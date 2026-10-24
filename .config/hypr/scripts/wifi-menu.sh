#!/usr/bin/env bash
# __        ___       _____ _
# \ \      / (_)     |  ___(_)
#  \ \ /\ / /| |_____| |_  | |
#   \ V  V / | |_____|  _| | |
#    \_/\_/  |_|     |_|   |_|
#

# -----------------------------------------------------
# Wi-Fi menu (rofi + iwctl): scan, connect, disconnect, forget
# -----------------------------------------------------

THEME=~/.config/rofi/config-wifi.rasi

menu() { # menu <placeholder> [mesg] — reads entries on stdin, prints selected index
    rofi -dmenu -i -replace -format i -config "$THEME" \
        -theme-str "entry { placeholder: \"$1\"; }" ${2:+-mesg "$2"}
}

ask() { # ask <placeholder> [password] — free text input, no list
    rofi -dmenu -replace -config "$THEME" ${2:+-password} \
        -theme-str "entry { placeholder: \"$1\"; } listview { enabled: false; }" </dev/null
}

error() {
    rofi -e "$1" -config "$THEME"
}

iwc() { # iwctl without colors
    iwctl "$@" | sed 's/\x1b\[[0-9;]*m//g'
}

# Property value from an iwctl "show" table, e.g. prop "Powered" device wlan0 show
prop() {
    local key=$1; shift
    iwc "$@" | awk -v k="$key" '{ sub(/^[ *]+/, "") } index($0, k" ") == 1 { sub(k" +", ""); sub(/ +$/, ""); print; exit }'
}

IFACE=$(iwc station list | awk 'f && NF { print $1; exit } /^-+$/ { n++; f = (n == 2) }')

# Prints: <connected:*|-> TAB <security> TAB <signal %> TAB <ssid>, strongest first
networks() {
    iwc station "$IFACE" get-networks rssi-dbms | awk '
        /Network name/ { n = index($0, "Network name"); s = index($0, "Security"); g = index($0, "Signal"); next }
        /^-+$/ { if (n) body = 1; next }
        body && NF {
            name = substr($0, n, s - n); sec = substr($0, s, g - s); dbm = substr($0, g) / 100
            gsub(/^ +| +$/, "", name); gsub(/ /, "", sec)
            pct = 2 * (dbm + 100); pct = pct > 100 ? 100 : pct < 0 ? 0 : pct
            printf "%s\t%s\t%d\t%s\n", (substr($0, 1, n - 1) ~ />/ ? "*" : "-"), sec, pct, name
        }' | sort -t$'\t' -k3,3nr
}

is_known() {
    iwctl known-networks "$1" show >/dev/null 2>&1
}

scan() {
    iwctl station "$IFACE" scan >/dev/null 2>&1
    sleep 0.3
    for _ in {1..50}; do # wait up to ~10s for iwd to finish
        [[ $(prop Scanning station "$IFACE" show) == yes ]] || return
        sleep 0.2
    done
}

connect() { # connect <ssid> <security> [hidden]
    local ssid=$1 security=$2 hidden=$3 pass out cmd=connect

    if [[ -n $hidden ]]; then
        cmd=connect-hidden
        pass=$(ask "Password (leave empty if open)" password) || return
    elif [[ $security == 8021x ]] && ! is_known "$ssid"; then
        error "$ssid uses 802.1X (enterprise). Add a provisioning file in /var/lib/iwd first."
        return
    elif [[ $security != open ]] && ! is_known "$ssid"; then
        pass=$(ask "Password for $ssid" password) || return
    fi

    out=$(iwctl --dont-ask ${pass:+--passphrase "$pass"} station "$IFACE" "$cmd" "$ssid" 2>&1) ||
        error "Failed to connect to $ssid: $(sed 's/\x1b\[[0-9;]*m//g' <<<"${out:-unknown error}")"
}

network_actions() { # network_actions <ssid> <security> <connected>
    local ssid=$1 security=$2 connected=$3 actions=() choice

    if [[ $connected == "*" ]]; then
        actions+=("󰖪  Disconnect")
    else
        actions+=("󰖩  Connect")
    fi
    is_known "$ssid" && actions+=("󰆴  Forget")

    # Unknown, not connected network: just connect
    [[ ${#actions[@]} -eq 1 && $connected != "*" ]] && { connect "$ssid" "$security"; return; }

    choice=$(printf '%s\n' "${actions[@]}" | menu "$ssid") || return
    case ${actions[$choice]} in
        *Disconnect) iwctl station "$IFACE" disconnect ;;
        *Connect)    connect "$ssid" "$security" ;;
        *Forget)     iwctl known-networks "$ssid" forget ;;
    esac
}

signal_icon() {
    if   (($1 >= 75)); then echo "󰤨"
    elif (($1 >= 50)); then echo "󰤥"
    elif (($1 >= 25)); then echo "󰤢"
    else                    echo "󰤟"
    fi
}

main() {
    local -a entries=() ssids=() securities=() connected=()
    local current choice

    if [[ -z $IFACE ]]; then
        error "No Wi-Fi station found (is iwd running?)"
        exit 1
    fi
    if [[ $(prop Powered device "$IFACE" show) != on ]]; then
        error "Wi-Fi is off (iwctl device $IFACE set-property Powered on)"
        exit 1
    fi

    while IFS=$'\t' read -r use security signal ssid; do
        [[ -z $ssid ]] && continue
        [[ $use == "*" ]] && current=$ssid

        local lock=" " mark=""
        [[ $security != open ]] && lock="󰌾"
        [[ $use == "*" ]] && mark="  (connected)"
        ssids+=("$ssid"); securities+=("$security"); connected+=("$use")
        entries+=("$(signal_icon "$signal")  $lock  $ssid$mark")
    done < <(networks)

    local -a header=("󰑐  Scan")
    [[ -n $current ]] && header+=("󰖪  Disconnect")
    header+=("󰈈  Hidden network")

    local status=${current:+Connected to $current}
    choice=$(printf '%s\n' "${header[@]}" "${entries[@]}" |
        menu "Search networks…" "${status:-Not connected}") || exit 0

    if ((choice < ${#header[@]})); then
        case ${header[$choice]} in
            *Scan)       scan; main; return ;;
            *Disconnect) iwctl station "$IFACE" disconnect ;;
            *Hidden*)
                local ssid
                ssid=$(ask "Hidden network SSID") || exit 0
                [[ -n $ssid ]] && connect "$ssid" "" hidden
                ;;
        esac
        return
    fi

    local i=$((choice - ${#header[@]}))
    network_actions "${ssids[$i]}" "${securities[$i]}" "${connected[$i]}"
}

main
