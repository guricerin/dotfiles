# bash_aliasesをロード
if [ -f "${HOME}/.bash_aliases" ]; then
    source "${HOME}/.bash_aliases"
fi

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
