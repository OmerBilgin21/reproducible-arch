#!/bin/bash
# Stage and commit one logical group of changes. Used by the atomic-commit skill.
#
#   commit-group.sh <message> <path>...
#
# Deliberately cannot: push, amend, skip hooks, commit to the default branch,
# or commit paths it was not explicitly given. There are no flags to pass.

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: commit-group.sh <message> <path>..." >&2
  exit 2
fi

MESSAGE="$1"
shift

[ -n "${MESSAGE//[[:space:]]/}" ] || {
  echo "Empty commit message." >&2
  exit 2
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  {
    echo "Not inside a git work tree." >&2
    exit 2
  }

CURRENT=$(git branch --show-current)
[ -n "$CURRENT" ] || {
  echo "Detached HEAD. Check out a branch first." >&2
  exit 2
}

# Default branch: origin/HEAD, then the forge, then the usual names.
DEFAULT=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | cut -d/ -f2- || true)
if [ -z "$DEFAULT" ]; then
  DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || true)
fi

if [ -n "$DEFAULT" ]; then
  IS_DEFAULT=$([ "$CURRENT" = "$DEFAULT" ] && echo yes || echo no)
else
  case "$CURRENT" in
  main | master)
    IS_DEFAULT=yes
    DEFAULT="$CURRENT"
    ;;
  *) IS_DEFAULT=no ;;
  esac
fi

if [ "$IS_DEFAULT" = "yes" ]; then
  echo "Refusing to commit: '$CURRENT' is this repository's default branch." >&2
  echo "Move these changes to a feature branch first." >&2
  exit 1
fi

# `--` stops flag parsing, so a path can never be read as an option.
git add -- "$@"

if git diff --cached --quiet -- "$@"; then
  echo "Nothing staged for the given paths; no commit made." >&2
  exit 1
fi

git commit -m "$MESSAGE" -- "$@"
