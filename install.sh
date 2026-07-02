#!/usr/bin/env bash
set -e

DOTFILES="$HOME/arch-setup"

echo ":: Installing packages..."
# sudo pacman -S --needed --noconfirm \
#     hyprland hyprlock hypridle hyprpaper \
#     quickshell waybar rofi kitty swaync \
#     cliphist playerctl awww matugen \
#     brightnessctl grim slurp swappy \
#     tesseract tesseract-data-eng \
#     btop blueman networkmanager \
#     pinta polkit-gnome \
#     qt6-base qt6-declarative qt6-svg qt6-wayland \
#     fcitx5 fcitx5-mozc \
#     xdg-desktop-portal-hyprland
#
if ! command -v grimblast &>/dev/null; then
    if command -v yay &>/dev/null; then
        yay -S --noconfirm grimblast-git
    else
        echo "WARNING: grimblast not found. Install grimblast-git from AUR manually."
    fi
fi

mkdir -p "$HOME/.config"

echo ":: Symlinking dotfiles..."
ln -sf "$DOTFILES/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES/.gtkrc-2.0" "$HOME/.gtkrc-2.0"
ln -sf "$DOTFILES/.Xresources" "$HOME/.Xresources"
for dir in "$DOTFILES/.config"/*/; do
    target="$HOME/.config/$(basename "$dir")"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "  WARNING: $target exists and is not a symlink — skipping"
    else
        ln -sfn "$dir" "$target"
    fi
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
