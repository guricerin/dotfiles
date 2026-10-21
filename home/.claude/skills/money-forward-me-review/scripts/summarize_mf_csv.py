#!/usr/bin/env python3
"""マネーフォワード ME の入出金 CSV を集計し、家計分析の材料を Markdown で出力する。

使い方:
    python3 summarize_mf_csv.py <CSV> [<CSV> ...] [--top N]

- 月ごとにダウンロードした複数の CSV をまとめて渡せる（ID 列があれば重複を除く）
- 文字コードは UTF-8 / Shift_JIS(cp932) を自動判定する
- 収支の集計対象は「計算対象 = 1 かつ 振替 = 0」の行。振替は別枠で集計する
"""

import argparse
import csv
import io
import re
import sys
from collections import defaultdict

COLUMN_ALIASES = {
    "target": ["計算対象"],
    "date": ["日付"],
    "content": ["内容"],
    "amount": ["金額（円）", "金額(円)", "金額"],
    "institution": ["保有金融機関"],
    "major": ["大項目"],
    "minor": ["中項目"],
    "memo": ["メモ"],
    "transfer": ["振替"],
    "id": ["ID"],
}


def read_text(path):
    raw = open(path, "rb").read()
    for enc in ("utf-8-sig", "cp932"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    sys.exit(f"文字コードを判定できませんでした: {path}")


def resolve_columns(header):
    cols = {}
    for key, names in COLUMN_ALIASES.items():
        for name in names:
            if name in header:
                cols[key] = header.index(name)
                break
    missing = [k for k in ("date", "content", "amount") if k not in cols]
    if missing:
        sys.exit(f"必須列が見つかりません: {missing} / ヘッダー: {header}")
    return cols


def parse_amount(s):
    s = s.replace(",", "").replace("円", "").strip()
    return int(float(s)) if s else 0


def load_rows(paths):
    rows, seen = [], set()
    for path in paths:
        reader = csv.reader(io.StringIO(read_text(path)))
        header = [h.strip() for h in next(reader)]
        cols = resolve_columns(header)
        get = lambda r, k, d="": r[cols[k]].strip() if k in cols and cols[k] < len(r) else d
        for r in reader:
            if not any(c.strip() for c in r):
                continue
            rid = get(r, "id")
            if rid:
                if rid in seen:
                    continue
                seen.add(rid)
            date = get(r, "date").replace("-", "/")
            rows.append({
                "date": date,
                "month": date[:7],
                "content": get(r, "content"),
                "amount": parse_amount(get(r, "amount", "0")),
                "institution": get(r, "institution"),
                "major": get(r, "major") or "未分類",
                "minor": get(r, "minor") or "未分類",
                "target": get(r, "target", "1") != "0",
                "transfer": get(r, "transfer", "0") == "1",
            })
    return rows


def yen(n):
    return f"{n:,}円"


def table(headers, body):
    lines = ["| " + " | ".join(headers) + " |", "|" + "---|" * len(headers)]
    lines += ["| " + " | ".join(str(c) for c in row) + " |" for row in body]
    return "\n".join(lines)


def normalize_content(s):
    # 明細の日付や連番を除いて、同じ支払先をまとめやすくする
    return re.sub(r"[\d０-９/／\-\s]+", "", s)[:30] or s


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv", nargs="+")
    ap.add_argument("--top", type=int, default=10)
    args = ap.parse_args()

    rows = load_rows(args.csv)
    if not rows:
        sys.exit("明細が 0 件でした")

    flows = [r for r in rows if r["target"] and not r["transfer"]]
    transfers = [r for r in rows if r["transfer"]]
    excluded = [r for r in rows if not r["target"] and not r["transfer"]]
    months = sorted({r["month"] for r in rows})
    n_months = len(months)

    out = []
    out.append("# 入出金 CSV 集計結果\n")
    out.append(f"- 対象ファイル: {', '.join(args.csv)}")
    out.append(f"- 期間: {min(r['date'] for r in rows)} 〜 {max(r['date'] for r in rows)}（{n_months}か月分: {', '.join(months)}）")
    out.append(f"- 明細件数: 全 {len(rows)} 件 / 収支集計対象 {len(flows)} 件 / 振替 {len(transfers)} 件 / 計算対象外 {len(excluded)} 件")
    out.append("")

    # 月次収支
    out.append("## 月次収支（振替・計算対象外を除く）\n")
    body, tot_in, tot_out = [], 0, 0
    for m in months:
        inc = sum(r["amount"] for r in flows if r["month"] == m and r["amount"] > 0)
        exp = -sum(r["amount"] for r in flows if r["month"] == m and r["amount"] < 0)
        tot_in, tot_out = tot_in + inc, tot_out + exp
        rate = f"{(inc - exp) / inc * 100:.1f}%" if inc else "-"
        body.append([m, yen(inc), yen(exp), yen(inc - exp), rate])
    rate = f"{(tot_in - tot_out) / tot_in * 100:.1f}%" if tot_in else "-"
    body.append(["**合計**", yen(tot_in), yen(tot_out), yen(tot_in - tot_out), rate])
    body.append(["**月平均**", yen(tot_in // n_months), yen(tot_out // n_months), yen((tot_in - tot_out) // n_months), ""])
    out.append(table(["月", "収入", "支出", "収支", "貯蓄率"], body))
    out.append("")

    # 大項目別
    out.append("## 大項目別（収支集計対象のみ）\n")
    by_major = defaultdict(int)
    for r in flows:
        by_major[r["major"]] += r["amount"]
    body = []
    for major, amt in sorted(by_major.items(), key=lambda x: x[1]):
        share = f"{-amt / tot_out * 100:.1f}%" if amt < 0 and tot_out else "-"
        body.append([major, yen(amt), yen(amt // n_months), share])
    out.append(table(["大項目", "合計", "月平均", "支出に占める割合"], body))
    out.append("")

    # 中項目別（支出上位）
    out.append(f"## 中項目別 支出上位 {args.top}\n")
    by_minor = defaultdict(int)
    for r in flows:
        if r["amount"] < 0:
            by_minor[(r["major"], r["minor"])] += -r["amount"]
    body = [[ma, mi, yen(a), yen(a // n_months)] for (ma, mi), a in sorted(by_minor.items(), key=lambda x: -x[1])[: args.top]]
    out.append(table(["大項目", "中項目", "合計", "月平均"], body))
    out.append("")

    # 定期的な支出の候補（サブスク・固定費）
    out.append("## 毎月発生している支出（固定費・サブスクの候補）\n")
    groups = defaultdict(lambda: defaultdict(int))
    for r in flows:
        if r["amount"] < 0:
            groups[(normalize_content(r["content"]), r["major"])][r["month"]] += -r["amount"]
    min_months = max(2, n_months - 1) if n_months >= 2 else 99
    body = []
    for (content, major), per_month in groups.items():
        if len(per_month) >= min_months:
            total = sum(per_month.values())
            body.append([content, major, f"{len(per_month)}/{n_months}か月", yen(total // len(per_month))])
    body.sort(key=lambda x: -int(x[3].replace(",", "").replace("円", "")))
    out.append(table(["内容", "大項目", "発生月数", "発生月の平均額"], body) if body else "（2か月以上の CSV がないため判定できません）")
    out.append("")

    # 高額な支出
    out.append(f"## 高額な支出 上位 {args.top}\n")
    big = sorted((r for r in flows if r["amount"] < 0), key=lambda r: r["amount"])[: args.top]
    out.append(table(["日付", "内容", "大項目/中項目", "金額"], [[r["date"], r["content"], f"{r['major']}/{r['minor']}", yen(r["amount"])] for r in big]))
    out.append("")

    # 未分類
    uncategorized = [r for r in flows if r["major"] == "未分類"]
    if uncategorized:
        out.append("## 未分類\n")
        out.append(f"- {len(uncategorized)} 件 / 合計 {yen(sum(r['amount'] for r in uncategorized))}")
        out.append("")

    # 振替
    out.append("## 振替（収支には含めていない資金移動）\n")
    if transfers:
        by_t = defaultdict(lambda: [0, 0])
        for r in transfers:
            key = (normalize_content(r["content"]), r["institution"])
            by_t[key][0] += r["amount"]
            by_t[key][1] += 1
        body = [[c, inst or "-", n, yen(a)] for (c, inst), (a, n) in sorted(by_t.items(), key=lambda x: x[1][0])]
        out.append(table(["内容", "保有金融機関", "件数", "合計"], body))
    else:
        out.append("（振替はありません）")
    out.append("")

    # 計算対象外
    if excluded:
        out.append("## 計算対象外の明細\n")
        out.append(f"- {len(excluded)} 件 / 合計 {yen(sum(r['amount'] for r in excluded))}（ユーザーが集計から外した明細）")
        out.append("")

    print("\n".join(out))


if __name__ == "__main__":
    main()
