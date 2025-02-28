#!/usr/bin/env bash

# 未定義変数があれば表示する
set -u
# エラー発生時、処理を中断する
set -e

# https://patorjk.com/software/taag/#p=display&f=Efti%20Wall&t=dotfiles
readonly LOGO=$'
        ...       #   ___                          _          .      .      _     _         |"|
   o,*,(o o)      #  <_*_>         ()_()         _|_|_      .  .:::.      o\' \,=./ `o      _|_|_       `  _ ,  \'
  8(o o)(_)Ooo    #  (o o)         (o o)         (o o)        :(o o):  .     (o o)         (o o)      -  (o)o)  -
ooO-(_)---Ooo-----8---(_)--Ooo-ooO--`o\'--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo--ooO\'(_)--Ooo-
'

readonly SCRIPT_ROOT=$(cd $(dirname $0); pwd)
readonly DOTFILES_HOME_ABS_PATH="$SCRIPT_ROOT/home"

build_symlink() {
  echo "Start to build symlink."
  # 意図しないファイルがリポジトリに含まれるのを防止したいので、ディレクトリのシムリンクは作成しない
  for src in $(find $DOTFILES_HOME_ABS_PATH -type f); do
    echo "---"
    local dst=${src/$DOTFILES_HOME_ABS_PATH/$(echo $HOME)} # e.g. /home/username/dotfiles/home/.zshrc => /home/username/.zshrc
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

main() {
  echo "$LOGO"
  build_symlink
  echo -e "\n ようこそ、dotfiles へ。\n そして、あなたの帰還に感謝します。"
}

main
