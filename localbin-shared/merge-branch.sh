#!/bin/bash
# Merge a base branch into the current branch and conclude it once conflicts
# are resolved. Used by the merge-branch skill.
#
#   merge-branch.sh start [<branch>]       # merge <branch>, else the PR base, else the default branch
#   merge-branch.sh lockfile <path>        # take the base side of a conflicted package-lock.json and regenerate it
#   merge-branch.sh continue [<path>...]   # stage the conflicted paths plus <path>s, then git merge --continue
#
# Deliberately cannot: push, abort, reset, amend, skip hooks, merge into the
# default branch, or start a merge on top of uncommitted tracked changes.

set -euo pipefail

usage() {
  echo "usage: merge-branch.sh start [<branch>] | lockfile <path> | continue [<path>...]" >&2
  exit 2
}

die() {
  echo "$*" >&2
  exit 1
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a git work tree."

CURRENT=$(git branch --show-current)
[ -n "$CURRENT" ] || die "Detached HEAD. Check out a branch first."

PREFIX=$(git rev-parse --show-prefix)
cd "$(git rev-parse --show-toplevel)"

from_caller() {
  case "$1" in
  /*) echo "$1" ;;
  *) echo "$PREFIX$1" ;;
  esac
}

resolve_default() {
  DEFAULT=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | cut -d/ -f2- || true)
  if [ -z "$DEFAULT" ]; then
    DEFAULT=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || true)
  fi
  if [ -z "$DEFAULT" ]; then
    for candidate in main master; do
      if git show-ref --verify --quiet "refs/heads/$candidate" ||
        git show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
        DEFAULT=$candidate
        break
      fi
    done
  fi
}

refuse_default_branch() {
  if [ -n "$DEFAULT" ] && [ "$CURRENT" = "$DEFAULT" ]; then
    echo "Refusing: '$CURRENT' is this repository's default branch." >&2
    die "Merge into a feature branch instead."
  fi
}

merge_in_progress() {
  git rev-parse -q --verify MERGE_HEAD >/dev/null
}

require_merge() {
  merge_in_progress || die "No merge in progress. Start one with: merge-branch.sh start [<branch>]"
}

other_operation_in_progress() {
  local marker
  for marker in rebase-merge rebase-apply CHERRY_PICK_HEAD REVERT_HEAD; do
    if [ -e "$(git rev-parse --git-path "$marker")" ]; then
      return 0
    fi
  done
  return 1
}

has_markers() {
  local found=1 file
  for file in "$@"; do
    [ -f "$file" ] || continue
    if grep -HnIE '^(<{7}|[|]{7}|>{7})( |$)' -- "$file"; then
      found=0
    fi
  done
  return "$found"
}

is_unmerged() {
  [ -n "$(git ls-files -u -- "$1")" ]
}

cmd_start() {
  [ "$#" -le 1 ] || usage

  if merge_in_progress; then
    die "A merge is already in progress. Resolve it, then run: merge-branch.sh continue"
  fi
  if other_operation_in_progress; then
    die "A rebase, cherry-pick or revert is in progress. Finish it first."
  fi
  if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    git status --short --untracked-files=no >&2
    die "Uncommitted tracked changes. Commit or stash them before merging."
  fi

  resolve_default
  refuse_default_branch

  local base source
  if [ "$#" -eq 1 ]; then
    base=$1
    source=argument
  else
    base=$(gh pr view --json baseRefName -q .baseRefName 2>/dev/null || true)
    if [ -n "$base" ]; then
      source=pr
    else
      base=$DEFAULT
      source=default
    fi
  fi

  [ -n "$base" ] || die "Could not determine a base branch. Name one: merge-branch.sh start <branch>"
  case "$base" in
  -*) die "Not a valid branch name: $base" ;;
  esac
  git check-ref-format --branch "$base" >/dev/null 2>&1 || die "Not a valid branch name: $base"
  [ "$base" != "$CURRENT" ] || die "'$base' is the current branch."

  echo "base: $base (source: $source)"

  if git remote get-url origin >/dev/null 2>&1; then
    git fetch --quiet origin "$base" 2>/dev/null ||
      echo "warning: could not fetch $base from origin; using the refs already present." >&2
  fi

  local local_ref="refs/heads/$base" remote_ref="refs/remotes/origin/$base" ref name
  if git show-ref --verify --quiet "$local_ref" && git show-ref --verify --quiet "$remote_ref"; then
    if git merge-base --is-ancestor "$local_ref" "$remote_ref"; then
      ref=$remote_ref
      name="origin/$base"
    elif git merge-base --is-ancestor "$remote_ref" "$local_ref"; then
      ref=$local_ref
      name=$base
    else
      die "Local '$base' and 'origin/$base' have diverged. Reconcile them first."
    fi
  elif git show-ref --verify --quiet "$remote_ref"; then
    ref=$remote_ref
    name="origin/$base"
  elif git show-ref --verify --quiet "$local_ref"; then
    ref=$local_ref
    name=$base
  else
    die "No branch '$base' locally or on origin."
  fi

  echo "merging: $name @ $(git rev-parse --short "$ref")"

  if git merge-base --is-ancestor "$ref" HEAD; then
    echo "result: up-to-date"
    return
  fi

  local before
  before=$(git rev-parse HEAD)

  if git -c merge.conflictStyle=zdiff3 merge --no-commit -m "Merge branch '$base' into $CURRENT" "$name"; then
    if merge_in_progress; then
      echo "result: ready-to-continue"
    elif [ "$(git rev-parse HEAD)" != "$before" ]; then
      echo "result: fast-forward"
    else
      echo "result: up-to-date"
    fi
    return
  fi

  merge_in_progress || die "git merge failed before changing anything; see the output above."

  echo "result: conflicts"
  git status --porcelain=v1 --untracked-files=no | grep -E '^(DD|AU|UD|UA|DU|AA|UU) ' || true
}

cmd_lockfile() {
  [ "$#" -eq 1 ] || usage
  require_merge

  local lock dir pkg
  lock=$(from_caller "$1")
  [ "$(basename -- "$lock")" = "package-lock.json" ] || die "Only package-lock.json is handled: $1"
  is_unmerged "$lock" || die "$1 is not conflicted."

  dir=$(dirname -- "$lock")
  pkg="$dir/package.json"
  [ -f "$pkg" ] || die "No package.json next to $1."
  if has_markers "$pkg"; then
    die "Resolve the conflict markers in $pkg first."
  fi

  git checkout --theirs -- "$lock"
  (cd "$dir" && npm install --package-lock-only --ignore-scripts --no-audit --no-fund)
  echo "regenerated: $lock"
}

cmd_continue() {
  require_merge
  resolve_default
  refuse_default_branch

  local paths=() path
  while IFS= read -r -d '' path; do
    paths+=("$path")
  done < <(git diff -z --name-only --diff-filter=U)
  for path in "$@"; do
    paths+=("$(from_caller "$path")")
  done

  if [ "${#paths[@]}" -gt 0 ]; then
    if has_markers "${paths[@]}"; then
      die "Conflict markers remain at the lines above. Resolve them, then run continue again."
    fi
    git add -A -- "${paths[@]}"
  fi

  if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    git diff --name-only --diff-filter=U >&2
    die "Still conflicted. Resolve these paths, then run continue again."
  fi

  GIT_EDITOR=true git merge --continue
  git log --oneline -1

  local left
  left=$(git status --porcelain --untracked-files=no)
  if [ -n "$left" ]; then
    echo "left uncommitted:"
    echo "$left"
  fi
}

case "${1:-}" in
start)
  shift
  cmd_start "$@"
  ;;
lockfile)
  shift
  cmd_lockfile "$@"
  ;;
continue)
  shift
  cmd_continue "$@"
  ;;
*) usage ;;
esac
