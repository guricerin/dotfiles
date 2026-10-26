#!/usr/bin/env python3
"""Auth0・セキュリティ関連・ソフトウェアの更新・札幌の生活関連のフィードを取得し、期間内の記事を JSON で標準出力に出す。

使い方:
    python3 fetch_news.py --output-dir <出力先フォルダ> [--since 2026-10-14T09:00] [--days 7] [--groups sapporo]

- 期間の始まり（since）は、--since 指定 > 出力先にある最新の YYYY-MM-DD-HH-MM.md の時刻 > 現在から --days 日前、の順で決める
- --groups を付けると、そのグループのソースだけを取得する。出力ファイル名は YYYY-MM-DD-HH-MM-<グループ>.md になり、
  全部を取得する実行の「前回」としては数えない（一部だけのまとめを起点にすると、他のグループの記事が抜けるため）
- 取得に失敗したソースがあっても止まらず、sources[].error に理由を入れて残りを続ける
- 外部ライブラリは使わない（標準ライブラリと gh コマンドだけ）
"""

import argparse
import html
import json
import os
import re
import subprocess
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime

# 一部のサイトはブラウザ風の User-Agent を弾き、Azure は逆にそれで 403 を返すので、curl 風にする
USER_AGENT = "curl/8.7.1"
TIMEOUT = 30
SUMMARY_LIMIT = 600
FILENAME_RE = re.compile(r"^(\d{4})-(\d{2})-(\d{2})-(\d{2})-(\d{2})(?:-([a-z0-9_-]+))?\.md$")
GROUPS = ["auth0", "security-ja", "security-en", "infra", "software", "ai", "advisory", "sapporo"]

# Azure の更新情報は量が多いので、本人の業務（AKS・MySQL Flexible Server・Functions・Entra ID など）に関係しそうなものだけ残す
AZURE_KEYWORDS = [
    "Kubernetes", "AKS", "MySQL", "Functions", "Entra", "Key Vault", "Container Registry",
    "Security", "Retirement", "Retire", "Monitor", "Grafana", "Prometheus",
]

FEEDS = [
    {"name": "Auth0 Changelog", "group": "auth0", "url": "https://auth0.com/changelog/rss.xml"},
    {"name": "JPCERT/CC", "group": "security-ja", "url": "https://www.jpcert.or.jp/rss/jpcert.rdf"},
    {"name": "IPA 重要なセキュリティ情報", "group": "security-ja", "url": "https://www.ipa.go.jp/security/rss/alert.rdf"},
    {"name": "The Hacker News", "group": "security-en", "url": "https://feeds.feedburner.com/TheHackersNews"},
    {"name": "BleepingComputer", "group": "security-en", "url": "https://www.bleepingcomputer.com/feed/"},
    {"name": "Kubernetes CVE", "group": "infra", "url": "https://kubernetes.io/docs/reference/issues-security/official-cve-feed/index.json"},
    {"name": "Azure Updates", "group": "infra", "url": "https://www.microsoft.com/releasecommunications/api/v2/azure/rss", "keywords": AZURE_KEYWORDS},
    # 窓の杜はセールや書籍の紹介も多いので、その連載の記事は題名で除く
    {
        "name": "窓の杜", "group": "software", "url": "https://forest.watch.impress.co.jp/data/rss/1.0/wf/feed.rdf",
        "exclude_titles": ["【本日みつけたお買い得情報】", "【Book Watch/セール情報】", "【読み放題！TechLib新着情報】"],
    },
    # 以下は本人が住む札幌の生活に関係するもの
    {"name": "ITmedia AI+", "group": "ai", "url": "https://rss.itmedia.co.jp/rss/2.0/aiplus.xml"},
    {"name": "Claude Code Releases", "group": "ai", "url": "https://github.com/anthropics/claude-code/releases.atom"},
    {"name": "OpenAI News", "group": "ai", "url": "https://openai.com/news/rss.xml"},
    {"name": "Simon Willison's Weblog", "group": "ai", "url": "https://simonwillison.net/atom/everything/"},
    {"name": "札幌市 新着情報", "group": "sapporo", "url": "https://www.city.sapporo.jp/new/shinchaku.xml"},
    {"name": "札幌市 報道発表", "group": "sapporo", "url": "https://www.city.sapporo.jp/somu/koho/hodo/houdou.xml"},
    {"name": "北海道新聞", "group": "sapporo", "url": "https://www.hokkaido-np.co.jp/output/7/free/index.ad.xml", "keywords": ["札幌"], "match_summary": True},
    {"name": "札幌経済新聞", "group": "sapporo", "url": "https://sapporo.keizai.biz/rss.xml"},
    # 気象庁の防災情報 XML。同じ内容が電文の形式違いで重複して届くので、形式違いの題名を除く
    {
        "name": "気象庁 警報・注意報", "group": "sapporo", "url": "https://www.data.jma.go.jp/developer/xml/feed/extra_l.xml",
        "keywords": ["石狩", "札幌"], "match_summary": True, "exclude_titles": ["（Ｈ２７）", "（Ｒ０６）", "（目撃情報付き）"],
    },
    {"name": "気象庁 地震・火山", "group": "sapporo", "url": "https://www.data.jma.go.jp/developer/xml/feed/eqvol_l.xml", "keywords": ["石狩", "札幌"], "match_summary": True},
    # 動物の出没・交通やライフライン・注意喚起の事件は、まとまったフィードがないので Google ニュースの検索で拾う
    {"name": "Google ニュース（クマ・シカ）", "group": "sapporo", "url": "https://news.google.com/rss/search?q=" + urllib.parse.quote("札幌 (クマ OR ヒグマ OR シカ) 出没") + "&hl=ja&gl=JP&ceid=JP:ja"},
    {"name": "Google ニュース（交通・ライフライン）", "group": "sapporo", "url": "https://news.google.com/rss/search?q=" + urllib.parse.quote("札幌 (運休 OR 運転見合わせ OR 通行止め OR 除雪 OR 停電 OR 断水)") + "&hl=ja&gl=JP&ceid=JP:ja"},
    {"name": "Google ニュース（注意喚起）", "group": "sapporo", "url": "https://news.google.com/rss/search?q=" + urllib.parse.quote("札幌 (逃走 OR 不審者 OR 発砲 OR 刃物 OR 注意喚起)") + "&hl=ja&gl=JP&ceid=JP:ja"},
]

