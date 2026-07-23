#!/bin/bash

pkg=$(pacman -Q | awk '{print $1 " (" $2 ")"}' | fzf --prompt="Remove package> " --reverse --height=40% | awk '{print $1}')

if [ -n "$pkg" ]; then
    echo "Uninstalling: $pkg"
    sudo pacman -Rs "$pkg"
fi
