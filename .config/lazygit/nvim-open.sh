#!/usr/bin/env bash
# Open a file (or directory) from lazygit in Neovim.
#
#   nvim-open.sh <path> [line]
#
# - Inside Neovim (lazygit started from <leader>gg or a :terminal, so $NVIM is set):
#   ask the parent Neovim to close lazygit and open the file in the window you came from.
# - Standalone lazygit: open Neovim in the repo root so the whole project is available.
#   Quitting Neovim drops you back into lazygit.

path="$1"
line="${2:-}"

abs="$(realpath -m -- "$path")"

if [ -n "$NVIM" ]; then
  # JSON-encode the path so it is a valid Vimscript string literal
  arg="$(printf '%s' "$abs" | jq -Rs .)"
  exec nvim --server "$NVIM" --remote-expr "v:lua.LazygitOpen($arg, '${line:-0}')" >/dev/null
fi

# Standalone: start Neovim from the repo root so pickers/LSP see the whole project
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root" || exit 1
if [ -n "$line" ] && [ "$line" != "0" ]; then
  exec nvim "+$line" -- "$abs"
else
  exec nvim -- "$abs"
fi
