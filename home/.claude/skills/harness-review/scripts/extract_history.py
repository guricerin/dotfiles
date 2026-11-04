#!/usr/bin/env python3
"""Claude Code の会話履歴（~/.claude/projects/*/*.jsonl）から、ハーネスの改善を考える材料を抜き出し、JSON で標準出力に出す。

使い方:
    python3 extract_history.py [--since 2026-10-28T09:00] [--days 7]
    python3 extract_history.py --mark-done 2026-11-04T15:00:00+09:00

- 期間の始まり（since）は、--since 指定 > 前回の実行時刻（STATE_FILE）> 現在から --days 日前、の順で決める
- 全プロジェクトの、メインの会話だけを見る（サブエージェントの会話は除く。本人とのやりとりが入っていないため）
- 抜き出すのは、本人の発言・拒否されたツール呼び出し・エラーになったツール呼び出し・中断・呼ばれたスキル
- --mark-done は、改善案を本人に返し終えたあとに、抽出時の until を前回の実行時刻として保存する
- 外部ライブラリは使わない（標準ライブラリだけ）
"""

import argparse
import glob
import json
import os
import re
import sys
from datetime import datetime, timedelta, timezone

PROJECTS_DIR = os.path.expanduser("~/.claude/projects")
STATE_FILE = os.path.expanduser("~/.claude/state/harness-review/last-run.json")
TEXT_LIMIT = 400
ERROR_LIMIT = 200
# 履歴に残るが本人の発言ではないもの
NOISE_RE = re.compile(r"^<(local-command-caveat|local-command-stdout|system-reminder|task-notification)>")
COMMAND_RE = re.compile(r"<command-name>(/[^<]+)</command-name>(?:.*?<command-args>(.*?)</command-args>)?", re.S)


def parse_time(s):
    t = datetime.fromisoformat(s.replace("Z", "+00:00"))
    return t if t.tzinfo else t.astimezone()


def clip(s, n):
    s = s.strip()
    return s if len(s) <= n else s[:n] + "…"


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text")
    return ""


def resolve_since(args, now):
    if args.since:
        return parse_time(args.since), "--since"
    if os.path.isfile(STATE_FILE):
        with open(STATE_FILE, encoding="utf-8") as f:
            return parse_time(json.load(f)["last_run"]), "前回の実行"
    return now - timedelta(days=args.days), f"前回の実行なし（直近 {args.days} 日）"


def summarize_input(tool_input):
    for key in ("command", "file_path", "skill", "url", "pattern", "prompt"):
        if key in tool_input:
            return clip(str(tool_input[key]), TEXT_LIMIT)
    return clip(json.dumps(tool_input, ensure_ascii=False), TEXT_LIMIT)


def read_session(path, since, until):
    session = {"file": path, "cwd": None, "first": None, "last": None, "prompts": [], "commands": [],
               "rejected": [], "errors": [], "interrupts": 0, "skills": []}
    tool_uses = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue
            if d.get("type") not in ("user", "assistant") or d.get("isSidechain"):
                continue
            ts = d.get("timestamp")
            if not ts:
                continue
            t = parse_time(ts)
            if not (since <= t <= until):
                continue
            session["cwd"] = session["cwd"] or d.get("cwd")
            session["first"] = session["first"] or ts
            session["last"] = ts
            content = d.get("message", {}).get("content")

            if d["type"] == "assistant":
                for b in content or []:
                    if b.get("type") == "tool_use":
                        tool_uses[b["id"]] = b
                        if b["name"] == "Skill":
                            session["skills"].append(b["input"].get("skill", ""))
                continue

            for b in content if isinstance(content, list) else []:
                if b.get("type") != "tool_result" or not b.get("is_error"):
                    continue
                use = tool_uses.get(b.get("tool_use_id"), {})
                entry = {"time": ts, "tool": use.get("name"), "input": summarize_input(use.get("input", {}))}
                result = text_of(b.get("content"))
                if "doesn't want to proceed" in result:
                    # 拒否の理由を本人が書いていれば、結果の後ろに付いてくる
                    m = re.search(r"the user said:\s*(.*)", result, re.S)
                    entry["reason"] = clip(m.group(1), TEXT_LIMIT) if m else None
                    session["rejected"].append(entry)
                else:
                    entry["error"] = clip(result, ERROR_LIMIT)
                    session["errors"].append(entry)

            if d.get("isMeta"):
                continue
            text = text_of(content).strip()
            if not text or NOISE_RE.match(text):
                continue
            if text.startswith("[Request interrupted"):
                session["interrupts"] += 1
                continue
            m = COMMAND_RE.search(text)
            if m:
                session["commands"].append(clip(f"{m.group(1)} {m.group(2) or ''}", TEXT_LIMIT))
                continue
            session["prompts"].append({"time": ts, "text": clip(text, TEXT_LIMIT)})
    return session


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--since", help="期間の始まり（ISO 8601。タイムゾーンなしはローカル時刻）")
    p.add_argument("--days", type=int, default=7, help="前回の実行がないときに遡る日数")
    p.add_argument("--mark-done", metavar="UNTIL", help="抽出時の until を前回の実行時刻として保存する")
    args = p.parse_args()

    if args.mark_done:
        os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
        with open(STATE_FILE, "w", encoding="utf-8") as f:
            json.dump({"last_run": parse_time(args.mark_done).isoformat()}, f)
        print(json.dumps({"saved": STATE_FILE, "last_run": args.mark_done}, ensure_ascii=False))
        return

    now = datetime.now().astimezone()
    since, since_source = resolve_since(args, now)
    warnings = []
    if since > now:
        warnings.append("期間の始まりが現在時刻より未来")

    sessions = []
    for path in glob.glob(os.path.join(PROJECTS_DIR, "*", "*.jsonl")):
        # 更新が期間より前のファイルは中身を読まない（履歴が多いと遅いため）
        if datetime.fromtimestamp(os.path.getmtime(path)).astimezone() < since:
            continue
        s = read_session(path, since, now)
        if s["first"]:
            sessions.append(s)
    sessions.sort(key=lambda s: s["first"])

    skills = {}
    for s in sessions:
        for name in s["skills"]:
            skills[name] = skills.get(name, 0) + 1
    print(json.dumps({
        "since": since.isoformat(),
        "since_source": since_source,
        "until": now.isoformat(),
        "warnings": warnings,
        "totals": {
            "sessions": len(sessions),
            "prompts": sum(len(s["prompts"]) for s in sessions),
            "rejected": sum(len(s["rejected"]) for s in sessions),
            "errors": sum(len(s["errors"]) for s in sessions),
            "interrupts": sum(s["interrupts"] for s in sessions),
            "skills": skills,
        },
        "projects": sorted({s["cwd"] for s in sessions if s["cwd"]}),
        "sessions": sessions,
    }, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    sys.exit(main())
