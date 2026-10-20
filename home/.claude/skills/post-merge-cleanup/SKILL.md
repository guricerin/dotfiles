---
name: post-merge-cleanup
description: PR をデフォルトブランチにマージした後の後片付けをする。デフォルトブランチに switch して git pull し、マージ済みの作業用ブランチをローカル・リモートの両方から削除する。「マージしたので片付けて」「マージ後の後始末」「main に戻って pull して」「作業ブランチ消して」「PR マージされた」など、PR のマージが済んで作業ブランチを畳みたい場面では、ブランチ名や手順を明示されていなくても必ずこのスキルを使う。
---

# Post-merge cleanup

PR がマージされた後の定型作業（デフォルトブランチへ戻る → 最新化 → 作業用ブランチ削除）を安全に行う。

ブランチ削除は取り消しにくい操作なので、「本当にマージ済みか」「まだ push していない作業が残っていないか」を確認してから消すのがこのスキルの肝。確認が取れないときは削除せずにユーザーへ状況を伝えて判断を仰ぐ。

## 手順

### 1. 対象を特定する

```bash
git branch --show-current
gh repo view --json defaultBranchRef -q .defaultBranchRef.name
```

- デフォルトブランチ名は `main` と決め打ちせず取得する（`master` や `develop` のリポジトリもある）。`gh` が使えなければ `git symbolic-ref --short refs/remotes/origin/HEAD` の結果から `origin/` を除いたものを使う。
- 現在のブランチが作業用ブランチ。ユーザーがブランチ名や PR 番号を指定していればそちらを優先する。
- すでにデフォルトブランチにいて対象が分からない場合は、会話の文脈から推測できなければユーザーに聞く。

### 2. PR がマージ済みか確認する

```bash
gh pr view <作業用ブランチ or PR番号> --json number,state,mergedAt,baseRefName,headRefName,headRefOid
```

- `state` が `MERGED` でなければここで止める。マージ前にブランチを消すと作業が失われうるため。
- PR が見つからない場合も止めて、ユーザーに確認する。

### 3. 作業ツリーがきれいか確認する

```bash
git status --porcelain
```

未コミットの変更があれば止めてユーザーに伝える。switch で変更が持ち越されたり、切り替えに失敗したりするため。勝手に stash や discard はしない。

### 4. デフォルトブランチに switch して pull

```bash
git switch <デフォルトブランチ>
git pull --ff-only
```

`--ff-only` にしているのは、ローカルのデフォルトブランチに意図しないマージコミットを作らないため。fast-forward できなければ止めて状況を報告する。

### 5. ローカルの作業用ブランチを削除

```bash
git branch -d <作業用ブランチ>
```

squash merge や rebase merge の場合、コミットハッシュが変わるため `-d` は「未マージ」と判断して失敗する。その場合は、ローカルブランチの先端が PR の最終コミット (`headRefOid`) と一致するか確認する:

```bash
git rev-parse <作業用ブランチ>
```

- 一致していれば、PR に含まれた内容しか持っていないので `git branch -D <作業用ブランチ>` で削除してよい。
- 一致しなければ、push していないコミットが残っている可能性がある。`git log --oneline <headRefOid>..<作業用ブランチ>` で差分を示し、削除せずユーザーに判断を委ねる。

ブランチが別の worktree でチェックアウトされていて削除できない場合も、その旨を伝えて止める。

### 6. リモートの作業用ブランチを削除

GitHub の「Automatically delete head branches」で既に消えていることも多いので、残っているときだけ削除する。

```bash
git ls-remote --exit-code --heads origin <作業用ブランチ>
# 終了コード 0（残っている）なら:
git push origin --delete <作業用ブランチ>
```

最後に追跡ブランチを掃除する:

```bash
git fetch --prune
```

### 7. 結果を報告する

何をしたかを短くまとめる。例:

```
- main に switch して pull（abc1234 → def5678）
- ローカルブランチ feat/foo を削除（squash merge のため -D、PR #12 の head と一致を確認済み）
- リモートブランチ origin/feat/foo を削除
```

途中で止めた場合は、どのステップで何が原因で止めたのか、ユーザーが次に取れる選択肢を添えて伝える。
