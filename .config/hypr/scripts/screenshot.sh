#!/usr/bin/env bash

SAVE_DIR="$HOME/Pictures"
mkdir -p "$SAVE_DIR"

source "$HOME/.config/hypr/scripts/notification-handler.sh"
APP_NAME="Screen Capture"
NOTIFICATION_ICON="camera-photo-symbolic"

take_screenshot() {
    local mode="$1"
    local filename="screenshot_$(date +%Y%m%d_%H%M%S).png"
    hyprshot -m "$mode" -o "$SAVE_DIR" -f "$filename" -z
    notify_user \
        --a "${APP_NAME}" \
        --i "${NOTIFICATION_ICON}" \
        --s "Screenshot saved" \
        --m "$SAVE_DIR/$filename" \
        --t 1000
}

if [[ "$1" == "--instant" ]]; then
    take_screenshot output
    exit 0
elif [[ "$1" == "--instant-area" ]]; then
    take_screenshot region
    exit 0
fi

chosen=$(rofi -dmenu -replace -config ~/.config/rofi/config-screenshot.rasi \
    -i -l 2 -width 30 -p "Screenshot" <<EOF
    Full Screen
    Selection
EOF
)

case "$chosen" in
    "    Full Screen") take_screenshot output ;;
    "    Selection") take_screenshot region ;;
esac