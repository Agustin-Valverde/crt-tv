#!/usr/bin/env bash
# Force (or remove) a 4:3 HDMI output mode so the CRT fills correctly.
# Usage: force-4x3.sh [on|off]   (default: on)
set -e
MODE="${1:-on}"
PARAM="video=HDMI-A-1:720x480@60"
for f in /boot/firmware/cmdline.txt /boot/cmdline.txt; do
  [ -f "$f" ] && CMDLINE="$f" && break
done
[ -z "${CMDLINE:-}" ] && { echo "cmdline.txt not found"; exit 1; }

sudo cp "$CMDLINE" "$CMDLINE.crtbak.$(date +%s)"
if [ "$MODE" = "off" ]; then
  sudo sed -i "s/ *$PARAM//g" "$CMDLINE"
  echo "Removed 4:3 mode. Reboot to apply."
else
  grep -q "$PARAM" "$CMDLINE" || sudo sed -i "s/\$/ $PARAM/" "$CMDLINE"
  echo "Set 4:3 mode ($PARAM). Reboot to apply."
fi
echo "cmdline is now:"; cat "$CMDLINE"
