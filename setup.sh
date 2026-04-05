#!/usr/bin/env bash

set -euo pipefail

bakDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
yayPath="$HOME/yay"

ensurePac() {
  pacman -Qi "$1" &>/dev/null || sudo pacman -S --needed --noconfirm "$1"
}

ensureYay() {
  yay -Qi "$1" &>/dev/null || yay -S --needed --noconfirm "$1"
}

ensureYayInstalled() {
  if ! command -v yay >/dev/null 2>&1; then
    if [[ -d "$yayPath" ]]; then
      echo "removing previously installed yay clone to freshly install it..."
      rm -rf "$yayPath"
    fi
    echo "cloning yay..."
    git clone --depth 1 https://aur.archlinux.org/yay.git "$yayPath"
    echo "build yay..."
    cd "$yayPath" && makepkg -si --noconfirm
    echo "yay installation done"
    cd "$bakDir"
  fi
}

sudo pacman -Syu --noconfirm

echo "switch to work directory: $bakDir"
cd "$bakDir"

echo "Restoring pacman packages..."
while IFS= read -r line; do
  ensurePac "$line"
done <"$bakDir/installed-packages.txt"
echo "pacman package installations done, installing AUR packages..."

echo "installing yay..."
ensureYayInstalled

echo "Restoring AUR packages..."
while IFS= read -r line; do
  ensureYay "$line"
done <"$bakDir/installed-aur.txt"
echo "AUR installations done, installing mise packages..."

echo "Installing mise..."
ensurePac mise
echo "mise installations done, setting up zsh..."
mise install

echo "Switching shells..."
sudo usermod --shell "$(command -v zsh)" "$USER"

echo "Restoring user configs..."
ensurePac stow
"$bakDir/stow.sh"

read -r -p "Setup NVIDIA? (y/n)" confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  echo "starting nvidia setup..."

  echo "installing required packages for nvidia setup..."
  ensurePac nvidia-open-dkms
  ensurePac nvidia-utils
  ensurePac libva-nvidia-driver
  ensurePac nvidia-container-toolkit
  echo "nvidia package installations done, running nvidia setup script..."

  "$bakDir/nvidia.sh"
fi

echo "Done."
