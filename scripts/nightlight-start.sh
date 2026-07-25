#!/usr/bin/env bash
# Night Light startup script — launched by Hyprland exec-once
# Reads ~/.config/hypr/nightlight.conf for saved settings, falls back to 3500K

CONF="$HOME/.config/hypr/nightlight.conf"

TEMP=3500
GAMMA=100
ENABLED=true

if [ -f "$CONF" ]; then
    t=$(grep -oP 'temperature=\K\d+' "$CONF" 2>/dev/null)
    g=$(grep -oP 'gamma=\K\d+'       "$CONF" 2>/dev/null)
    e=$(grep -oP 'enabled=\K\w+'     "$CONF" 2>/dev/null)
    [ -n "$t" ] && TEMP=$t
    [ -n "$g" ] && GAMMA=$g
    [ "$e" = "false" ] && ENABLED=false
fi

pkill -x hyprsunset 2>/dev/null || true

if [ "$ENABLED" = "true" ]; then
    exec hyprsunset -t "$TEMP" -g "$GAMMA"
fi
