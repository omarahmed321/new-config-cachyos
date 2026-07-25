#!/usr/bin/env bash
# lockscreen.sh - Helper script to dynamically identify the active/focused monitor 
# and lock the system showing the widgets only on that monitor.

mkdir -p "$HOME/.cache/hypr"

# Get active/focused monitor name
focused_mon=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' 2>/dev/null)

# Fallback to first monitor in list if not found
if [ -z "$focused_mon" ]; then
    focused_mon=$(hyprctl monitors -j | jq -r '.[0].name' 2>/dev/null)
fi

# Fallback to default if everything else fails
if [ -z "$focused_mon" ]; then
    focused_mon="DP-2"
fi

# Write monitor variable to be sourced by hyprlock.conf
echo "\$main_monitor = $focused_mon" > "$HOME/.cache/hypr/lock_monitor.conf"

# Launch hyprlock
hyprlock
