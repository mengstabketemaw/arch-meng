#!/usr/bin/env bash
# Phone hotspots often drop UDP broadcast, so KDE Connect can't auto-discover.
# Keep the current default gateway (the phone, when on its hotspot) in
# KDE Connect's customDevices list and refresh whenever the route changes.

CONF="$HOME/.config/kdeconnect/config"

sync_gateway() {
    local gw
    gw=$(ip -4 route show default | awk '{print $3; exit}')
    [ -z "$gw" ] && return
    mkdir -p "$(dirname "$CONF")"
    [ -f "$CONF" ] || printf '[General]\n' >"$CONF"
    grep -q "^customDevices=$gw$" "$CONF" && return
    if grep -q '^customDevices=' "$CONF"; then
        sed -i "s/^customDevices=.*/customDevices=$gw/" "$CONF"
    else
        sed -i "/^\[General\]/a customDevices=$gw" "$CONF"
    fi
    # daemon caches its config; restart so it reads the new address
    pkill -x kdeconnectd
    sleep 1
    setsid /usr/bin/kdeconnectd >/dev/null 2>&1 &
}

sync_gateway
kdeconnect-cli --refresh >/dev/null 2>&1

ip monitor route | while read -r line; do
    case "$line" in
    *default*)
        sleep 2
        sync_gateway
        kdeconnect-cli --refresh >/dev/null 2>&1
        ;;
    esac
done
