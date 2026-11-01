#!/usr/bin/env bash
# __     ______  _   _
# \ \   / /  _ \| \ | |
#  \ \ / /| |_) |  \| |
#   \ V / |  __/| |\  |
#    \_/  |_|   |_| \_|
#

# -----------------------------------------------------
# One-key Pritunl toggle: PIN + generated TOTP, no prompts
# Secrets live in ~/.config/pritunl/vpn-auth (chmod 600, not in git):
#   PIN=1234
#   TOTP_SECRET=BASE32SECRET
#   PROFILE_ID=          # optional, defaults to first profile
# -----------------------------------------------------

AUTH=~/.config/pritunl/vpn-auth

notify() {
    notify-send -a "VPN" -i network-vpn "VPN" "$1"
}

if [[ ! -r $AUTH ]]; then
    notify "Missing $AUTH (see vpn-toggle.sh header)"
    exit 1
fi
source "$AUTH"

# Prints "<id> <connected:0|1>" for the chosen profile
status=$(pritunl-client list -j | python3 -c '
import json, sys
want = sys.argv[1]
profiles = json.load(sys.stdin) or []
for p in profiles:
    if want and p.get("id") != want:
        continue
    on = any(str(p.get(k, "")).lower() in ("true", "active", "connected", "connecting")
             for k in ("state", "run_state"))
    print(p["id"], int(on))
    break
' "$PROFILE_ID")

if [[ -z $status ]]; then
    notify "No Pritunl profile found — import it with: pritunl-client add <uri>"
    exit 1
fi
read -r id connected <<<"$status"

if ((connected)); then
    pritunl-client stop "$id" && notify "Disconnected"
    exit
fi

otp=$(python3 -c '
import base64, hmac, struct, sys, time
key = base64.b32decode(sys.argv[1].replace(" ", "").upper() + "=" * (-len(sys.argv[1].replace(" ", "")) % 8))
h = hmac.digest(key, struct.pack(">Q", int(time.time()) // 30), "sha1")
o = h[-1] & 15
print("%06d" % ((struct.unpack(">I", h[o:o + 4])[0] & 0x7fffffff) % 1000000))
' "$TOTP_SECRET")

if pritunl-client start "$id" --password "${PIN}${otp}"; then
    notify "Connecting…"
    # Keep arifpay.* on normal DNS instead of the tunnel
    setsid -f ~/.config/hypr/scripts/vpn-dns-split.sh >/dev/null 2>&1
    # Tray icon only, no window
    pgrep -f pritunl_client_electron >/dev/null ||
        setsid -f pritunl-client-electron --no-main >/dev/null 2>&1

else
    notify "Failed to start profile $id"
fi
