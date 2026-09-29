#!/usr/bin/env bash

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="$HOME/.local/bin"

mkdir -p "$target"

for tool in "$here"/*/; do
  name="$(basename "$tool")"
  [ -f "$tool/go.mod" ] || continue
  echo "building $name -> $target/$name"
  (cd "$tool" && go build -o "$target/$name" .)
done
