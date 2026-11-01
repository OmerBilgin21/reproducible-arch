if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  if [[ -d "$HOMEBREW_PREFIX/opt/libpq/bin" ]]; then
    export PATH="$HOMEBREW_PREFIX/opt/libpq/bin:$PATH"
  fi
fi
