#!bin/bash

set -eu

extensions=$(cat ./extensions.txt)

for extension in $extensions; do
    echo "install $extension ..."
    code --install-extension $extension
done
