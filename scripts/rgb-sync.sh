#!/bin/bash
## SnowDots — RGB sync to current wallpaper accent
## Routes through the bridge /sync so per-device brightness is preserved
## and off devices stay off (no black-flash). Falls back to direct fades
## only when the bridge is unreachable (e.g. early boot).

COLORS_FILE="$HOME/.cache/skwd-wall/colors.json"

# ── Boot wait: wallpaper accent (skwd/matugen may still be generating) ──
for _ in $(seq 1 90); do
    ACCENT=$(jq -r '.accent' "$COLORS_FILE" 2>/dev/null)
    if [ -n "$ACCENT" ] && [ "$ACCENT" != "null" ] && [ "$ACCENT" != "#000000" ]; then
        break
    fi
    sleep 1
done
if [ -z "$ACCENT" ] || [ "$ACCENT" = "null" ] || [ "$ACCENT" = "#000000" ]; then
    exit 0
fi

# ── Boot wait: OpenRGB full enumeration. The ASUS TUF controller
#    registers ~7s after server start (DRAM ~0.3s), so a naive 2s
#    boot sync only catches RAM. At runtime devices are already up and
#    this returns on the first poll. ──
timeout 45 python3 - <<'PYEOF' 2>/dev/null || true
import time
try:
    from openrgb import OpenRGBClient
except Exception:
    raise SystemExit(0)
for _ in range(45):
    try:
        c = OpenRGBClient()
        names = [d.name for d in c.devices]
        if len(names) >= 3 or any('TUF' in n or 'ASUS' in n for n in names):
            break
        time.sleep(1)
    except Exception:
        time.sleep(1)
PYEOF

LED_COLOR=$(python3 -c "
import colorsys

hex_color = '${ACCENT}'.lstrip('#')
r = int(hex_color[0:2], 16) / 255.0
g = int(hex_color[2:4], 16) / 255.0
b = int(hex_color[4:6], 16) / 255.0

h, l, s = colorsys.rgb_to_hls(r, g, b)

# Unified LED color: same hue, vibrant saturation, medium brightness
# Looks good on case LEDs, keyboard, and Govee strip alike
r_l, g_l, b_l = colorsys.hls_to_rgb(h, 0.45, 0.90)
print('%02x%02x%02x' % (int(r_l*255), int(g_l*255), int(b_l*255)))
" 2>/dev/null)

[ -z "$LED_COLOR" ] && exit 0

# ── Prefer the bridge /sync: it preserves each device's brightness and
#    silently updates color for off devices (no flash, no reset).
# ── The bridge's trigger_sync reads the SAME colors.json accent, so
#    passing LED_COLOR here is only for the direct-fallback path.
resp=$(curl -sf -m 3 -X POST http://localhost:5070/sync 2>/dev/null)
if [ -n "$resp" ] && echo "$resp" | jq -e '.ok' >/dev/null 2>&1; then
    msg=$(echo "$resp" | jq -r '.message // "Colors synced to wallpaper"')
    logger -t rgb-sync "$msg" 2>/dev/null || true
    exit 0
fi

# ── Bridge unreachable — fall back to direct fades at brightness 80 ─────
# Run PC and Govee fades in parallel with matching step timing
# fade-rgb.py: 10 steps × 20ms = 200ms fade
# govee-led.py --fade: 10 steps × 20ms = 200ms fade via daemon socket
# Both finish at ~same time for synchronized color transition
timeout 10 python3 "$HOME/Dotfiles/scripts/fade-rgb.py" "$LED_COLOR" 80 80 2>&1 | sed 's/^/[PC] /' &

timeout 10 python3 "$HOME/Dotfiles/scripts/govee-led.py" "$LED_COLOR" 80 --fade 2>&1 | sed 's/^/[Govee] /' || echo "[Govee] failed or timed out" &

wait
