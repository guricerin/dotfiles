#!/usr/bin/env bash

brew install \
  zsh \
  sheldon \
  fzf \
  fd \
  ripgrep \
  bat \
  starship \
  pre-commit \
  gitleaks \
  gh \
  ghq \
  mise \
  nushell \
  uv
$(brew --prefix)/opt/fzf/install

# brew にない Python 製の CLI ツール
uv tool install skillspector
