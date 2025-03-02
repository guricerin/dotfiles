#!/usr/bin/env bash

# 未定義変数があれば表示する
set -u
# エラー発生時、処理を中断する
set -e

# https://patorjk.com/software/taag/#p=display&f=Efti%20Wall&t=homebound
readonly LOGO=$'
     ___       #   ___            ___          |"|          ( ( (      #   ___            o           _   _             ...
    .|||.      #  <_*_>          /_\ `*       _|_|_       \'. ___ .\'    #  <_*_>        ` /_\ \'       \'\\-//`       o,*,(o o)
    (o o)      #  (o o)         (o o)         (o o)      \'  (> <) \'    #  (o o)       - (o o) -       (o o)       8(o o)(_)Ooo
ooO--(_)--Ooo--8---(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo--8---(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO-(_)---Ooo----
'

readonly SCRIPT_ROOT=$(cd $(dirname $0); pwd)
readonly DOTFILES_HOME="$SCRIPT_ROOT/home"

build_symlinks() {
  # 意図しないファイルがリポジトリに含まれるのを防止したいので、ディレクトリのシムリンクは作成しない
  for src in $(find $DOTFILES_HOME -type f); do
    echo "---"
    local dst=${src/$DOTFILES_HOME/$(echo $HOME)} # e.g. /home/username/homebound/home/.zshrc => /home/username/.zshrc
    local parent=$(dirname $dst)
    if [ ! -d $parent ]; then
      mkdir -p $parent
    fi
    if [ -f $dst ]; then
      printf "\e[0;34m      backup $dst.bak\e[0m\n"
      cp $dst $dst.bak
    fi
    ln -snf $src $dst
    printf "\e[0;32m  [o] $dst -> $src\e[0m\n"
  done
}

print_expectation() {
  for src in $(find $DOTFILES_HOME -type f); do
    local dst=${src/$DOTFILES_HOME/$(echo $HOME)}
    printf "\e[0;34m  [?] $dst -> $src\e[0m\n"
  done
}

declare -g IS_APPLY_MODE=0

parse_args() {
  for arg in "$@"; do
    case $arg in
      -a|--apply)
        IS_APPLY_MODE=1
        ;;
      *)
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  if [ $IS_APPLY_MODE -eq 1 ]; then
    echo "$LOGO"
    echo -e "apply\n"
    build_symlinks
    echo -e "\n ようこそ、$(whoami) の世界へ。\n そして、あなたの帰還に感謝します。"
  else
    echo -e "dry-run\n"
    print_expectation
  fi
}

main "$@"
