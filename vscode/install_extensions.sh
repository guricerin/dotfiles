#!/bin/bash

set -eu

extensions=(
    vscodevim.vim
    ms-vscode.cpptools
    ryanolsonx.zenburn
    mechatroner.rainbow-csv
    CoenraadS.bracket-pair-colorizer
    rust-lang.rust
)

for i in ${extensions[@]}; do
    code --install-extension $i
done
