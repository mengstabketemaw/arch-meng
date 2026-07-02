#!/usr/bin/env bash
WALLPAPER_APP="quickshell"
WALLPAPER_FOLDER="$HOME/arch-setup/wallpapers"

# Colors for UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure that cache folder exists
mkdir -p $HOME/.cache

# --- UI Functions (Redirected to stderr) ---
info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Check parameters
if [ "$1" == "--restore" ]; then
    if [ "$WALLPAPER_APP" == "quickshell" ]; then
        info "Using awww with Quickshell Wallpaper Selector."
    elif [ "$WALLPAPER_APP" == "waypaper" ]; then
        waypaper --restore
    else
        error "Wallpaper App $WALLPAPER_APP not supported."
    fi    
    exit
elif [ "$1" == "--random" ]; then
    if [ "$WALLPAPER_APP" == "quickshell" ]; then
        $HOME/.config/hypr/scripts/wallpaper.sh --random
    elif [ "$WALLPAPER_APP" == "waypaper" ]; then
        waypaper --random --folder $WALLPAPER_FOLDER
    else
        error "Wallpaper App $WALLPAPER_APP not supported."
    fi    
    exit
fi

# Launch wallpaper app
if [ "$WALLPAPER_APP" == "quickshell" ]; then
    info "Toggle Quickshell Wallpaper App"
    qs ipc call wallpaper toggle
elif [ "$WALLPAPER_APP" == "waypaper" ]; then
    info "Launch Waypaper"
    waypaper --folder $WALLPAPER_FOLDER
else
    error "Wallpaper App $WALLPAPER_APP not supported."
fi