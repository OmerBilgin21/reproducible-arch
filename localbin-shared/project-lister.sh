#!/usr/bin/env bash

set -euo pipefail

OS="$(uname -s)"

project=$(find "$HOME/projects" -maxdepth 3 -name ".git" -type d 2>/dev/null |
  sed 's|/.git$||' |
  sort |
  fzf --prompt="project > " --height=50% --reverse --no-info)

if [ -n "$project" ]; then
  if [[ "$OS" == "Linux" ]]; then
    zeditor -e "$project"
  else
    zed -e "$project"
  fi
fi
