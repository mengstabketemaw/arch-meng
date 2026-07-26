#!/usr/bin/env bash

set -euo pipefail

# -------------------------------------------------
# Hyprland core
# -------------------------------------------------
HYPRLAND_PKGS=(
    hyprland
    hyprlock
    hypridle
    hyprpaper
    hyprpicker
    hyprsunset
    hyprcursor
    hyprgraphics
    hyprlang
    hyprutils
    hyprwayland-scanner
    hyprwire
    xdg-desktop-portal-hyprland
)

# -------------------------------------------------
# Core system / Wayland
# -------------------------------------------------
CORE_PKGS=(
    wayland
    wayland-protocols
    xorg-xwayland
    xdg-utils
    polkit-gnome
    iwd
    blueman
    bluez
    bluez-utils
    seatd
    uwsm
    sddm
)

# -------------------------------------------------
# Audio (pipewire stack)
# -------------------------------------------------
AUDIO_PKGS=(
    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber
    pavucontrol
    sof-firmware
    rtkit
)

# -------------------------------------------------
# Display / UI
# -------------------------------------------------
DISPLAY_PKGS=(
    quickshell
    waybar
    rofi
    swaync
    kitty
    kitty-shell-integration
    kitty-terminfo
    xsettingsd
)

# -------------------------------------------------
# Input
# -------------------------------------------------
INPUT_PKGS=(
    fcitx5
    fcitx5-m17n
)

# -------------------------------------------------
# Tools / CLI
# -------------------------------------------------
TOOLS_PKGS=(
    fzf
    ripgrep
    btop
    htop
    fastfetch
    lazygit
    neovim
    vim
    nano
    zsh
    zoxide
    eza
    nvm
    wget
    curl
    git
    tree-sitter
    nodejs
    npm
    lua-language-server
    stylua
)

# -------------------------------------------------
# Screenshot / Clipboard / Media
# -------------------------------------------------
MEDIA_PKGS=(
    hyprshot
    cliphist
    playerctl
    brightnessctl
    imagemagick
    tesseract
    tesseract-data-eng
)

# -------------------------------------------------
# File manager / Browser / Apps
# -------------------------------------------------
APPS_PKGS=(
    nautilus
    chromium
    flatpak
)

# -------------------------------------------------
# Qt / GTK / Theming
# -------------------------------------------------
THEME_PKGS=(
    qt6-base
    qt6-declarative
    qt6-svg
    qt6-wayland
    qt6-5compat
    qt6ct
    matugen
    adwaita-icon-theme
    adwaita-cursors
    adwaita-fonts
    hicolor-icon-theme
    shared-mime-info
)

# -------------------------------------------------
# Fonts
# -------------------------------------------------
FONT_PKGS=(
    ttf-liberation
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk
    noto-fonts-extra
    ttf-fira-code
    ttf-fira-sans
    ttf-nerd-fonts-symbols
    ttf-material-icons
    otf-font-awesome
)

# -------------------------------------------------
# AUR packages (requires yay or paru)
# -------------------------------------------------
AUR_PKGS=(
    wlogout
    waypaper
    oh-my-posh
    spotify-launcher
    telegram-desktop
)

# -------------------------------------------------
# Install function
# -------------------------------------------------
install_repo_pkgs() {
    local pkgs=("$@")
    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

install_aur_pkgs() {
    local pkgs=("$@")

    if ! command -v yay &>/dev/null; then
        echo "  Installing yay (AUR helper)..."
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
    fi

    yay -S --needed --noconfirm "${pkgs[@]}"
}

# -------------------------------------------------
# Main
# -------------------------------------------------
echo ":: Installing Hyprland core..."
install_repo_pkgs "${HYPRLAND_PKGS[@]}"

echo ":: Installing core system..."
install_repo_pkgs "${CORE_PKGS[@]}"

echo ":: Installing audio (pipewire)..."
install_repo_pkgs "${AUDIO_PKGS[@]}"

echo ":: Installing display / UI..."
install_repo_pkgs "${DISPLAY_PKGS[@]}"

echo ":: Installing input method..."
install_repo_pkgs "${INPUT_PKGS[@]}"

echo ":: Installing tools / CLI..."
install_repo_pkgs "${TOOLS_PKGS[@]}"

echo ":: Installing screenshot / clipboard / media..."
install_repo_pkgs "${MEDIA_PKGS[@]}"

echo ":: Installing apps..."
install_repo_pkgs "${APPS_PKGS[@]}"

echo ":: Installing Qt / GTK / theming..."
install_repo_pkgs "${THEME_PKGS[@]}"

echo ":: Installing fonts..."
install_repo_pkgs "${FONT_PKGS[@]}"

echo ":: Installing AUR packages..."
install_aur_pkgs "${AUR_PKGS[@]}"

echo ""
echo "Done. Run ./configure.sh to set up symlinks and configuration."
