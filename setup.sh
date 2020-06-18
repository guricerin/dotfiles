#!/usr/bin/env bash

# 未定義変数があれば表示する
set -u
# エラー発生時、処理を中断する
set -e

dotfiles_logo='
    _        _    __ _ _
   | |      | |  / _(_) |
 __| |  ___ | |_| |_ _| | ___  ___
/  _  |/ _ \| __|  _| | |/ _ \/ __|
| (_| | (_) | |_| | | | |  __/\__ \
 \____|\___/ \__|_| |_|_|\___||___/
'

readonly SCRIPT_ROOT=$(cd $(dirname ${0}); pwd)
readonly DOTFILES_HOME=${SCRIPT_ROOT}/home

main() {
    for src in $(find ${DOTFILES_HOME}/ -maxdepth 1); do
        local dst="${HOME}/`basename ${src}`"
        [[ ${dst} == "${HOME}/home" ]] && continue
        ln -snf ${src} ${dst}
        printf "\e[0;32m  [o] ${dst} -> ${src}\e[0m\n"
    done
}

echo "$dotfiles_logo"
main