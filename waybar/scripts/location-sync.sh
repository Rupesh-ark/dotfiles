#!/bin/bash
# Detect location via geoclue and cache the city name

STATE_DIR="$HOME/.cache/waybar"
STATE_FILE="$STATE_DIR/location_enabled"
LOCATION_FILE="$STATE_DIR/location"

mkdir -p "$STATE_DIR"

# Only sync if enabled
[[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" != "on" ]] && exit 0

city=""

# Find geoclue demo binaries (paths vary by distro)
AGENT_PATH=""
for p in /usr/lib/geoclue-2.0/demos/agent /usr/libexec/geoclue-2.0/demos/agent /usr/lib64/geoclue-2.0/demos/agent; do
    [[ -x "$p" ]] && { AGENT_PATH="$p"; break; }
done

WHEREAMI_PATH=""
for p in /usr/lib/geoclue-2.0/demos/where-am-i /usr/libexec/geoclue-2.0/demos/where-am-i /usr/lib64/geoclue-2.0/demos/where-am-i; do
    [[ -x "$p" ]] && { WHEREAMI_PATH="$p"; break; }
done

# Start geoclue agent if not running
if [[ -n "$AGENT_PATH" ]]; then
    pgrep -f "geoclue-2.0/demos/agent" >/dev/null || "$AGENT_PATH" &>/dev/null &
fi

# Get coordinates from geoclue
if [[ -n "$WHEREAMI_PATH" ]]; then
    geo_output=$(timeout 15 "$WHEREAMI_PATH" -t 10 2>/dev/null)
    lat=$(echo "$geo_output" | grep 'Latitude:' | tail -1 | awk '{print $2}' | tr -d '°')
    lon=$(echo "$geo_output" | grep 'Longitude:' | tail -1 | awk '{print $2}' | tr -d '°')
fi

if [[ -n "$lat" && -n "$lon" ]]; then
    # Reverse geocode via nominatim
    city=$(curl -sf --max-time 5 \
        "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json" \
        -H "User-Agent: waybar-weather" | jq -r '.address.city // .address.town // .address.village // empty')
fi

# Save result
if [[ -n "$city" ]]; then
    echo "$city" > "$LOCATION_FILE"
    rm -f "$STATE_DIR/weather.json"
    pkill -RTMIN+10 waybar
fi
