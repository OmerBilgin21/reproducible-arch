#!/usr/bin/env bash

set -euo pipefail

project=$(find "$HOME/projects" -maxdepth 3 -name ".git" -type d 2>/dev/null |
  sed 's|/.git$||' |
  sort |
  fzf --prompt="project > " --height=50% --reverse --no-info)

[ -n "$project" ] && zeditor -r "$project"
