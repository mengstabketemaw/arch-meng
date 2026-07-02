#!/usr/bin/env bash

SAVE_DIR="$HOME/Pictures"
SAVE_FILENAME="screenshot_$(date +%Y%m%d_%H%M%S).jpg"
NAME="$SAVE_FILENAME"

source "$HOME/.config/hypr/scripts/notification-handler.sh"
APP_NAME="Screen Capture"
NOTIFICATION_ICON="camera-photo-symbolic"
export GRIMBLAST_EDITOR="pinta"

take_screenshot() {
    local type="$1"
    grimblast copysave "$type" "$NAME"
    if [ -f "$HOME/$NAME" ] && [ -d "$SAVE_DIR" ]; then
        mv "$HOME/$NAME" "$SAVE_DIR/"
    fi
    notify_user \
        --a "${APP_NAME}" \
        --i "${NOTIFICATION_ICON}" \
        --s "Screenshot saved" \
        --m "$SAVE_DIR/$NAME" \
        --t 1000
}

if [[ "$1" == "--instant" ]]; then
    take_screenshot output
    exit 0
elif [[ "$1" == "--instant-area" ]]; then
    take_screenshot area
    exit 0
fi

chosen=$(rofi -dmenu -replace -config ~/.config/rofi/config-screenshot.rasi \
    -i -l 2 -width 30 -p "Screenshot" <<EOF
    Full Screen
    Selection
EOF
)

case "$chosen" in
    "    Full Screen") take_screenshot screen ;;
    "    Selection") take_screenshot area ;;
esac
