---
name: assign-pr-to-me
description: GitHub にプルリクエストを作成するときに、assignee に自分（gh で認証中のアカウント）を必ず追加する。`gh pr create` を実行する場面、「PR 作って」「プルリク出して」「コミットして PR」など PR を作成するあらゆる場面では、assignee について言及がなくても必ずこのスキルを使う。作成済みの PR に自分を assignee として追加したいときにも使う。
---

# Assign PR to me

GitHub に PR を作るときは、assignee に自分を入れる。PR 作成の手順そのもの（ブランチ・コミット・本文の書き方、draft にするかなど）は通常どおりで、このスキルは assignee の付与だけを担う。

## PR を作成するとき

`gh pr create` に `--assignee @me` を付ける。`@me` は gh で認証中のアカウントに解決されるので、ユーザー名を決め打ちしない。

```bash
gh pr create --assignee @me --title "..." --body "..."
```

他のフラグ（`--draft` や `--base` など）とはそのまま併用できる。

## 作成済みの PR に追加するとき

付け忘れた場合や、既存の PR が対象の場合は後から追加する。

```bash
gh pr edit <PR番号 or ブランチ> --add-assignee @me
```

## 確認

作成・追加の後、自分が assignee に入っていることを確認する。

```bash
gh pr view <PR番号 or ブランチ> --json assignees -q '.assignees[].login'
```

入っていなければ `gh pr edit --add-assignee @me` で追加し直す。追加に失敗した場合（リポジトリへの権限がないなど）は PR 自体はそのまま残し、assignee を付けられなかったことと原因をユーザーに伝える。