# GitHub Advisory は本人が使う言語のエコシステムに絞り、件数が多いので high 以上だけにする
ADVISORY_ECOSYSTEMS = ["npm", "composer", "go", "rust"]
ADVISORY_SEVERITIES = ["critical", "high"]

NS = {
    "rss1": "http://purl.org/rss/1.0/",
    "dc": "http://purl.org/dc/elements/1.1/",
    "atom": "http://www.w3.org/2005/Atom",
}


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as res:
        return res.read()


def parse_date(text):
    if not text:
        return None
    text = text.strip()
    try:
        dt = parsedate_to_datetime(text)
    except (TypeError, ValueError):
        try:
            dt = datetime.fromisoformat(text.replace("Z", "+00:00"))
        except ValueError:
            return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def clean(text):
    """HTML タグと余分な空白を除き、長すぎる本文を切り詰める"""
    text = html.unescape(re.sub(r"<[^>]+>", " ", text or ""))
    text = re.sub(r"\s+", " ", text).strip()
    return text[:SUMMARY_LIMIT] + ("…" if len(text) > SUMMARY_LIMIT else "")


def parse_xml_feed(data):
    root = ET.fromstring(data)
    items = []
    # RSS 2.0
    for it in root.iter("item"):
        items.append({
            "title": it.findtext("title"),
            # Auth0 Changelog は <link> がなく <guid> だけを持つ
            "link": it.findtext("link") or it.findtext("guid"),
            "published": parse_date(it.findtext("pubDate") or it.findtext("dc:date", namespaces=NS)),
            "summary": it.findtext("description"),
            "categories": [c.text for c in it.findall("category") if c.text],
        })
    # RSS 1.0（RDF）。JPCERT/CC と IPA
    for it in root.iter(f"{{{NS['rss1']}}}item"):
        items.append({
            "title": it.findtext("rss1:title", namespaces=NS),
            "link": it.findtext("rss1:link", namespaces=NS),
            "published": parse_date(it.findtext("dc:date", namespaces=NS)),
            "summary": it.findtext("rss1:description", namespaces=NS),
            "categories": [],
        })
    # Atom
    for it in root.iter(f"{{{NS['atom']}}}entry"):
        link = it.find("atom:link", NS)
        items.append({
            "title": it.findtext("atom:title", namespaces=NS),
            "link": link.get("href") if link is not None else None,
            "published": parse_date(it.findtext("atom:published", namespaces=NS) or it.findtext("atom:updated", namespaces=NS)),
            "summary": it.findtext("atom:summary", namespaces=NS) or it.findtext("atom:content", namespaces=NS),
            "categories": [],
        })
    return items


def parse_json_feed(data):
    """JSON Feed 形式。Kubernetes の公式 CVE フィード"""
    items = []
    for it in json.loads(data).get("items", []):
        items.append({
            "title": it.get("title"),
            "link": it.get("url") or it.get("external_url"),
            "published": parse_date(it.get("date_published")),
            "summary": it.get("summary") or it.get("content_text"),
            "categories": [],
        })
    return items


def fetch_advisories(since):
    items = []
    for eco in ADVISORY_ECOSYSTEMS:
        for sev in ADVISORY_SEVERITIES:
            path = f"/advisories?ecosystem={eco}&severity={sev}&published=>={since.date().isoformat()}&per_page=100"
            out = subprocess.run(["gh", "api", path], capture_output=True, text=True, timeout=TIMEOUT)
            if out.returncode != 0:
                raise RuntimeError(out.stderr.strip() or f"gh api が終了コード {out.returncode} で失敗")
            for adv in json.loads(out.stdout):
                packages = sorted({v["package"]["name"] for v in adv.get("vulnerabilities") or [] if v.get("package")})
                items.append({
                    "title": f"[{sev}] {adv.get('summary')}",
                    "link": adv.get("html_url"),
                    "published": parse_date(adv.get("published_at")),
                    "summary": adv.get("description"),
                    "categories": [eco] + packages,
                    "cve": adv.get("cve_id"),
                })
    return items


