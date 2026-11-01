#!/usr/bin/env bash
# Moves workspace 9 to the HDMI monitor whenever it gets plugged in.

HDMI="HDMI-A-1"
WS=9

move_ws() {
    hyprctl monitors -j | grep -q "\"name\": \"$HDMI\"" || return
    hyprctl dispatch moveworkspacetomonitor "$WS" "$HDMI" >/dev/null
}

move_ws

python3 -u - <<PY | while read -r line; do
import os, socket
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(f"{os.environ['XDG_RUNTIME_DIR']}/hypr/{os.environ['HYPRLAND_INSTANCE_SIGNATURE']}/.socket2.sock")
for line in s.makefile():
    print(line, end="")
PY
    case "$line" in
        monitoradded*">>$HDMI"*) sleep 0.5; move_ws ;;
    esac
done
