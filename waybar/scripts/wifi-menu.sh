#!/bin/bash

# Rofi-based WiFi picker for waybar
# Animated spinner while scanning, instant when cached

CACHE="$HOME/.cache/waybar/wifi-networks"

# Auto-detect wireless interface (falls back to wlo1 if detection fails)
IFACE=$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')
[[ -z "$IFACE" ]] && IFACE="wlo1"

# Gruvbox rofi theme
BG="#282828"
BG_ALT="#3c3836"
FG="#ebdbb2"
ACCENT="#fe8019"

THEME="window { background-color: $BG; border: 2px; border-color: $ACCENT; border-radius: 12px; width: 450px; font: \"JetBrainsMono Nerd Font 11\"; }
mainbox { background-color: $BG; children: [inputbar, message, listview]; }
inputbar { background-color: $BG_ALT; children: [prompt, entry]; padding: 12px; border-radius: 8px; margin: 8px; }
prompt { text-color: $ACCENT; font: \"JetBrainsMono Nerd Font Bold 11\"; margin: 0 8px 0 0; }
entry { text-color: $FG; placeholder-color: #a89984; placeholder: \"Search networks...\"; }
listview { background-color: $BG; padding: 0 8px 8px 8px; lines: 8; scrollbar: false; }
element { padding: 10px 12px; border-radius: 8px; background-color: $BG; text-color: $FG; }
element selected { background-color: $ACCENT; text-color: $BG; }
element-text { background-color: inherit; text-color: inherit; }
message { padding: 8px 16px; background-color: $BG; }
textbox { text-color: #a89984; font: \"JetBrainsMono Nerd Font 13\"; horizontal-align: 0.5; }"

mkdir -p "$(dirname "$CACHE")"

# Build network list from nmcli output
build_list() {
    local current="$1"
    nmcli -t -f SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null | sort -t: -k1 -rn | awk -F: -v cur="$current" '
    !seen[$3]++ && $3 != "" {
        sig = $1 + 0
        icon = (sig >= 75) ? "󰤨" : (sig >= 50) ? "󰤥" : (sig >= 25) ? "󰤟" : "󰤯"
        lock = ($2 != "" && $2 != "--") ? "  󰌾" : ""
        mark = ($3 == cur) ? "  ✓" : ""
        printf "%s   %s%s%s\n", icon, $3, lock, mark
    }'
}

# Get current SSID using nmcli (more portable than iwconfig)
CURRENT=$(nmcli -t -f ACTIVE,SSID dev wifi list 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')

# If cache is fresh, show instantly
if [[ -f "$CACHE" ]] && (( $(date +%s) - $(stat -c %Y "$CACHE") < 30 )); then
    NETWORKS=$(cat "$CACHE")
    ( build_list "$CURRENT" > "$CACHE" ) &
else
    # No cache — show animated spinner in rofi while scanning
    SCAN_DONE="/tmp/wifi-scan-$$"

    # Start scan in background
    ( build_list "$CURRENT" > "$CACHE"; touch "$SCAN_DONE" ) &
    SCAN_PID=$!

    # Spinner animation loop — cycles rofi with bouncing dots
    FRAMES=(
        "󰤟       Scanning"
        "  󰤥     Scanning."
        "    󰤨   Scanning.."
        "  󰤥     Scanning..."
        "󰤟       Scanning.."
        "        Scanning."
    )

    while [[ ! -f "$SCAN_DONE" ]]; do
        for frame in "${FRAMES[@]}"; do
            [[ -f "$SCAN_DONE" ]] && break 2
            echo "" | rofi -dmenu -mesg "$frame" -p "󰤨  WiFi" -theme-str "$THEME
            listview { lines: 0; }
            inputbar { enabled: false; }
            window { width: 350px; }
            message { padding: 24px 16px; }
            textbox { font: \"JetBrainsMono Nerd Font 12\"; }" &
            ROFI_PID=$!
            sleep 0.3
            kill "$ROFI_PID" 2>/dev/null
            wait "$ROFI_PID" 2>/dev/null
        done
    done

    rm -f "$SCAN_DONE"
    wait "$SCAN_PID" 2>/dev/null
    NETWORKS=$(cat "$CACHE")
fi

# Prepend disconnect option
if [[ -n "$CURRENT" ]]; then
    NETWORKS="󰤭   Disconnect ($CURRENT)"$'\n'"$NETWORKS"
fi

# Show rofi with results
CHOSEN=$(echo "$NETWORKS" | rofi -dmenu -i -p "󰤨  WiFi" -theme-str "$THEME")
[[ -z "$CHOSEN" ]] && exit 0

# Handle disconnect
if [[ "$CHOSEN" == *"Disconnect"* ]]; then
    nmcli dev disconnect "$IFACE" 2>/dev/null
    notify-send "WiFi" "Disconnected from $CURRENT"
    rm -f "$CACHE"
    exit 0
fi

# Extract SSID
SSID=$(echo "$CHOSEN" | sed 's/^[^ ]*   //;s/  󰌾.*//;s/  ✓//')

# Connect
if nmcli -t -f NAME con show | grep -qx "$SSID"; then
    nmcli con up "$SSID" 2>/dev/null
    [[ $? -eq 0 ]] && notify-send "WiFi" "Connected to $SSID" || notify-send "WiFi" "Failed to connect" -u critical
else
    PASS=$(rofi -dmenu -p "󰌾  Password" -password -theme-str "$THEME")
    if [[ -n "$PASS" ]]; then
        nmcli dev wifi connect "$SSID" password "$PASS" 2>/dev/null
        [[ $? -eq 0 ]] && notify-send "WiFi" "Connected to $SSID" || notify-send "WiFi" "Failed to connect" -u critical
    fi
fi
rm -f "$CACHE"
