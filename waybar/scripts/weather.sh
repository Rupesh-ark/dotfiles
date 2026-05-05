#!/bin/bash

# Waybar weather module using wttr.in
# Output: JSON for waybar custom module

# ── Configuration ──────────────────────────────────────
# Reads location from cache (set by location-sync.sh via geoclue)
# Falls back to empty string which lets wttr.in auto-detect via IP
STATE_DIR="$HOME/.cache/waybar"
LOCATION_FILE="$STATE_DIR/location"
STATE_FILE="$STATE_DIR/location_enabled"

LOCATION=""
if [[ -f "$STATE_FILE" && "$(cat "$STATE_FILE")" == "on" && -f "$LOCATION_FILE" ]]; then
    LOCATION=$(cat "$LOCATION_FILE")
fi
# ───────────────────────────────────────────────────────

CACHE_DIR="$HOME/.cache/waybar"
CACHE_FILE="$CACHE_DIR/weather.json"
CACHE_MAX_AGE=900 # 15 minutes

mkdir -p "$CACHE_DIR"

# Use cache if fresh enough
if [[ -f "$CACHE_FILE" ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
    if (( age < CACHE_MAX_AGE )); then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Fetch weather data (URL-encode spaces)
LOCATION_URL=$(echo "$LOCATION" | sed 's/ /+/g')
weather=$(curl -sf "wttr.in/${LOCATION_URL}?format=j1" 2>/dev/null)

if [[ -z "$weather" ]]; then
    echo '{"text": "N/A", "tooltip": "Weather unavailable", "class": "disconnected"}'
    exit 0
fi

# Parse with jq — handle both root-level and .data wrapper formats
root=$(echo "$weather" | jq -r 'if .data then .data else . end')
current=$(echo "$root" | jq -r '.current_condition[0]')
location=$(echo "$root" | jq -r '.nearest_area[0].areaName[0].value // empty')
if [[ -z "$location" ]]; then
    location="${LOCATION:-Unknown}"
fi
temp_c=$(echo "$current" | jq -r '.temp_C')
feels=$(echo "$current" | jq -r '.FeelsLikeC')
humidity=$(echo "$current" | jq -r '.humidity')
desc=$(echo "$current" | jq -r '.weatherDesc[0].value')
wind_kmph=$(echo "$current" | jq -r '.windspeedKmph')
wind_dir=$(echo "$current" | jq -r '.winddir16Point')

# Map weather description to nerd font icon
icon=""
desc_lower=$(echo "$desc" | tr '[:upper:]' '[:lower:]')
case "$desc_lower" in
    *"clear"*|*"sunny"*)       icon="" ;;
    *"partly cloudy"*)         icon="" ;;
    *"cloudy"*|*"overcast"*)   icon="" ;;
    *"mist"*|*"fog"*)          icon="" ;;
    *"rain"*|*"drizzle"*)      icon="" ;;
    *"thunder"*|*"storm"*)     icon="" ;;
    *"snow"*|*"blizzard"*)     icon="" ;;
    *"sleet"*|*"ice"*)         icon="" ;;
    *)                         icon="" ;;
esac

# Build tooltip with forecast
forecast=""
for i in 0 1 2; do
    day=$(echo "$root" | jq -r ".weather[$i].date")
    max=$(echo "$root" | jq -r ".weather[$i].maxtempC")
    min=$(echo "$root" | jq -r ".weather[$i].mintempC")
    day_desc=$(echo "$root" | jq -r ".weather[$i].hourly[4].weatherDesc[0].value")
    if [[ "$i" -eq 0 ]]; then
        label="Today"
    else
        label=$(date -d "$day" +%A 2>/dev/null || echo "$day")
    fi
    forecast="${forecast}
  ${label}:  ${min}° → ${max}°  ${day_desc}"
done

tooltip="$icon  $desc — $location

Feels like ${feels}°C
Humidity  ${humidity}%
Wind  ${wind_kmph} km/h $wind_dir

─── 3-Day Forecast ───$forecast"

text="$icon ${temp_c}°"

# Output compact single-line JSON (required by waybar)
output=$(jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$desc_lower" \
    '{text: $text, tooltip: $tooltip, class: $class}')

echo "$output" | tee "$CACHE_FILE"
