#!/usr/bin/env bash

set -euo pipefail

OS="$(uname -s)"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

stow -D -t ~/.config config-shared
stow -D -t ~/.local/bin localbin-shared
stow -D -t ~/.emacs.d emacs
stow -D -t ~/ zsh
stow -D -t ~/ home-shared

stow -t ~/.config config-shared
stow -t ~/.local/bin localbin-shared
stow -t ~/.emacs.d emacs
stow -t ~/ zsh
stow -t ~/ home-shared

if [[ "$OS" == "Linux" ]]; then
  stow -D -t ~/ home-linux
  stow -D -t ~/.config config-linux
  stow -D -t ~/.local/bin localbin-linux
  stow -t ~/.config config-linux
  stow -t ~/.local/bin localbin-linux
  stow -t ~/ home-linux
elif [[ "$OS" == "Darwin" ]]; then
  stow -D -t ~/.config config-mac
  stow -D -t ~/.local/bin localbin-mac
  stow -t ~/.config config-mac
  stow -t ~/.local/bin localbin-mac
fi

if command -v go >/dev/null; then
  "$HERE/go-tools/build.sh"
else
  echo "go is not installed, skipping go-tools build"
fi
