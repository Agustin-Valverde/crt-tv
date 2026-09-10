#!/usr/bin/env bash
# CRT TV — endless shuffled playback of $VIDEO_DIR (and subfolders).
# Rescans + reshuffles every full pass, so new downloads get picked up.
# Exposes an mpv IPC socket so the remote app can control it.
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

while true; do
  mapfile -d '' -t files < <(find "$VIDEO_DIR" -type f \
      \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.avi' \
         -o -iname '*.mov' -o -iname '*.webm' -o -iname '*.m4v' \) -print0)

  if [ "${#files[@]}" -eq 0 ]; then
    echo "No videos found in $VIDEO_DIR — waiting 10s..."
    sleep 10
    continue
  fi

  mpv \
    --fullscreen \
    --panscan=1.0 \
    --vo=drm \
    --shuffle \
    --no-osc \
    --really-quiet \
    --input-ipc-server="$MPV_SOCKET" \
    "${files[@]}"

  sleep 1   # brief pause before reshuffling / on crash
done
