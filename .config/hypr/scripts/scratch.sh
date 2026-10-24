#!/usr/bin/env bash
#  ____                 _       _
# / ___|  ___ _ __ __ _| |_ ___| |__
# \___ \ / __| '__/ _` | __/ __| '_ \
#  ___) | (__| | | (_| | || (__| | | |
# |____/ \___|_|  \__,_|\__\___|_| |_|
#

# -----------------------------------------------------
# Scratch notes (rofi + nvim): search, open, create, delete
#   Enter       open selected / create from typed name if nothing matches
#   Ctrl+Enter  create from typed name even if something matches
#   Alt+d       delete selected
# -----------------------------------------------------

DIR=${SCRATCH_DIR:-$HOME/scratch}
THEME=~/.config/rofi/config-scratch.rasi
EDITOR_CMD=${SCRATCH_EDITOR:-nvim}

mkdir -p "$DIR"

menu() { # menu <placeholder> [mesg] — reads entries on stdin, prints "<index> <text>"
    rofi -dmenu -i -replace -format 'i s' -config "$THEME" \
        -kb-custom-1 "Alt+d" \
        -theme-str "entry { placeholder: \"$1\"; }" ${2:+-mesg "$2"}
}

confirm() { # confirm <question> — succeeds on "Yes"
    [[ $(printf '󰆴  Yes\n󰜺  No\n' | rofi -dmenu -i -replace -config "$THEME" \
        -theme-str "entry { placeholder: \"$1\"; }") == *Yes ]]
}

ago() { # ago <epoch seconds> — short relative time
    local s=$(( $(date +%s) - $1 ))
    if   ((s < 60));    then echo "just now"
    elif ((s < 3600));  then echo "$((s / 60))m ago"
    elif ((s < 86400)); then echo "$((s / 3600))h ago"
    else                     echo "$((s / 86400))d ago"
    fi
}

open() { # open <file>
    exec kitty --class scratch --title "scratch: $(basename "$1")" \
        --directory "$DIR" "$EDITOR_CMD" "$1"
}

# Turns a typed name into a file path; adds .md unless an extension was given
path_for() {
    local name=${1//\//-}
    name=${name#"${name%%[![:space:]]*}"}; name=${name%"${name##*[![:space:]]}"}
    [[ -z $name ]] && return 1
    [[ $name != *.* ]] && name+=.md
    echo "$DIR/$name"
}

main() {
    local -a files=() entries=()
    local mtime file out code index text

    # Most recently edited first
    while IFS=$'\t' read -r mtime file; do
        files+=("$file")
        entries+=("$(printf '%-40s  %s' "${file#"$DIR"/}" "$(ago "${mtime%.*}")")")
    done < <(find "$DIR" -maxdepth 1 -type f ! -name '.*' -printf '%T@\t%p\n' | sort -rn)

    out=$( ((${#entries[@]})) && printf '%s\n' "${entries[@]}" |
        menu "Search or create scratch…" "Enter open/create · Ctrl+Enter new · Alt+d delete")
    code=$?
    ((${#entries[@]})) || out=$(menu "Name a new scratch…" "No scratches yet in $DIR" </dev/null)
    [[ -z $out ]] && exit 0

    index=${out%% *}; text=${out#* }

    if ((code == 10)); then
        ((index >= 0)) || exit 0
        confirm "Delete ${files[$index]##*/}?" && rm -f -- "${files[$index]}"
        main; return
    fi

    # Existing entry picked
    if ((index >= 0 && index < ${#files[@]})) && [[ $text == "${entries[$index]}" ]]; then
        open "${files[$index]}"
    fi

    # Custom input: open if it names an existing file, otherwise create it
    file=$(path_for "$text") || exit 0
    [[ -e $file ]] || touch "$file"
    open "$file"
}

main
