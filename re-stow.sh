#!/usr/bin/env bash

set -euo pipefail

OS="$(uname -s)"

stow -D -t ~/.config config-shared
stow -D -t ~/.local/bin localbin-shared
stow -D -t ~/ zsh
stow -D -t ~/ home-shared

stow -t ~/.config config-shared
stow -t ~/.local/bin localbin-shared
stow -t ~/ zsh
stow -t ~/ home-shared

if [[ "$OS" == "Linux" ]]; then
  stow -D -t ~/.config config-linux
  stow -D -t ~/.local/bin localbin-linux
  stow -t ~/.config config-linux
  stow -t ~/.local/bin localbin-linux
  hyprctl reload
  restart-app waybar
elif [[ "$OS" == "Darwin" ]]; then
  stow -D -t ~/.config config-mac
  stow -D -t ~/.local/bin localbin-mac
  stow -t ~/.config config-mac
  stow -t ~/.local/bin localbin-mac
fi
