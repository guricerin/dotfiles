#!/bin/bash

echo "symbolic link dotfiles..."
for f in .??*; do
    [ "$f" = ".git" ] && continue;
    [ "$f" = ".gitignore" ] && continue;
    [ "$f" = ".DS_Store" ] && continue; # macの場合、このカスみたいなファイルも無視する。

    # HOMEに各dotfileのシンボリックリンクを貼る。
    ln -snfv ~/dotfiles/"$f" ~/
done

cat <<EOF

*******************************
dotfiles symboliclink finised.
*******************************

EOF
