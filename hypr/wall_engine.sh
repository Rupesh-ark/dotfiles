#!/bin/bash

# 1. Configuration
LOG_FILE="$HOME/.cache/wallpaper_engine.log"
BASE_DIR="$HOME/Pictures/wallpapers"
mkdir -p "$BASE_DIR"
touch "$LOG_FILE"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Detect wallpaper tool: prefers awww (custom), falls back to standard swww
WALL_CMD=""
if command -v awww >/dev/null 2>&1; then
    WALL_CMD="awww"
elif command -v swww >/dev/null 2>&1; then
    WALL_CMD="swww"
else
    notify-send "Wallpaper Engine" "No wallpaper tool found (install swww)" -u critical
    exit 1
fi

# 2. Gruvbox Light Rofi Prompt
BG="#fbf1c7"
FG="#3c3836"
ACCENT="#af3a03"
SELECT="#ebdbb2"

THEME=$(echo "" | rofi -dmenu -i -p "󰸉 Theme" \
    -mesg "Searching Wallhaven for $WALL_CMD setup..." \
    -theme-str "window { background-color: $BG; border: 2px; border-color: $ACCENT; border-radius: 12px; width: 500px; font: 'JetBrainsMono Nerd Font 12'; } \
                mainbox { children: [inputbar, message]; background-color: $BG; } \
                inputbar { background-color: $SELECT; children: [prompt, entry]; padding: 12px; } \
                prompt { text-color: $ACCENT; font: 'JetBrainsMono Nerd Font Bold 12'; } \
                entry { text-color: $FG; } \
                message { padding: 12px; background-color: $BG; } \
                textbox { text-color: $FG; }")

[[ -z "$THEME" ]] && { log_msg "User cancelled prompt."; exit 1 }

log_msg "New theme requested: $THEME"
notify-send "Wallpaper Engine" "Fetching $THEME wallpapers..."
QUERY=$(echo "$THEME" | sed 's/ /+/g')

# 3. Download Function
download_wall() {
    local res=$1
    local folder=$2
    local api_url="https://wallhaven.cc/api/v1/search?q=$QUERY&resolutions=$res&sorting=random&purity=100"
    
    local response=$(curl -s "$api_url")
    local img_url=$(echo "$response" | jq -r '.data[0].path')

    if [ "$img_url" != "null" ] && [ -n "$img_url" ]; then
        rm -f "$folder"/*
        local filename=$(basename "$img_url")
        local full_path="$folder/$filename"
        wget -qO "$full_path" "$img_url"
        echo "$full_path"
    else
        return 1
    fi
}

# 4. Fetching (try high-res first, fallback to standard)
IMG=$(download_wall "2560x1440" "$BASE_DIR/high_res")
[[ -z "$IMG" ]] && IMG=$(download_wall "1920x1080" "$BASE_DIR/std_res")

# 5. Applying via detected wallpaper tool
if [[ -n "$IMG" ]]; then
    IMG=$(echo "$IMG" | tr -d '\n' | tr -d '\r')

    # Apply to all connected monitors (generic)
    mapfile -t monitors < <(hyprctl monitors -j | jq -r '.[].name')
    for mon in "${monitors[@]}"; do
        log_msg "Applying to $mon: $IMG"
        $WALL_CMD img -o "$mon" "$IMG" --transition-type outer --transition-fps 60 >> "$LOG_FILE" 2>&1
    done

    notify-send "Wallpaper Engine" "Theme updated to: $THEME"
else
    log_msg "Error: Search returned no results."
    notify-send "Wallpaper Engine" "No images found." -u critical
fi

log_msg "Process complete."
echo "-------------------------------------------" >> "$LOG_FILE"
