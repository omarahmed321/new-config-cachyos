#!/usr/bin/env bash
#===============================================================================
#   Night Light Startup script
#   Loads settings from ~/.config/hypr/nightlight.conf and starts hyprsunset
#===============================================================================

CONFIG_FILE="$HOME/.config/hypr/nightlight.conf"
TEMP=3500
GAMMA=100
ENABLED="true"

if [ -f "$CONFIG_FILE" ]; then
    # Parse flat key=value format safely
    while IFS='=' read -r key value; do
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        if [ "$key" = "temperature" ]; then
            TEMP="$value"
        elif [ "$key" = "gamma" ]; then
            GAMMA="$value"
        elif [ "$key" = "enabled" ]; then
            ENABLED="$value"
        fi
    done < "$CONFIG_FILE"
fi

# Kill any running hyprsunset instances
pkill -x hyprsunset 2>/dev/null || true

if [ "$ENABLED" = "true" ]; then
    # Convert gamma integer percentage (e.g. 70) to float (0.7)
    # Using bc or awk for float division, with a fallback if not available
    if command -v bc &>/dev/null; then
        GAMMA_FLOAT=$(echo "scale=2; $GAMMA / 100" | bc)
    else
        # Fallback basic arithmetic
        GAMMA_FLOAT="1.0"
        if [ "$GAMMA" -lt 100 ]; then
            if [ "$GAMMA" -lt 10 ]; then
                GAMMA_FLOAT="0.0$GAMMA"
            else
                GAMMA_FLOAT="0.$GAMMA"
            fi
        fi
    fi
    # Execute hyprsunset in the background
    hyprsunset -t "$TEMP" -g "$GAMMA_FLOAT" &>/dev/null &
fi
