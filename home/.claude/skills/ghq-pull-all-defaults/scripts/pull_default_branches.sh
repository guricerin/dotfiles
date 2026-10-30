#!/usr/bin/env bash

# ghq root 配下の全リポジトリで、デフォルトブランチを origin に合わせて fast-forward する
#
# 使い方:
#   pull_default_branches.sh [--dry-run] [--jobs 8]
#
# 出力（1リポジトリ1行、タブ区切り）:
#   <状態>  <リポジトリ（ghq root からの相対パス）>  <今のブランチ>  <詳細>
#   状態: updated / up-to-date / fetched / skipped / failed / dry-run
#
# 作業中のブランチと未コミットの修正には触れない。コミット・stash・switch はしない。

set -u

JOBS=8
DRY_RUN=0
# 1リポジトリの fetch にかける時間の上限（秒）。応答のないリモートで全体が止まらないようにする
FETCH_TIMEOUT=60

# 認証の入力待ちで止まらないようにする
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=15}"

timeout_cmd() {
  if command -v timeout >/dev/null; then
    timeout "$FETCH_TIMEOUT" "$@"
  elif command -v gtimeout >/dev/null; then
    gtimeout "$FETCH_TIMEOUT" "$@"
  else
    "$@"
  fi
}

# 1行で出す。並列に書き込んでも行が混ざらないよう、printf 1回で書く
report() {
  local status=$1 repo=$2 branch=$3 detail=$4
  printf '%s\t%s\t%s\t%s\n' "$status" "$repo" "$branch" "$detail"
}

# エラーメッセージを1行に縮める
one_line() {
  tr '\n' ' ' | sed -e 's/  */ /g' -e 's/ *$//' | cut -c1-200
}

process_repo() {
  local path=$1
  local repo=${path#"$GHQ_ROOT"/}
  local git="git -C $path"

  if ! $git remote get-url origin >/dev/null 2>&1; then
    report skipped "$repo" "-" "origin のリモートがない"
    return
  fi

  local current
  current=$($git branch --show-current)
  [ -z "$current" ] && current="(detached)"

  # デフォルトブランチは origin/HEAD から取る。なければリモートに問い合わせる（設定は書き換えない）
  local default
  default=$($git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  default=${default#origin/}
  if [ -z "$default" ]; then
    default=$(timeout_cmd $git ls-remote --symref origin HEAD 2>/dev/null | awk '/^ref:/ {sub("refs/heads/", "", $2); print $2; exit}')
  fi
  if [ -z "$default" ]; then
    report failed "$repo" "$current" "デフォルトブランチを特定できない"
    return
  fi

  # 未追跡のファイル（.env など）は数えない。fast-forward で上書きされる場合は git 自身が止める
  local dirty=0
  [ -n "$($git status --porcelain --untracked-files=no)" ] && dirty=1

  local has_local=0
  $git show-ref --verify --quiet "refs/heads/$default" && has_local=1

  if [ "$current" = "$default" ]; then
    if [ $dirty -eq 1 ]; then
      report skipped "$repo" "$current" "デフォルトブランチに未コミットの修正がある"
      return
    fi
    if [ $DRY_RUN -eq 1 ]; then
      report dry-run "$repo" "$current" "fetch して $default を fast-forward する予定"
      return
    fi
    local before err
    before=$($git rev-parse --short HEAD)
    if ! err=$(timeout_cmd $git fetch --quiet origin 2>&1); then
      report failed "$repo" "$current" "fetch に失敗: $(echo "$err" | one_line)"
      return
    fi
    if ! err=$($git merge --ff-only --quiet "origin/$default" 2>&1); then
      report failed "$repo" "$current" "fast-forward できない: $(echo "$err" | one_line)"
      return
    fi
    local after
    after=$($git rev-parse --short HEAD)
    if [ "$before" = "$after" ]; then
      report up-to-date "$repo" "$current" "$default は最新"
    else
      report updated "$repo" "$current" "$default を更新 ($before → $after)"
    fi
    return
  fi

  # 今のブランチがデフォルトブランチでない: 移動せずにデフォルトブランチだけを進める
  local note=""
  [ $dirty -eq 1 ] && note="（今のブランチの未コミットの修正はそのまま）"

  if [ $has_local -eq 0 ]; then
    if [ $DRY_RUN -eq 1 ]; then
      report dry-run "$repo" "$current" "ローカルに $default がないので fetch だけする予定$note"
      return
    fi
    local err
    if ! err=$(timeout_cmd $git fetch --quiet origin 2>&1); then
      report failed "$repo" "$current" "fetch に失敗: $(echo "$err" | one_line)"
      return
    fi
    report fetched "$repo" "$current" "ローカルに $default がないので fetch だけした$note"
    return
  fi

  if [ $DRY_RUN -eq 1 ]; then
    report dry-run "$repo" "$current" "fetch で $default を fast-forward する予定$note"
    return
  fi

  local before after err
  before=$($git rev-parse --short "refs/heads/$default")
  # <src>:<dst> の形は fast-forward できるときだけローカルのブランチを更新する（先頭に + を付けない）
  if ! err=$(timeout_cmd $git fetch --quiet origin "refs/heads/$default:refs/heads/$default" 2>&1); then
    report failed "$repo" "$current" "$default を更新できない: $(echo "$err" | one_line)"
    return
  fi
  # origin/<default> などの追跡ブランチもまとめて最新にする
  timeout_cmd $git fetch --quiet origin >/dev/null 2>&1
  after=$($git rev-parse --short "refs/heads/$default")
  if [ "$before" = "$after" ]; then
    report up-to-date "$repo" "$current" "$default は最新$note"
  else
    report updated "$repo" "$current" "$default を更新 ($before → $after)$note"
  fi
}

# xargs から1リポジトリずつ呼ばれるときの入口
if [ "${1:-}" = "--one" ]; then
  GHQ_ROOT=$2
  DRY_RUN=$3
  process_repo "$4"
  exit 0
fi

while [ $# -gt 0 ]; do
  case $1 in
    --dry-run) DRY_RUN=1 ;;
    --jobs) JOBS=$2; shift ;;
    *) echo "不明な引数: $1" >&2; exit 2 ;;
  esac
  shift
done

if ! command -v ghq >/dev/null; then
  echo "ghq が見つからない" >&2
  exit 1
fi

GHQ_ROOT=$(ghq root)
ghq list --full-path | xargs -P "$JOBS" -I{} bash "$0" --one "$GHQ_ROOT" "$DRY_RUN" {} | sort
