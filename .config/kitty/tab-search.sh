#!/bin/bash

# Fetch kitty tabs info
data=$(kitty @ ls 2>/dev/null) || {
  echo "Error: Could not connect to kitty. Is allow_remote_control enabled?"
  sleep 2
  exit 1
}

# Parse and pipe to a styled floating FZF interface
id=$(echo "$data" | jq -r '
  .[].tabs[] |
  (.active_window_history[0]) as $active_win |
  .id as $tab_id |
  .title as $tab_title |
  ((.windows[] | select(.id == $active_win) | .cwd) // "") as $cwd |
  ($cwd | sub("^\(env.HOME)"; "~")) as $short |
  "\($tab_id)\t\($short)  →  \($tab_title)"
' | fzf \
    --ansi \
    --reverse \
    --border=rounded \
    --margin=30%,30% \
    --padding=1 \
    --header="Search" \
    --header-first \
    --color="border:#82a1f1,header:#82a1f1,pointer:#f43f5e,prompt:#38bdf8" \
    | cut -f1)

# Focus the selected tab if one was chosen
[ -n "$id" ] && kitty @ focus-tab --match id:"$id"

