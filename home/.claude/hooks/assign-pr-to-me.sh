#!/usr/bin/env bash

# Claude Code の PostToolUse(Bash) フック
# gh pr create で作成された PR の assignee に、gh で認証中のアカウントを追加する

set -u

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

if ! echo "$command" | grep -q 'gh pr create'; then
  exit 0
fi

# gh pr create は作成した PR の URL を出力するので、そこから対象を特定する
pr_url=$(echo "$input" | jq -r '.tool_response.stdout // ""' | grep -oE 'https://github\.com/[^/ ]+/[^/ ]+/pull/[0-9]+' | tail -n 1)
if [ -z "$pr_url" ]; then
  exit 0
fi

if ! gh pr edit "$pr_url" --add-assignee @me >/dev/null 2>&1; then
  echo "{\"systemMessage\": \"$pr_url の assignee への追加に失敗しました\"}"
fi
