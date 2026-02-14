mkdir -p ~/.config
mkdir -p ~/.local/bin
stow -t ~/.config config
stow -t ~/.local/bin localbin
stow -t ~/ zsh
