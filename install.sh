#!/usr/bin/env bash
# One-time setup on the Raspberry Pi. Safe to re-run (idempotent).
set -e
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">> Making scripts executable"
chmod +x "$REPO/scripts/"*.sh

echo ">> Wiring ~/.bash_profile (autostart on tty1)"
LINE_PROFILE="source \"$REPO/scripts/profile.sh\""
grep -qxF "$LINE_PROFILE" "$HOME/.bash_profile" 2>/dev/null \
  || echo "$LINE_PROFILE" >> "$HOME/.bash_profile"

echo ">> Wiring ~/.bashrc (tv-* aliases)"
LINE_RC="source \"$REPO/scripts/aliases.sh\""
grep -qxF "$LINE_RC" "$HOME/.bashrc" 2>/dev/null \
  || echo "$LINE_RC" >> "$HOME/.bashrc"

echo ">> Ensuring ~/.bash_profile loads ~/.bashrc (so aliases work over SSH)"
LINE_SRC='[ -f ~/.bashrc ] && . ~/.bashrc'
grep -qxF "$LINE_SRC" "$HOME/.bash_profile" 2>/dev/null \
  || echo "$LINE_SRC" >> "$HOME/.bash_profile"

echo ">> Ensuring video dir exists"
source "$REPO/scripts/env.sh"
mkdir -p "$VIDEO_DIR"

echo ">> Installing qBittorrent-nox (if missing)"
if ! command -v qbittorrent-nox >/dev/null 2>&1; then
  sudo apt-get update && sudo apt-get install -y qbittorrent-nox
fi

echo ">> Enabling qbittorrent-nox service for $(id -un)"
sudo systemctl enable --now "qbittorrent-nox@$(id -un)"
echo "   Web UI: http://raspberrypi.local:8080  (set save path to $VIDEO_DIR)"


echo ">> Linking mpv config (~/.config/mpv -> repo)"
mkdir -p "$HOME/.config"
if [ -e "$HOME/.config/mpv" ] && [ ! -L "$HOME/.config/mpv" ]; then
  mv "$HOME/.config/mpv" "$HOME/.config/mpv.bak.$(date +%s)"
fi
ln -sfn "$REPO/config/mpv" "$HOME/.config/mpv"

echo ">> Ensuring python3 is present"
command -v python3 >/dev/null 2>&1 || sudo apt-get install -y python3

echo
echo "Done. Reminders:"
echo "  - Remove any OLD autostart block / aliases from ~/.bash_profile and ~/.bashrc"
echo "    and the old ~/play-tv.sh, so nothing runs twice."
echo "  - Run 'source ~/.bashrc' or re-login to load the aliases."
echo "  - VIDEO_DIR is: $VIDEO_DIR"
