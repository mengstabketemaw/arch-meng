#!/usr/bin/env bash
# Make nvim (in kitty) the default app for text-like files instead of LibreOffice.
DESKTOP=nvim-kitty.desktop
mimes=$(grep '^MimeType=' "$HOME/.local/share/applications/$DESKTOP" | cut -d= -f2 | tr ';' ' ')
xdg-mime default "$DESKTOP" $mimes
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
