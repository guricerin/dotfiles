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
# Windows と共通のファイルと、macOS・Linux でだけ使うファイル。Windows 用は home-windows/ にあり、setup.ps1 がリンクする
readonly DOTFILES_HOMES=("$SCRIPT_ROOT/home-common" "$SCRIPT_ROOT/home-unix")

declare -ga SRCS=()
declare -ga DSTS=()

# リンク元とリンク先の組を SRCS と DSTS に集める
collect_pairs() {
  for home in "${DOTFILES_HOMES[@]}"; do
    for src in $(find $home -type f); do
      SRCS+=("$src")
      DSTS+=("${src/$home/$HOME}") # e.g. /home/username/dotfiles/home-unix/.zshrc => /home/username/.zshrc
    done
  done

  # home-common/ と home-unix/ の両方に同じパスがあると、どちらを張るか決められない
  local dups=$(printf '%s\n' "${DSTS[@]}" | sort | uniq -d)
  if [ -n "$dups" ]; then
    for dup in $dups; do
      printf "\e[0;31m  [x] home-common/ と home-unix/ の両方にある: ${dup/$HOME\//}\e[0m\n"
    done
    exit 1
  fi
}

build_symlinks() {
  # 意図しないファイルがリポジトリに含まれるのを防止したいので、ディレクトリのシムリンクは作成しない
  for i in "${!SRCS[@]}"; do
    local src=${SRCS[$i]}
    local dst=${DSTS[$i]}
    local parent=$(dirname $dst)
    if [ ! -d $parent ]; then
      mkdir -p $parent
    fi
    # シムリンクでない実ファイルだけを .bak に退避する
    if [ -f $dst ] && [ ! -L $dst ]; then
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
  for i in "${!SRCS[@]}"; do
    printf "\e[0;34m  [?] ${DSTS[$i]} -> ${SRCS[$i]}\e[0m\n"
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
  collect_pairs
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
