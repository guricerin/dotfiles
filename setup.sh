#!/usr/bin/env bash

# 未定義変数があれば表示する
set -u
# エラー発生時、処理を中断する
set -e

# https://patorjk.com/software/taag/#p=display&f=Efti%20Wall&t=dotfiles
readonly LOGO=$'
        ...       #   ___                          _          .      .      _     _         |"|
   o,*,(o o)      #  <_*_>         ()_()         _|_|_      .  .:::.      o\' \\,=./ `o      _|_|_       `  _ ,  \'
  8(o o)(_)Ooo    #  (o o)         (o o)         (o o)        :(o o):  .     (o o)         (o o)      -  (o)o)  -
ooO-(_)---Ooo-----8---(_)--Ooo-ooO--`o\'--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo--ooO\'(_)--Ooo-
'

readonly SCRIPT_ROOT=$(cd $(dirname $0); pwd)
readonly DOTFILES_HOME="$SCRIPT_ROOT/home"

build_symlinks() {
  # 意図しないファイルがリポジトリに含まれるのを防止したいので、ディレクトリのシムリンクは作成しない
  for src in $(find $DOTFILES_HOME -type f); do
    local dst=${src/$DOTFILES_HOME/$(echo $HOME)} # e.g. /home/username/dotfiles/home/.zshrc => /home/username/.zshrc
    local parent=$(dirname $dst)
    if [ ! -d $parent ]; then
      mkdir -p $parent
    fi
    if [ -f $dst ]; then
      cp $dst $dst.bak
    fi
    ln -snf $src $dst
  done
}

confirm_apply() {
  if [ $IS_AUTO_APPROVE -eq 1 ]; then
    return 0
  fi
  local answer
  read -r -p "続けますか？ [y/N] " answer || answer=""
  case $answer in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      echo "中止しました"
      exit 1
      ;;
  esac
}

print_expectation() {
  for src in $(find $DOTFILES_HOME -type f); do
    local dst=${src/$DOTFILES_HOME/$(echo $HOME)}
    printf "\e[0;34m  [?] $dst -> $src\e[0m\n"
  done
}

declare -g IS_DRY_RUN=0
declare -g IS_AUTO_APPROVE=0

parse_args() {
  for arg in "$@"; do
    case $arg in
      -n|--dry-run)
        IS_DRY_RUN=1
        ;;
      -y|--yes)
        IS_AUTO_APPROVE=1
        ;;
      *)
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  if [ $IS_DRY_RUN -eq 1 ]; then
    echo -e "dry-run\n"
    print_expectation
  else
    print_expectation
    echo
    confirm_apply
    echo "$LOGO"
    echo -e "apply\n"
    build_symlinks
    echo -e "\n ようこそ、$(whoami) の世界へ。\n そして、あなたの帰還に感謝します。"
  fi
}

main "$@"
