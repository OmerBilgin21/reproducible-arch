#!/usr/bin/env bash

set -euo pipefail

OS="$(uname -s)"

# because we do the --adopt then discard changes trick for hyprland.conf
# this exit is good to have, I don't wanna lose my changes if I have some
git diff --quiet HEAD ./config-linux/hypr/hyprland.conf || {
  echo "You have changes in hyprland.conf, those would be lost. First commit them before running re-stow.sh"
  exit 1
}

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
  # I have to use --adopt here because apparently hyprland changed behaviour
  # and is now always spitting out a hyprland.conf file if it's absent.
  stow -t ~/.config config-linux --adopt
  git checkout -- ./config-linux/hypr/hyprland.conf
  stow -t ~/.local/bin localbin-linux
  stow -t ~/ home-linux
  sleep 3
  hyprctl reload # for waybar
  sleep 1
  hyprctl reload # for hyprland
  restart-app waybar
elif [[ "$OS" == "Darwin" ]]; then
  stow -D -t ~/.config config-mac
  stow -D -t ~/.local/bin localbin-mac
  stow -t ~/.config config-mac
  stow -t ~/.local/bin localbin-mac
fi
