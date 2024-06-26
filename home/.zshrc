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

alias g='git'

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

# wsl2 default browser
export BROWSER="/mnt/c/Program\ Files/Mozilla\ Firefox/firefox.exe"

# config
export XDG_CONFIG_HOME="$HOME/.config"

# linuxbrew
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

# Go (via brew)
export GOPATH="$(go env GOPATH)"

# Rust (via rustup)
export PATH="$HOME/.cargo/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# asdf
. /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh

# starship (last line)
eval "$(starship init zsh)"
