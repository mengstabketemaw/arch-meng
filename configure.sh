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

echo ":: Setting up oh-my-zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null || true
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
    [ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ] && \
        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" 2>/dev/null || true
fi

echo ":: Creating cache directory..."
mkdir -p "$HOME/.cache/hyprland-dotfiles"

echo ":: Generating initial colors from wallpaper..."
if [ -f "$DOTFILES/wallpapers/blank.png" ]; then
    matugen image "$DOTFILES/wallpapers/blank.png" 2>/dev/null || true
fi

echo ":: Setting up wallpaper..."
if command -v hyprpaper &>/dev/null; then
    if [ -f "$DOTFILES/wallpapers/blank.png" ]; then
        hyprctl hyprpaper preload "$DOTFILES/wallpapers/blank.png" 2>/dev/null || true
        for monitor in $(hyprctl monitors 2>/dev/null | grep -oP 'Monitor \K\S+'); do
            hyprctl hyprpaper wallpaper "$monitor,$DOTFILES/wallpapers/blank.png" 2>/dev/null || true
        done
    fi
fi

echo ""
echo "Done. Log out and log back in, or run: hyprctl reload"
