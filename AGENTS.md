# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this repo is

Personal Arch Linux dotfiles for a KDE Plasma + Krohnkite (tiling) + NVIDIA setup, plus the development tooling that goes with it (Neovim, zsh, Go CLIs, agent configs). The repo lives at `~/reproducible-arch` and is deployed into `$HOME` with GNU stow — several files reference that absolute path, so it is effectively a fixed location.

It is a dotfiles repo, not an application: there is no build system, no test suite, and no CI. Editing a file here only affects the live system after a (re-)stow, or immediately if the file is already symlinked.

## Commands

```bash
./setup.sh              # full bootstrap: pacman + AUR + mise + stow + optional NVIDIA setup
./stow.sh               # link configs into $HOME (idempotent-ish, used on fresh machines)
./re-stow.sh            # unstow + restow everything — use this after changes
./kde-krohnkite-setup.sh # one-off, hand-invoked: applies Krohnkite/KWin keybinds and input niceties via kwriteconfig6 (not wired into stow/setup; see its header for re-run caveats)
./go-tools/build.sh     # build every go-tools/*/ with a go.mod into ~/.local/bin/<dirname>
```

`stow.sh` and `re-stow.sh` both call `go-tools/build.sh` at the end (skipped if `go` is missing).

Formatting/linting is editor-driven (conform.nvim + nvim-lint), not script-driven. If you change files here, match the tool that would run on them:

- shell → `shfmt` (zsh files use `shfmt -ln=zsh`); `shellcheck` directives are already sprinkled through `zsh/*`
- lua → `stylua` · go → `gofmt` · ts/js → `prettier` + `eslint_d` · json → `jq`
- `.editorconfig` applies repo-wide: LF, UTF-8, spaces, 2-space indent

The only package-manager project is `pi-stuff/extensions` (`npm run lint`, `npm run tsc`, `npm run format`).

## Changing KDE/KWin/Krohnkite settings

Any request to change a KWin global shortcut, window rule, Krohnkite setting, or other
live-system KDE config is a two-step job, in this order:

1. **Apply and verify it live first**, via whatever actually works for that setting
   (`kwriteconfig6` + `qdbus6 org.kde.KWin /KWin reconfigure`, `gdbus call ... setForeignShortcut`
   for shortcuts that are already registered, a throwaway KWin JS script loaded via
   `org.kde.KWin.Scripting.loadScript` to inspect live window/rule state, etc.). Confirm it
   actually took effect on the running session — don't assume a config write alone is enough;
   several of these (kglobalaccel especially) silently no-op on a plain ini edit. Report success
   or failure to the user based on the live result, not the file write.
2. **Once confirmed working, add that exact working version to `kde-krohnkite-setup.sh`** (new
   function/section as needed) so it's reproducible on a fresh install or after a re-run, not
   just a one-off hand fix. Don't add a version you haven't verified live - if the straightforward
   approach silently no-ops (common with kglobalaccel), find the one that actually works before
   writing it into the script.

## Stow layout — the central convention

Directory name encodes both the target and the platform. `stow.sh`/`re-stow.sh` map them as:

| Source dir         | Target          | Platform |
| ------------------ | --------------- | -------- |
| `config-shared`    | `~/.config`     | all      |
| `config-linux`     | `~/.config`     | Linux    |
| `config-mac`       | `~/.config`     | Darwin   |
| `localbin-shared`  | `~/.local/bin`  | all      |
| `localbin-linux`   | `~/.local/bin`  | Linux    |
| `localbin-mac`     | `~/.local/bin`  | Darwin   |
| `home-shared`      | `~/`            | all      |
| `home-linux`       | `~/`            | Linux    |
| `zsh`              | `~/`            | all      |
| `emacs`            | `~/.emacs.d`    | all      |

Consequences when adding something:

