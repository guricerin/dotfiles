# bash_aliasesをロード
if [ -f "${HOME}/.bash_aliases" ]; then
    source "${HOME}/.bash_aliases"
fi

# config
export XDG_CONFIG_HOME="$HOME/.config"

# tmux
# alias tmux="tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"
export RUST_SRC_PATH="$HOME/.multirust/toolchains/nightly-x86_64-apple-darwin/lib/rustlib/src/rust/src"

# Ruby
# rbenvコマンドがある場合のみ
if type rbenv > /dev/null 2>&1; then
	eval "$(rbenv init -)"
fi

# Haskell
export PATH="$HOME/.local/bin:$PATH"
alias ghci='stack ghci'
alias ghc='stack ghc --'
alias runghc='stack runghc --'

# lsp (for C++, macos)
#export PATH="$HOME/ccls/Release:$PATH"
#export PATH="/usr/local/opt/llvm/bin:$PATH"
#export LDFLAGS="-L/usr/local/opt/llvm/lib"
#export CPPFLAGS="-I/usr/local/opt/llvm/include"

# fishがインストールされているなら実行
#if type fish > /dev/null 2>&1; then
#	exec fish
#fi
