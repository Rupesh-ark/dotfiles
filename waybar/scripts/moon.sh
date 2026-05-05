#!/bin/bash
# Moon phase calculator - pure bash, no dependencies

# Days since known new moon (Jan 6, 2000)
known_new=$((946944000))
now=$(date +%s)
cycle=2551443  # lunar cycle in seconds (29.53 days)

phase=$(( (now - known_new) % cycle ))
phase_day=$(( phase / 86400 ))

if   (( phase_day < 2 ));  then icon="🌑"; name="New Moon"
elif (( phase_day < 6 ));  then icon="🌒"; name="Waxing Crescent"
elif (( phase_day < 9 ));  then icon="🌓"; name="First Quarter"
elif (( phase_day < 13 )); then icon="🌔"; name="Waxing Gibbous"
elif (( phase_day < 16 )); then icon="🌕"; name="Full Moon"
elif (( phase_day < 20 )); then icon="🌖"; name="Waning Gibbous"
elif (( phase_day < 23 )); then icon="🌗"; name="Last Quarter"
elif (( phase_day < 27 )); then icon="🌘"; name="Waning Crescent"
else                            icon="🌑"; name="New Moon"
fi

echo "{\"text\": \"$icon\", \"tooltip\": \"$name (Day $phase_day/29)\", \"class\": \"moon\"}"
