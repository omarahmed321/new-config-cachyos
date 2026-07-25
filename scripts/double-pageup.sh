#!/bin/bash
LAST_FILE="/tmp/.pageup_last"
NOW=$(date +%s%N)

if [ -f "$LAST_FILE" ]; then
    LAST=$(cat "$LAST_FILE")
    DIFF=$(( (NOW - LAST) / 1000000 ))
    if [ "$DIFF" -lt 500 ]; then
        rm -f "$LAST_FILE"
        wtype -M ctrl -k grave
        exit 0
    fi
fi

echo "$NOW" > "$LAST_FILE"
sleep 0.6
[ -f "$LAST_FILE" ] && rm -f "$LAST_FILE"
