#!/usr/bin/env bash

set -euo pipefail

mkdir -p ~/.config
mkdir -p ~/.local/bin

OS="$(uname -s)"

stow -t ~/.config config-shared
stow -t ~/.local/bin localbin-shared
stow -t ~/ zsh
stow -t ~/ home-shared

if [[ "$OS" == "Linux" ]]; then
  stow -t ~/.config config-linux
  stow -t ~/.local/bin localbin-linux
elif [[ "$OS" == "Darwin" ]]; then
  stow -t ~/.config config-mac
  stow -t ~/.local/bin localbin-mac
fi
