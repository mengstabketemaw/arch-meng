#!/usr/bin/env bash
#  ____  _
# |  _ \| | ____ _
# | |_) | |/ / _` |
# |  __/|   < (_| |
# |_|   |_|\_\__, |
#            |___/
#
# -----------------------------------------------------
# Package installer / uninstaller (kitty + fzf)
#   pkg-manager.sh install     search repos (and AUR with Ctrl+A), install
#   pkg-manager.sh uninstall   search installed apps, remove with unused deps
#
#   Tab        select multiple
#   Enter      install / remove selection
#   Ctrl+A     (install) toggle AUR results — off by default
#   Esc        quit
# -----------------------------------------------------

SELF=$(realpath "$0")
CLASS=pkg-manager
STATE=${XDG_RUNTIME_DIR:-/tmp}/pkg-manager-aur
AUR_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/pkg-manager/aur-packages

# Never remove these without a very loud warning
PROTECTED=(base linux linux-lts linux-zen linux-firmware glibc systemd pacman sudo
    hyprland kitty bash zsh networkmanager mesa grub efibootmgr)

aur_helper() {
    local h
    for h in yay paru; do command -v "$h" &>/dev/null && { echo "$h"; return; }; done
    return 1
}

# Relaunch inside a floating kitty window when started from rofi / a keybind
if [[ $1 == install || $1 == uninstall ]] && [[ -z $PKG_MANAGER_IN_TERM ]]; then
    PKG_MANAGER_IN_TERM=1 exec kitty --class "$CLASS" --title "Package ${1^}" "$SELF" "$@"
fi

# ---------- list producers (called by fzf reload) ----------

