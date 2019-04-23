#!/bin/bash

set -eu

extensions=(
    vscodevim.vim
    ms-vscode.cpptools
    ryanolsonx.zenburn
)

for i in ${extensions[@]}; do
    code --install-extension $i
done
