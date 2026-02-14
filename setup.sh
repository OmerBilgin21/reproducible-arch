#!/usr/bin/env bash
# shellcheck disable=SC2317

set -euo pipefail

bakDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

read -r -p "are you here only for nvim with stow setup? (y/N): " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
  if ! command -v stow >/dev/null 2>&1; then
    echo "stow is required for nvim-only setup. Install it first, then retry."
    exit 1
  fi

  mkdir -p "$HOME/.config"

  if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$(date +%Y%m%d-%H%M%S)"
  fi

  stow -d "$bakDir/config" -t "$HOME/.config" nvim
  echo "nvim setup complete."
  exit 0
fi

echo "continuing with OS setup as usual"

yayPath="$HOME/yay"

ensurePac() {
  pacman -Qi "$1" &>/dev/null || sudo pacman -S --needed --noconfirm "$1"
}

ensureYay() {
  yay -Qi "$1" &>/dev/null || yay -S --needed --noconfirm "$1"
}

sudo pacman -Syu --noconfirm

ensurePac gum

if gum confirm "Restore pacman packages?"; then
  echo "[+] Restoring packages..."
  while IFS= read -r line; do
    ensurePac "$line"
  done <"$bakDir/installed-packages.txt"

  if [[ ! -d "$yayPath" ]]; then
    git clone https://aur.archlinux.org/yay.git "$yayPath"
    cd "$yayPath" && makepkg -si --noconfirm
  fi
fi

cd "$bakDir"

if gum confirm "Restore yay packages?"; then
  while IFS= read -r line; do
    ensureYay "$line"
  done <"$bakDir/installed-aur.txt"
fi

if gum confirm "Restore user configs?"; then
  echo "[+] Restoring user configs..."
  ensurePac stow
  chmod +x "$bakDir/stow.sh"
  $bakDir/stow.sh
fi

if gum confirm "Setup NVIDIA?"; then
  echo "[+] starting nvidia setup..."
  chmod +x "$bakDir/nvidia.sh"
  $bakDir/nvidia.sh
fi

if gum confirm "Make ZSH your default shell?"; then
  echo "[+] switching shells..."
  chsh -s "$(which zsh)"
fi

if gum confirm "Install and setup mise/mise-packages?"; then
  ensurePac mise
  mise install
fi

#   REMINDER SERVICES!
#   dnscrypt-proxy.service
#   tlp.service
#   nvidia-hibernate.service
#   nvidia-resume.service
#   nvidia-suspend.service
#   greetd.service
#   docker.service

echo "[+] Done."
