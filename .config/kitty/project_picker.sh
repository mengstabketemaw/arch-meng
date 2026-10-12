#!/bin/bash

# Ensure ~/projects directory exists
if [ ! -d "$HOME/projects" ]; then
  echo "Error: ~/projects directory not found."
  sleep 2
  exit 1
fi

run_fzf() {
  find "$HOME/projects" -maxdepth 1 -mindepth 1 -type d | sed "s|^$HOME|~|" | fzf \
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

# Launch project in a clean new tab titled exactly after the folder name
kitty @ launch --type=tab --tab-title="$project_name" --cwd="$full_path"

