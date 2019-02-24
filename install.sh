#!/usr/bin/env bash

# 未定義変数があれば表示する
set -u

# エラー発生時、処理を中断する
# set -e

echo "symlink dotfiles..."
for f in .??*; do
    [ "$f" = ".git" ] && continue;
    [ "$f" = ".gitignore" ] && continue;
    [ "$f" = ".DS_Store" ] && continue; # macの場合、このカスみたいなファイルも無視する

    # HOMEに各dotfileのシンボリックリンクを貼る
    ln -snfv ~/dotfiles/"$f" $HOME
done

cat <<EOF

*******************************
dotfiles symlink finised.
*******************************

EOF
