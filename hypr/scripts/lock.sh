#!/usr/bin/env bash
# Lock screen with cmatrix background + hyprlock overlay

# Gruvbox colors for cmatrix (cycle randomly)
colors=("green" "red" "yellow" "blue" "magenta" "cyan" "white")
picked="${colors[$((RANDOM % ${#colors[@]}))]}"

# Launch kitty fullscreen with cmatrix on every monitor
# Uses hyprland's fullscreen layer trick via window rules
kitty --class "cmatrix-lock" \
    -o font_size=10 \
    -o background_opacity=0.85 \
    -o background="#282828" \
    -o cursor_shape=block \
    -o hide_window_decorations=yes \
    cmatrix -b -u 4 -C "$picked" &
CMATRIX_PID=$!

# Give kitty a moment to spawn
sleep 0.3

# Launch hyprlock (transparent, overlays on top)
hyprlock

# Cleanup: kill cmatrix when unlocked
kill $CMATRIX_PID 2>/dev/null
wait $CMATRIX_PID 2>/dev/null
