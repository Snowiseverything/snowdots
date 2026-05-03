#!/bin/bash
DATA=$(curl -s "https://api.sunrise-sunset.org/json?lat=36.19&lng=44.01&formatted=0")
SUNRISE=$(echo $DATA | jq -r '.results.sunrise' | xargs -I{} date -d {} +%R)
SUNSET=$(echo $DATA | jq -r '.results.sunset' | xargs -I{} date -d {} +%R)

echo -e "☀️ Sunrise: $SUNRISE"
echo -e "🌙 Sunset:  $SUNSET"
