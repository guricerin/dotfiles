#!/usr/bin/env python3
"""Claude Code の PostToolUse(Write|Edit) フック

SKILL.md が書き込まれたら、雛形の未記入（{{必須: ...}}）や中身が空の見出しが残っていないか、
frontmatter の name / description が文字数の上限を超えていないかを検査する。
問題があれば終了コード 2 で理由を返し、Claude に直させる。
"""

import json
import os
import re
import sys

payload = json.load(sys.stdin)
path = payload.get("tool_input", {}).get("file_path", "")

if os.path.basename(path) != "SKILL.md":
    sys.exit(0)
# 雛形そのものと、claude.ai から同期・プラグインで配布されるスキルは対象外
real = os.path.realpath(path)
if "/.claude/templates/" in real or "/skills/synced/" in real or "/.claude/plugins/" in real:
    sys.exit(0)
if not os.path.isfile(path):
    sys.exit(0)

lines = open(path, encoding="utf-8").read().splitlines()
problems = []

for i, line in enumerate(lines, 1):
    if "{{必須" in line:
        problems.append(f"{i} 行目: 未記入の項目があります: {line.strip()}")

# コードブロックの中の「#」は見出しではないので除いて、見出しの直後に本文があるかを見る
headings, in_fence = [], False
for i, line in enumerate(lines, 1):
    if line.lstrip().startswith("```"):
        if not in_fence:
            headings.append((i, None, line))  # コードブロックも見出しの本文として数える
        in_fence = not in_fence
        continue
    if in_fence:
        continue
    m = re.match(r"^(#{1,6})\s+\S", line)
    headings.append((i, len(m.group(1)) if m else None, line))

for idx, (i, level, line) in enumerate(headings):
    if level is None:
        continue
    has_body = False
    for _, next_level, next_line in headings[idx + 1:]:
        if next_level is not None:
            # より深い見出しが続くなら、その中身がこの見出しの本文になる
            has_body = next_level > level
            break
        if next_line.strip():
            has_body = True
            break
    if not has_body:
        problems.append(f"{i} 行目: 見出しの中身が空です: {line.strip()}")


def frontmatter_value(fm_lines, key):
    """frontmatter から key の値を取り出す。引用符つき・折り返し（> や |）・複数行の値に対応する"""
    for idx, line in enumerate(fm_lines):
        m = re.match(rf"^{re.escape(key)}:\s*(.*)$", line)
        if not m:
            continue
        first = m.group(1).strip()
        rest = []
        for next_line in fm_lines[idx + 1:]:
            # インデントされていない行（次のキー）で値が終わる
            if next_line and not next_line[0].isspace():
                break
            rest.append(next_line.strip())
        if first[:1] in (">", "|"):
            sep = "\n" if first[0] == "|" else " "
            return sep.join(l for l in rest if l)
        value = " ".join([first] + [l for l in rest if l])
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        return value
    return ""


# 上限: name 64 文字・description 1024 文字は Agent Skills の仕様（https://agentskills.io/specification）。
# description + when_to_use の 1536 文字は Claude Code のスキル一覧で切り詰められる長さ
if lines and lines[0].strip() == "---":
    end = next((i for i, l in enumerate(lines[1:], 1) if l.strip() == "---"), None)
    if end is not None:
        fm = lines[1:end]
        name = frontmatter_value(fm, "name")
        description = frontmatter_value(fm, "description")
        when_to_use = frontmatter_value(fm, "when_to_use")
        if len(name) > 64:
            problems.append(f"name が {len(name)} 文字です。上限は 64 文字です")
        if len(description) > 1024:
            problems.append(f"description が {len(description)} 文字です。上限は 1024 文字です")
        if len(description) + len(when_to_use) > 1536:
            problems.append(
                f"description と when_to_use の合計が {len(description) + len(when_to_use)} 文字です。"
                "1536 文字を超えた分は Claude Code のスキル一覧で切り詰められます"
            )

if problems:
    print(
        f"{path} に直すべき箇所があります。未記入の項目は推測で埋めず、情報が足りなければ止まってユーザーに聞いてください。"
        "該当するものがない項目は「該当なし（理由: …）」と書いてください。"
        "文字数の上限を超えているものは、要点を残して短くしてください。\n" + "\n".join(problems),
        file=sys.stderr,
    )
    sys.exit(2)
