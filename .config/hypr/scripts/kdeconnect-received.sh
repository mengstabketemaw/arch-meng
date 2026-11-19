#!/usr/bin/env bash
# KDE Connect reports finished transfers through Plasma's JobView service,
# which doesn't exist on Hyprland. Listen for the share plugin's
# shareReceived signal instead and show a notification with Open/Folder actions.

dbus-monitor --session "type='signal',interface='org.kde.kdeconnect.device.share',member='shareReceived'" |
    while read -r line; do
        case "$line" in
        *'string "file://'*)
            url=${line#*string \"}
            url=${url%\"}
            raw=${url#file://}
            path=$(printf '%b' "${raw//%/\\x}") # percent-decode
            (
                action=$(notify-send -a "KDE Connect" -i kdeconnect \
                    -A open=Open -A folder="Show in folder" \
                    "File received" "$(basename "$path")")
                case "$action" in
                open) xdg-open "$path" ;;
                folder) xdg-open "$(dirname "$path")" ;;
                esac
            ) &
            ;;
        esac
    done
