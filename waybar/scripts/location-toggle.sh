#!/bin/bash
# Toggle location on/off for Waybar weather

STATE_DIR="$HOME/.cache/waybar"
STATE_FILE="$STATE_DIR/location_enabled"
LOCATION_FILE="$STATE_DIR/location"

mkdir -p "$STATE_DIR"
[[ ! -f "$STATE_FILE" ]] && echo "off" > "$STATE_FILE"

case "$1" in
    toggle)
        current=$(cat "$STATE_FILE")
        if [[ "$current" == "on" ]]; then
            echo "off" > "$STATE_FILE"
        else
            echo "on" > "$STATE_FILE"
            ~/.config/waybar/scripts/location-sync.sh &
        fi
        pkill -RTMIN+10 waybar
        ;;
    *)
        current=$(cat "$STATE_FILE")
        icon_on=$'\uf450'
        icon_off=$'\uf451'
        if [[ "$current" == "on" ]]; then
            city=$(cat "$LOCATION_FILE" 2>/dev/null || echo "Syncing...")
            printf '{"text": "%s", "tooltip": "Location: ON — %s\\nClick to disable", "class": "on"}\n' "$icon_on" "$city"
        else
            printf '{"text": "%s", "tooltip": "Location: OFF\\nClick to enable", "class": "off"}\n' "$icon_off"
        fi
        ;;
esac
