#!/usr/bin/env bash
killall waybar 2>/dev/null || true
sleep 0.2
waybar