def find_previous(output_dir, suffix):
    """出力先にある最新のまとめを探す。全部のまとめ（接尾辞なし）と、同じ接尾辞のまとめだけを数える。
    ファイル名の時刻はローカル時刻として読む"""
    if not os.path.isdir(output_dir):
        return None, None
    latest, latest_time = None, None
    for name in os.listdir(output_dir):
        m = FILENAME_RE.match(name)
        if not m or m.group(6) not in (None, suffix):
            continue
        t = datetime(*map(int, m.groups()[:5])).astimezone()
        if latest_time is None or t > latest_time:
            latest, latest_time = name, t
    return latest, latest_time


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output-dir", required=True)
    ap.add_argument("--since", help="ISO 8601。タイムゾーンなしはローカル時刻")
    ap.add_argument("--days", type=int, default=7, help="前回の出力がないときに遡る日数")
    ap.add_argument("--groups", help=f"取得するグループをカンマ区切りで指定する（{', '.join(GROUPS)}）。省略時は全部")
    args = ap.parse_args()
    groups = sorted(set(args.groups.split(","))) if args.groups else None
    if groups and set(groups) - set(GROUPS):
        ap.error(f"不明なグループ: {', '.join(sorted(set(groups) - set(GROUPS)))}")
    suffix = "_".join(groups) if groups else None

    now = datetime.now().astimezone()
    warnings = []
    previous_file, previous_time = find_previous(args.output_dir, suffix)
    if args.since:
        since = datetime.fromisoformat(args.since)
        since = since.astimezone() if since.tzinfo is None else since
        since_source = "arg"
    elif previous_time:
        since, since_source = previous_time, "previous_file"
    else:
        since, since_source = now - timedelta(days=args.days), f"default_{args.days}d"
    if since > now:
        warnings.append(f"期間の始まり {since.isoformat()} が現在時刻より未来です")

    sources, items = [], []
    for feed in FEEDS:
        if groups and feed["group"] not in groups:
            continue
        entry = {"name": feed["name"], "group": feed["group"], "url": feed["url"], "error": None, "count": 0}
        try:
            data = fetch(feed["url"])
            parsed = parse_json_feed(data) if feed["url"].endswith(".json") else parse_xml_feed(data)
        except Exception as e:  # ソース単位で失敗を記録し、残りのソースは続ける
            entry["error"] = f"{type(e).__name__}: {e}"
            sources.append(entry)
            continue
        # フィードは新しい順に一定件数しか載せないので、最古の記事が期間の始まりより新しければ取りこぼしている
        dates = [it["published"] for it in parsed if it["published"]]
        if dates and min(dates) > since:
            warnings.append(
                f"{feed['name']} の最古の記事が {min(dates).astimezone().isoformat(timespec='minutes')} で、"
                "期間の始まりより新しい。それより前の記事は取得できていない"
            )
        for it in parsed:
            if not it["published"] or it["published"] < since:
                continue
            if any(x in (it["title"] or "") for x in feed.get("exclude_titles", [])):
                continue
            keywords = feed.get("keywords")
            if keywords:
                haystack = " ".join([it["title"] or ""] + it["categories"] + ([it["summary"] or ""] if feed.get("match_summary") else []))
                if not any(k.lower() in haystack.lower() for k in keywords):
                    continue
            items.append({"source": feed["name"], "group": feed["group"], **it})
            entry["count"] += 1
        sources.append(entry)

    if not groups or "advisory" in groups:
        entry = {"name": "GitHub Advisory", "group": "advisory", "url": "gh api /advisories", "error": None, "count": 0}
        try:
            for it in fetch_advisories(since):
                if it["published"] and it["published"] >= since:
                    items.append({"source": "GitHub Advisory", "group": "advisory", **it})
                    entry["count"] += 1
        except Exception as e:
            entry["error"] = f"{type(e).__name__}: {e}"
        sources.append(entry)

    # 同じ URL が複数のフィードに出ることがあるので除く
    seen, unique = set(), []
    for it in sorted(items, key=lambda x: x["published"], reverse=True):
        key = it["link"] or (it["source"], it["title"])
        if key in seen:
            continue
        seen.add(key)
        it["published"] = it["published"].astimezone().isoformat(timespec="minutes")
        it["summary"] = clean(it["summary"])
        unique.append(it)

    json.dump({
        "since": since.isoformat(timespec="minutes"),
        "until": now.isoformat(timespec="minutes"),
        "since_source": since_source,
        "previous_file": previous_file,
        "groups": groups,
        "suggested_filename": now.strftime("%Y-%m-%d-%H-%M") + (f"-{suffix}" if suffix else "") + ".md",
        "warnings": warnings,
        "sources": sources,
        "items": unique,
    }, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
