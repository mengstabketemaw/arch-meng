#!/usr/bin/env bash
CACHE_FOLDER="$HOME/.cache/hyprland-dotfiles"

# Colors for UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- UI Functions (Redirected to stderr) ---
info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

if [ -d $CACHE_FOLDER ]; then
    rm  -rf $CACHE_FOLDER
    mkdir -p $CACHE_FOLDER
    info "Restore Default Wallpaper"
    $HOME/.config/hypr/scripts/wallpaper.sh $HOME/.config/hypr/assets/blank.png
fi