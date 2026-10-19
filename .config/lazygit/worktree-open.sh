#!/usr/bin/env bash
# Jump to the kitty tab running Neovim in a git worktree, or open one.
#
#   worktree-open.sh <worktree-path>
#
# Each worktree gets its own Neovim in its own kitty tab, so the one you were
# working in keeps running in the background (buffers, LSP, debugger, terminals).
# Tabs are tagged with the kitty user var `wt=<path>`; tabs opened some other way
# (e.g. project_picker.sh) are still found through a Neovim running in that path.
#
# Needs `listen_on` in kitty.conf so it also works from lazygit inside Neovim.

path="$1"
[ -z "$path" ] && { echo "usage: worktree-open.sh <worktree-path>" >&2; exit 1; }
abs="$(realpath -- "$path")" || exit 1

if [ -z "$KITTY_LISTEN_ON" ] || ! command -v kitty >/dev/null; then
  echo "kitty remote control unavailable (set listen_on in kitty.conf and restart kitty)" >&2
  exit 1
fi

tab_id="$(kitty @ ls 2>/dev/null | jq -r --arg p "$abs" '
  [ .[].tabs[]
    | select(any(.windows[];
        .user_vars.wt == $p
        or any(.foreground_processes[]?;
                 .cwd == $p and ((.cmdline[0] // "") | test("(^|/)nvim$")))))
    | .id ] | first // empty')"

if [ -n "$tab_id" ]; then
  exec kitty @ focus-tab --match "id:$tab_id"
fi

# Title: <main repo folder>:<branch>, e.g. etswitch-ips:develop
common="$(git -C "$abs" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
repo="$(basename "$(dirname "$common")")"
branch="$(git -C "$abs" branch --show-current 2>/dev/null)"
[ -z "$branch" ] && branch="$(git -C "$abs" rev-parse --short HEAD 2>/dev/null)"
title="${repo:-$(basename "$abs")}:${branch:-?}"

# Same shape as project_picker.sh: quitting Neovim leaves a shell in the worktree
exec kitty @ launch --type=tab --tab-title="$title" --cwd="$abs" --var "wt=$abs" \
  zsh -ic 'nvim; exec zsh' >/dev/null
