#!/usr/bin/env bash

# 言語のランタイムなど、プロジェクトごとにバージョンを変えたいツールを mise で入れる
# 入れ分けの基準は README.md の「ツールの入れ分け」を参照

set -eu

# ~/.config/mise/config.toml に書き込み、どのディレクトリでも使えるようにする
# プロジェクトで別のバージョンが要るときは、そのリポジトリで `mise use <tool>@<version>` する
mise use --global \
  bun@latest \
  python@latest \
  go@latest \
  terraform@latest \
  kubectl@latest
