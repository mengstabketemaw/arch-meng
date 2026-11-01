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

run_fzf() {
  list_projects "$HOME/projects" 1 | sed "s|^$HOME|~|" | fzf \
      --ansi \
      --reverse \
      --border=rounded \
      --margin=30%,30% \
      --padding=1 \
      --header="Open Project" \
      --header-first \
      --color="border:#82a1f1,header:#82a1f1,pointer:#f43f5e,prompt:#38bdf8"
}

# Capture the selection safely
selected_dir=$(run_fzf)

# Escape makes fzf exit with no output; the overlay then just closes
[ -z "$selected_dir" ] && exit 0

full_path="${selected_dir/#\~/$HOME}"
project_name=$(basename "$full_path")

# Open the project in a new tab titled after the folder, with Neovim running
# nvim runs inside an interactive zsh (so .zshrc PATH/env apply); quitting it
# leaves a shell in the project folder instead of closing the tab
kitty @ launch --type=tab --tab-title="$project_name" --cwd="$full_path" --var "wt=$full_path" zsh -ic 'nvim; exec zsh'

