#!/usr/bin/env bash

# 未定義変数があれば表示する
set -u
# エラー発生時、処理を中断する
set -e

# use colors on terminal
tput=$(which tput)
if [ -n "$tput" ]; then
    ncolors=$($tput colors)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    NORMAL=""
fi

### functions
# info: output terminal green
info() {
    printf "${GREEN}"
    echo -n "  info  "
    printf "${NORMAL}"
    echo "$1"
}
# error: output terminal red
error() {
    printf "${RED}"
    echo -n "  error "
    printf "${NORMAL}"
    echo "$1"
}
# warn: output terminal yellow
warn() {
    printf "${YELLOW}"
    echo -n "  warn  "
    printf "${NORMAL}"
    echo "$1"
}
# log: out put termial normal
log() {
    echo "  $1"
}

OS="unknown"

os_type() {
    if [ "$(uname)" == 'Darwin' ]; then
        echo setup for mac
        OS="mac"
    elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
        echo setup for linux
        OS="linux"
    else
        echo "OS is unknown. exit setup."
        return -1
    fi
}

dotfiles_logo='
    _        _    __ _ _
   | |      | |  / _(_) |
 __| |  ___ | |_| |_ _| | ___  ___
/  _  |/ _ \| __|  _| | |/ _ \/ __|
| (_| | (_) | |_| | | | |  __/\__ \
 \____|\___/ \__|_| |_|_|\___||___/
'
echo "$dotfiles_logo"

read -p "$(warn 'Are you sure you want to install it? [y/n] ')" -n 1 -r

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    error 'Installation failed. Nothing changed.'
    exit 1
fi

echo ""
info "symlink dotfiles..."
cd non-xdg/
for f in .??*; do
    [ "$f" = ".git" ] && continue;
    [ "$f" = ".gitignore" ] && continue;
    [ "$f" = ".DS_Store" ] && continue; # macの場合、このカスみたいなファイルも無視する

    # HOMEに各dotfileのシンボリックリンクを貼る
    ln -snfv $HOME/dotfiles/non-xdg/"$f" $HOME
done

# .config
# cp -rf ./config/ $HOME/.config
ln -snfv $HOME/dotfiles/config/ $HOME/.config

os_type
if [ "$OS" == "mac" ]; then
    VSCODE_PATH="~/Library/Application\ Support/Code/User"
    rm -f ~/Library/Application\ Support/Code/User/settings.json
    ln -snfv ~/dotfiles/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
    rm -f ~/Library/Application\ Support/Code/User/keybindings.json
    ln -snfv ~/dotfiles/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
fi

info 'dotfiles symlink finised.'
