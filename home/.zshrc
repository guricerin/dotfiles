# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/guri/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

#######################################################################################
# my .zshrc

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
alias l='ls -alF'

# ファイル操作前に確認する
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# config
export XDG_CONFIG_HOME="$HOME/.config"

# git
alias g='git'

if [[ "$(uname -r)" == *-microsoft-standard-WSL2 ]]; then
  echo "This is wsl2"
  # wsl2 default browser
  export BROWSER="/mnt/c/Program\ Files/Mozilla\ Firefox/firefox.exe"
  # linuxbrew
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
elif [[ "$(uname)" == "Darwin" ]]; then
  echo "This is macos"
  # homebrew
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# fzf (via brew): 曖昧検索
alias f='fzf'
[[ $commands[fzf] ]] && source <(fzf --zsh)
## .gitディレクトリを除外し、カレントディレクトリ以下のディレクトリとファイルを再帰的に曖昧検索
export FZF_DEFAULT_COMMAND='fd -H -E .git'
## 検索結果はターミナルの下側に表示させる
export FZF_DEFAULT_OPTS="--reverse --height=90%"
## CTRL + T でカレントディレクトリ以下のファイルをプレビュー表示しつつ曖昧検索
export FZF_CTRL_T_COMMAND='fd --type f -H -E .git'
export FZF_CTRL_T_OPTS='--preview "head -100 {}"'

# docker
alias d='docker'
alias dc='docker compose'

# kubernetes
alias k='kubectl'
## kubectl completion
[[ $commands[kubectl] ]] && source <(kubectl completion zsh)

# terraform
alias tf='terraform'

# my-bin
export PATH="$HOME/bin:$PATH"

# sheldon (via brew): shell用プラグインマネージャー
## load plugins
eval "$(sheldon source)"

# Go (via brew)
export GOPATH="$(go env GOPATH)"

# Rust (via rustup)
export PATH="$HOME/.cargo/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# starship: プロンプト改造
## ↓は最終行に書くこと
eval "$(starship init zsh)"
