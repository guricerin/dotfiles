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

# config
export XDG_CONFIG_HOME="$HOME/.config"

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

# my-bin
export PATH="$HOME/bin:$PATH"

# sheldon (via brew): shell用プラグインマネージャー
## https://github.com/rossmacarthur/sheldon
## load plugins
eval "$(sheldon source)"

# mise: バージョン管理ツール
## https://github.com/jdx/mise
eval "$(mise activate zsh)"

# fzf (via brew): 曖昧検索
source <(fzf --zsh)
## .gitディレクトリを除外し、カレントディレクトリ以下のディレクトリとファイルを再帰的に曖昧検索
export FZF_DEFAULT_COMMAND='fd -H -E .git'
## 検索結果はターミナルの下側に表示させる
export FZF_DEFAULT_OPTS="--reverse --height=90%"
## CTRL + T でカレントディレクトリ以下のファイルをプレビュー表示しつつ曖昧検索
export FZF_CTRL_T_COMMAND='fd --type f -H -E .git'
export FZF_CTRL_T_OPTS='--preview "head -100 {}"'
# Ctrl + G で リポジトリ移動
function ghq-fzf-cd() {
  local dir
  dir=$(ghq list --full-path | fzf)
  if [[ -n "$dir" ]]; then
    cd "$dir" || { echo "Error: Failed to change directory to '$dir'"; return; }
    zle reset-prompt
  fi
}
zle -N ghq-fzf-cd
bindkey '^G' ghq-fzf-cd

# kubectl
if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
fi
# krew: k8s plugin manager (via brew)
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# helm
if command -v helm >/dev/null 2>&1; then
  source <(helm completion zsh)
fi

# Go (via brew)
if command -v go >/dev/null 2>&1; then
  export GOPATH="$(go env GOPATH)"
fi

# Rust (via rustup)
export PATH="$HOME/.cargo/bin:$PATH"

# bun
if [ -d "$HOME/.bun" ]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  ## bun completions
  [ -f "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
fi

# alias
alias l='ls -alF --color=auto'
## ファイル操作前に確認する
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# zsh-abbr: alias と違って、元のコマンドへと展開してくれる
## `*`以降の文字で連結した直後の略語も展開する
ABBR_REGULAR_ABBREVIATION_GLOB_PREFIXES+=(
  '*& '
  '*&& '
  '*| '
  '*|| '
  '*; '
)
abbr -S wh='which' >> /dev/null
abbr -S g='git' >> /dev/null
abbr -S f='fzf' >> /dev/null
abbr -S d='docker' >> /dev/null
abbr -S dc='docker compose' >> /dev/null
abbr -S k='kubectl' >> /dev/null
abbr -S tf='terraform' >> /dev/null

# starship: プロンプト改造
## https://starship.rs/
## ↓は最終行に書くこと
eval "$(starship init zsh)"