# <installed-mark> \t <name> \t <repo> \t <description>
list_repo() {
    pacman -Ss | awk '
        NR % 2 == 1 { split($1, a, "/"); repo = a[1]; name = a[2]
                      mark = ($0 ~ /\[installed/) ? "●" : " "; next }
        { sub(/^ +/, ""); printf "%s\t%-32s\t%-9s\t%s\n", mark, name, repo, $0 }'
}

list_aur() {
    mkdir -p "${AUR_CACHE%/*}"
    # Refresh the AUR name list at most once a day (helper first, direct download as fallback)
    if [[ ! -s $AUR_CACHE ]] || [[ -n $(find "$AUR_CACHE" -mmin +1440) ]]; then
        local tmp=$AUR_CACHE.tmp h ok=
        for h in yay paru; do
            command -v "$h" &>/dev/null && "$h" -Slq aur 2>/dev/null > "$tmp" && [[ -s $tmp ]] && { ok=1; break; }
        done
        [[ -z $ok ]] && curl -fsSL https://aur.archlinux.org/packages.gz 2>/dev/null | gunzip > "$tmp" && [[ -s $tmp ]] && ok=1
        if [[ -n $ok ]]; then mv "$tmp" "$AUR_CACHE"; else rm -f "$tmp"; fi
    fi
    [[ -s $AUR_CACHE ]] || return
    awk -v foreign="$(pacman -Qmq)" '
        BEGIN { n = split(foreign, f, "\n"); for (i = 1; i <= n; i++) fo[f[i]] = 1 }
        { printf "%s\t%-32s\t%-9s\t%s\n", ($0 in fo) ? "●" : " ", $0, "aur", "(AUR — see preview)" }' "$AUR_CACHE"
}

list_install() {
    list_repo
    [[ -e $STATE ]] && list_aur
}

# <name> \t <version> \t <source> \t <description>  — explicitly installed only
list_installed() {
    pacman -Qs | awk -v explicit="$(pacman -Qeq)" -v foreign="$(pacman -Qmq)" '
        BEGIN { n = split(explicit, e, "\n"); for (i = 1; i <= n; i++) ex[e[i]] = 1
                n = split(foreign,  f, "\n"); for (i = 1; i <= n; i++) fo[f[i]] = 1 }
        NR % 2 == 1 { split($1, a, "/"); name = a[2]; ver = $2; next }
        name in ex  { sub(/^ +/, ""); printf "%-30s\t%-16s\t%-5s\t%s\n", name, substr(ver, 1, 16), (name in fo) ? "aur" : "repo", $0 }'
}

prompt() { [[ -e $STATE ]] && echo "install [repo+AUR] > " || echo "install [repo] > "; }

toggle_aur() { [[ -e $STATE ]] && rm -f "$STATE" || touch "$STATE"; }

# ---------- previews ----------

preview_install() { # <name> <repo>
    set -- "${1%% *}" "${2%% *}"
    if [[ $2 == aur ]]; then
        local helper; helper=$(aur_helper) && "$helper" -Si "$1" 2>/dev/null
    else
        pacman -Si "$2/$1" 2>/dev/null
    fi
}

preview_uninstall() { # <name>
    set -- "${1%% *}"
    printf '\e[1;31mWill remove (package + deps no other package needs):\e[0m\n'
    pacman -Rsp --print-format '  %n %v' "$1" 2>&1
    echo
    pacman -Qi "$1"
}

# ---------- helpers ----------

pause() { echo; read -rsn1 -p $'\e[2mPress any key to close…\e[0m'; echo; }

ask() { # ask <question> — default No
    local a; read -rp $'\e[1;33m'"$1"$' [y/N]\e[0m ' a; [[ $a == [yY]* ]]
}

FZF_COMMON=(--multi --delimiter=$'\t' --layout=reverse --border=rounded --info=inline-right
    --tabstop=1 --preview-window='right,50%,wrap,border-left' --bind='ctrl-/:toggle-preview'
    --color='marker:green,pointer:cyan')

# ---------- install ----------

do_install() {
    rm -f "$STATE" # AUR off by default on each launch
    local sel
    sel=$(list_install | fzf "${FZF_COMMON[@]}" \
        --with-nth='1,2,3,4' --nth='2,4' --tiebreak=begin,length \
        --prompt="$(prompt)" \
        --header=$'Tab select · Enter install · Ctrl+A toggle AUR · Ctrl+/ preview · ● installed' \
        --preview="'$SELF' preview-install {2} {3}" \
        --bind="ctrl-a:execute-silent('$SELF' toggle-aur)+reload('$SELF' list-install)+transform-prompt('$SELF' prompt)")
    rm -f "$STATE"
    [[ -z $sel ]] && exit 0

    local -a repo=() aur=()
    local mark name src desc
    while IFS=$'\t' read -r mark name src desc; do
        name=${name%% *}; src=${src%% *}
        [[ $src == aur ]] && aur+=("$name") || repo+=("$src/$name")
    done <<< "$sel"

    printf '\e[1m:: Installing:\e[0m %s\n\n' "${repo[*]#*/} ${aur[*]}"
    local rc=0
    if ((${#repo[@]})); then
        sudo pacman -S --needed "${repo[@]}" || rc=$?
    fi
    if ((${#aur[@]})); then
        local helper
        if helper=$(aur_helper); then
            "$helper" -S --needed "${aur[@]}" || rc=$?
        else
            echo "No AUR helper (yay/paru) found."; rc=1
        fi
    fi
    ((rc == 0)) && notify-send -a "Packages" "Installed" "${repo[*]#*/} ${aur[*]}" 2>/dev/null
    pause
}

# ---------- uninstall ----------

do_uninstall() {
    local sel
    sel=$(list_installed | fzf "${FZF_COMMON[@]}" \
        --with-nth='1,2,3,4' --nth='1,4' --tiebreak=begin,length \
        --prompt="uninstall > " \
        --header=$'Tab select · Enter remove (with unused deps) · Ctrl+/ preview' \
        --preview="'$SELF' preview-uninstall {1}")
    [[ -z $sel ]] && exit 0

    local -a pkgs=()
    local name rest p
    while IFS=$'\t' read -r name rest; do pkgs+=("${name%% *}"); done <<< "$sel"

    for p in "${pkgs[@]}"; do
        if [[ " ${PROTECTED[*]} " == *" $p "* ]]; then
            printf '\e[1;41m WARNING \e[0m \e[1m%s\e[0m is a core system package — removing it can break your system.\n' "$p"
            ask "Really remove $p?" || { echo "Aborted."; pause; exit 1; }
        fi
    done

    # -R remove, -n drop config backups in /etc, -s also remove deps nothing else needs
    if ! sudo pacman -Rns "${pkgs[@]}"; then
        echo; echo "Nothing removed (cancelled, or another package depends on it — see above)."
        pause; exit 1
    fi

    # Leftover orphans (deps whose last user was removed earlier, etc.)
    local -a orphans
    mapfile -t orphans < <(pacman -Qdtq 2>/dev/null)
    if ((${#orphans[@]})); then
        printf '\n\e[1m:: Orphaned packages still on the system:\e[0m %s\n' "${orphans[*]}"
        ask "Remove them too?" && sudo pacman -Rns "${orphans[@]}"
    fi

    # Per-user leftovers named after the package (symlinks — i.e. dotfiles — are never touched)
    local -a leftovers=()
    local d
    for p in "${pkgs[@]}"; do
        for d in "$HOME/.config" "$HOME/.local/share" "$HOME/.local/state" "$HOME/.cache"; do
            while IFS= read -r -d '' f; do leftovers+=("$f"); done < <(
                find "$d" -mindepth 1 -maxdepth 1 -iname "$p" ! -type l -print0 2>/dev/null)
        done
    done
    if ((${#leftovers[@]})); then
        printf '\n\e[1m:: User data/config left behind:\e[0m\n'
        printf '   %s\n' "${leftovers[@]}"
        ask "Delete these as well?" && rm -rf -- "${leftovers[@]}" && echo "Deleted."
    fi

    notify-send -a "Packages" "Removed" "${pkgs[*]}" 2>/dev/null
    pause
}

case $1 in
    install)           do_install ;;
    uninstall)         do_uninstall ;;
    list-install)      list_install ;;
    list-installed)    list_installed ;;
    toggle-aur)        toggle_aur ;;
    prompt)            prompt ;;
    preview-install)   preview_install "$2" "$3" ;;
    preview-uninstall) preview_uninstall "$2" ;;
    *) echo "usage: ${0##*/} install|uninstall" >&2; exit 1 ;;
esac
