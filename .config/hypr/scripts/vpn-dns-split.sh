#!/usr/bin/env bash
# -----------------------------------------------------
# Split DNS for the Pritunl tunnel
# The VPN pushes "arifpay.org arifpay.net ~." onto tun0, which sends those
# domains to the VPN resolver only. This strips them from tun0 and routes
# them to the normal uplink instead. Re-applies if the VPN reconnects and
# exits once tun0 has been gone for a minute.
# Needs scripts/50-resolved-domains.rules installed (polkit, no password).
# -----------------------------------------------------

DOMAINS=(arifpay.net arifpay.org)
TUN=tun0

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/vpn-dns-split.lock"
flock -n 9 || exit 0

uplink() {
    ip -o route show default | awk '$5 !~ /^tun/ {print $5; exit}'
}

# True if tun0 still claims a domain or the uplink lost its routing domains
needs_fix() {
    local d tun up
    tun=$(resolvectl domain "$TUN" 2>/dev/null)
    up=$(resolvectl domain "$(uplink)" 2>/dev/null)
    for d in "${DOMAINS[@]}"; do
        [[ $tun == *" $d"* || $up != *"~$d"* ]] && return 0
    done
    return 1
}

apply() {
    local uplink
    uplink=$(uplink)
    resolvectl domain "$TUN" '~.'
    [[ -n $uplink ]] && resolvectl domain "$uplink" "${DOMAINS[@]/#/\~}"
}

misses=0
while ((misses < 20)); do
    if ip link show "$TUN" &>/dev/null; then
        misses=0
        needs_fix && apply
    else
        ((misses++))
    fi
    sleep 3
done
