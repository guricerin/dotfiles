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
alias dc='docker'
alias dcc='docker compose'
alias k='kubectl'

# config
export XDG_CONFIG_HOME="$HOME/.config"

# Go
export PATH="$HOME/go/bin:$PATH"
export GOPATH="$(go env GOPATH)"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# linuxbrew
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

# nvm
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Deno
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# starship
eval "$(starship init zsh)"
