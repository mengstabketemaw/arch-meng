#!/usr/bin/env bash

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.config"

echo ":: Symlinking dotfiles..."
ln -sf "$DOTFILES/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES/.gtkrc-2.0" "$HOME/.gtkrc-2.0"
ln -sf "$DOTFILES/.Xresources" "$HOME/.Xresources"
for dir in "$DOTFILES/.config"/*/; do
    target="$HOME/.config/$(basename "$dir")"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "  $target exists and is not a symlink — moving to $target.bak"
        mv "$target" "$target.bak"
    fi
    ln -sfn "$dir" "$target"
done

echo ":: Creating cache directory..."
mkdir -p "$HOME/.cache/hyprland-dotfiles"

echo ":: Generating initial colors from wallpaper..."
if [ -f "$DOTFILES/wallpapers/blank.png" ]; then
    matugen image "$DOTFILES/wallpapers/blank.png" 2>/dev/null || true
fi

echo ":: Setting up wallpaper..."
if command -v awww &>/dev/null; then
    awww init 2>/dev/null || true
    if [ -f "$DOTFILES/wallpapers/blank.png" ]; then
        awww img "$DOTFILES/wallpapers/blank.png" 2>/dev/null || true
    fi
fi

echo ""
echo "Done. Log out and log back in, or run: hyprctl reload"
