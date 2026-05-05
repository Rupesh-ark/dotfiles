#!/usr/bin/env bash
# Set random gruvbox wallpapers on all monitors

WALLDIR="$HOME/Pictures/wallpapers/gruvbox"

# Detect wallpaper tool: prefers awww (custom), falls back to standard swww
WALL_CMD=""
if command -v awww >/dev/null 2>&1; then
    WALL_CMD="awww"
elif command -v swww >/dev/null 2>&1; then
    WALL_CMD="swww"
else
    echo "No wallpaper tool found. Install swww to use this script."
    exit 1
fi

# Get all image files
mapfile -t wallpapers < <(find "$WALLDIR" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \))

if [[ ${#wallpapers[@]} -eq 0 ]]; then
    echo "No wallpapers found in $WALLDIR"
    exit 1
fi

# Get connected monitors
mapfile -t monitors < <(hyprctl monitors -j | jq -r '.[].name')

# Set a random wallpaper on each monitor
for mon in "${monitors[@]}"; do
    pick="${wallpapers[$((RANDOM % ${#wallpapers[@]}))]}"
    $WALL_CMD img -o "$mon" "$pick" \
        --transition-type grow \
        --transition-duration 2 \
        --transition-fps 60 \
        --transition-pos center &
done

wait
