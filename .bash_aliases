# Enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

if [ -f /usr/local/bin/brew ]; then
    alias emacs='/usr/local/Cellar/emacs-plus/26.1/bin/emacs-26.1'
fi

# 詳細表示
alias ll='ls -alF'

# カレント、親ディレクトリを除く隠しファイルを表示
alias la='ls -A'

# ファイルサイズ表示を整形
alias df='df -h'

# ファイル操作前に確認する
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'
