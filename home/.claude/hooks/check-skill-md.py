#!/usr/bin/env python3
"""Claude Code の PostToolUse(Write|Edit) フック

SKILL.md が書き込まれたら、雛形の未記入（{{必須: ...}}）や中身が空の見出しが残っていないかを検査する。
残っていれば終了コード 2 で理由を返し、Claude に埋め直させる。
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

if problems:
    print(
        f"{path} に未記入の項目があります。推測で埋めず、情報が足りなければ止まってユーザーに聞いてください。"
        "該当するものがない項目は「該当なし（理由: …）」と書いてください。\n" + "\n".join(problems),
        file=sys.stderr,
    )
    sys.exit(2)
