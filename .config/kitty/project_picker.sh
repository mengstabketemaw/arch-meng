#!/bin/bash

# Ensure ~/projects directory exists
if [ ! -d "$HOME/projects" ]; then
  echo "Error: ~/projects directory not found."
  sleep 2
  exit 1
fi

# A folder holding only sub-folders is a group, not a project: list its
# children instead (recursively). Anything with a file or a .git is a project.
list_projects() {
  local dir="$1" depth="$2" child
  for child in "$dir"/*/; do
    [ -d "$child" ] || continue
    child="${child%/}"
    if [ "$depth" -lt 5 ] && [ ! -e "$child/.git" ] &&
       [ -n "$(find "$child" -mindepth 1 -maxdepth 1 -not -name '.*' -print -quit)" ] &&
       [ -z "$(find "$child" -mindepth 1 -maxdepth 1 -not -type d -print -quit)" ]; then
      list_projects "$child" $((depth + 1))
    else
      echo "$child"
    fi
  done
}

# Extra folders outside ~/projects that should always be listed
EXTRA_PROJECTS=("$HOME/arch-meng")

run_fzf() {
  {
    for extra in "${EXTRA_PROJECTS[@]}"; do [ -d "$extra" ] && echo "$extra"; done
    list_projects "$HOME/projects" 1
  } | sed "s|^$HOME|~|" | fzf \
      --ansi \
      --print-query \
      --expect=alt-enter \
      --reverse \
      --border=rounded \
      --margin=30%,30% \
      --padding=1 \
      --header="Open Project  (no match + Enter / Alt+Enter: create ~/projects/<query>)" \
      --header-first \
      --color="border:#82a1f1,header:#82a1f1,pointer:#f43f5e,prompt:#38bdf8"
}

# fzf output: line 1 = query, line 2 = key pressed (empty or alt-enter),
# line 3 = selected entry (empty when nothing matched)
output=$(run_fzf)
status=$?
# 130 = Escape / Ctrl-C: just close the overlay
[ "$status" -eq 130 ] && exit 0

query=$(sed -n 1p <<<"$output")
key=$(sed -n 2p <<<"$output")
selected_dir=$(sed -n 3p <<<"$output")

if [ "$key" = "alt-enter" ] || [ -z "$selected_dir" ]; then
  # Create a new project named after the query (sub-paths like group/name ok)
  query="${query#"${query%%[![:space:]]*}"}"; query="${query%"${query##*[![:space:]]}"}"
  [ -z "$query" ] && exit 0
  case "$query" in
    /*|*..*) echo "Invalid project name: $query"; sleep 2; exit 1 ;;
  esac
  full_path="$HOME/projects/$query"
  mkdir -p "$full_path" || { sleep 2; exit 1; }
  [ -e "$full_path/.git" ] || git -C "$full_path" init -q
else
  full_path="${selected_dir/#\~/$HOME}"
fi
project_name=$(basename "$full_path")

# Open the project in a new tab titled after the folder, with Neovim running
# nvim runs inside an interactive zsh (so .zshrc PATH/env apply); quitting it
# leaves a shell in the project folder instead of closing the tab
kitty @ launch --type=tab --tab-title="$project_name" --cwd="$full_path" --var "wt=$full_path" zsh -ic 'nvim; exec zsh'

