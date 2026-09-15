#!/usr/bin/env bash
# Force (or remove) a 4:3-friendly HDMI output mode so the CRT fills correctly.
# Auto-detects the connected HDMI connector. Usage: force-4x3.sh [on|off]
set -e
MODE="${1:-on}"
RES="720x480@60"

# detect connected connector name, e.g. HDMI-A-1
CONN=""
for s in /sys/class/drm/card*-HDMI-A-*/status; do
  [ -e "$s" ] || continue
  if [ "$(cat "$s")" = "connected" ]; then
    name="$(basename "$(dirname "$s")")"   # card1-HDMI-A-1
    CONN="${name#*-}"                       # HDMI-A-1
    break
  fi
done
[ -z "$CONN" ] && { echo "No connected HDMI connector found"; exit 1; }

for f in /boot/firmware/cmdline.txt /boot/cmdline.txt; do
  [ -f "$f" ] && CMDLINE="$f" && break
done
[ -z "${CMDLINE:-}" ] && { echo "cmdline.txt not found"; exit 1; }

sudo cp "$CMDLINE" "$CMDLINE.crtbak.$(date +%s)"
# always strip any prior video=HDMI-A-*:... (fixes wrong connector names too)
sudo sed -i -E 's/ *video=HDMI-A-[0-9]+:[^ ]*//g' "$CMDLINE"
if [ "$MODE" != "off" ]; then
  sudo sed -i "s/\$/ video=$CONN:$RES/" "$CMDLINE"
  echo "Set 4:3 mode: video=$CONN:$RES"
else
  echo "Removed forced mode."
fi
echo "Reboot to apply. cmdline is now:"; cat "$CMDLINE"
