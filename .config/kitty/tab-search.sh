#!/bin/bash

data=$(kitty @ ls 2>/dev/null) || {
  echo "Error: Could not connect to kitty. Is allow_remote_control enabled?"
  sleep 2
  exit 1
}

id=$(echo "$data" | jq -r '
  .[].tabs[] |
  (.active_window_history[0]) as $active_win |
  .id as $tab_id |
  .title as $tab_title |
  ((.windows[] | select(.id == $active_win) | .cwd) // "") as $cwd |
  ($cwd | sub("^\(env.HOME)"; "~")) as $short |
  "\($tab_id)\t\($short)  \($tab_title)"
' | fzf | cut -f1)

[ -n "$id" ] && kitty @ focus-tab --match id:"$id"
