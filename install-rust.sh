#!/bin/bash

# rustup self uninstall

# curl https://sh.rustup.rs -sSf | sh
# source ~/.cargo/env

rustup update
rustup component add rls rust-analysis rust-src

#rustup toolchain install nightly
#rustup component add --toolchain=nightly rust-analysis
#rustup component add --toolchain=nightly rls-preview
#rustup component add --toolchain=nightly rust-src