- A new file goes in the dir matching where it must land, with the in-target path mirrored underneath (e.g. `home-shared/.claude/settings.json` → `~/.claude/settings.json`).
- Anything in `localbin-*` must be executable and have no extension (it becomes a command on `$PATH`); `~/.local/bin` is prepended to `PATH` in `zsh/.zshenv`.
- Compiled Go binaries land in the same `~/.local/bin` but are *not* stowed — they are gitignored build output.
- `*-mac` dirs are mostly placeholders (`.gitkeep`); this machine is the Linux one.

## Directory map

- **`zsh/`** — `.zshrc` sources `.zshenv`, `.zshsecrets` (gitignored), `.zsh_vi_mode`, `.zsh_aliases` from `$HOME/reproducible-arch` directly, so edits to aliases/env take effect on `source ~/.zshrc` with no restow. zinit for plugins, mise for tool versions, starship prompt.
- **`config-shared/nvim/`** — see Neovim section below.
- **`localbin-linux/`** — the desktop's glue scripts, named by verb-prefix: `launch-*` (start/focus an app), `restart-*`, `pkg-*` (fzf-driven pacman/yay pickers), `cmd-*`, `drive-*`, `font-*`. Follow the existing prefix when adding one.
- **`localbin-shared/`** — cross-platform dev helpers: `commit-group.sh` (used by the atomic-commit skill; intentionally cannot push, amend, skip hooks, or commit to the default branch), `agent_review_diff` (splits the diff vs the merge-base with `origin/HEAD` into per-file chunks in `/tmp`), `project-lister.sh`, `tmux-window-picker`, `rg-finder`.
- **`go-tools/`** — one Go module per subdirectory, each built into a same-named binary:
  - `allow-chained-allowlist` — parses `~/.claude/settings.json` permission rules, splits a chained shell command into segments, and decides allow/ask/deny per segment (incl. redirect write-target checks). Has debug entrypoints: `--dump-rules`, `--split`, `--redirects`, `--decide`, `--cwd`. Used both as a Claude Code hook and by `config-shared/opencode/plugin/chain-allowlist.js`.
  - `prPicker` — lists GitHub PRs awaiting the user's review (config at `home-shared/.prPicker/config.json` → `~/.prPicker/config.json`); hands selections to the Neovim `custom.pr-review` module.
- **`pi-stuff/`** — the `pi` agent setup: `extensions/*.ts` (websearch/readability tools, permission gate) and `proxy/` (a Go reverse proxy on `:11435` that strips reasoning flags from Ollama requests, plus a SearXNG compose file). `localbin-linux/runpi` starts searxng + ollama + proxy, then `pi`.
- **`config-shared/opencode/`**, **`home-shared/.claude/`**, **`home-linux/.pi/`** — agent configs (models, MCP servers, permissions). The three share the same chained-allowlist hook and point at a local llama.cpp/Ollama endpoint. API keys and the tailscale URL live in gitignored `.opencode-*` files referenced as `{file:...}` from `opencode.json`.
- **`installed-packages.txt`, `installed-aur.txt`, `enabled-services.txt`** — hand-maintained snapshots read line-by-line by `setup.sh` (services file is informational only, it isn't applied). They are not auto-regenerated; update them when adding a package you want to survive a reinstall.

## Neovim

lazy.nvim with `root` pointed at `config-shared/nvim/plugin-code/`: **all plugins are vendored into this repo** (see README for the credit list), and a `LazyUpdate` autocmd strips their `.git` dirs so they stay plain files. So a plugin update is a content change in this repo, and `plugin-code/` is excluded from telescope searches (`!plugin-code/`) and from lua-ls (`ignoreDir`). Don't treat files under `plugin-code/` as this repo's code and don't reformat them.

Own code: `lua/config/` (presets, keymaps, snippets, landing screen), `lua/plugins/` (one file per concern, returning lazy specs), `lua/custom/` (first-party modules — `pr-review.lua`, a gh-cli + diffview PR review flow; `lsp-idle.lua`, currently commented out).
