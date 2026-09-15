#!/usr/bin/env bash
# CRT TV playback engine (single mpv owner on the CRT).
#   - idles while $TV_PAUSE_FLAG exists (tv-stop)
#   - if $TV_QUEUE_FILE (m3u) exists: play it in order ONCE, then delete it
#     (this is how "play a show -> back to shuffle" works)
#   - otherwise: shuffle everything in $VIDEO_DIR (rescans each pass)
# Sizing/subtitles/track-rules come from ~/.config/mpv (mpv.conf + autotracks.lua).
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

MPV_COMMON=( --fullscreen --vo=drm --no-osc --really-quiet
             --input-ipc-server="$MPV_SOCKET" )

while true; do
  # Paused? idle (tv-start removes the flag to resume).
  if [ -f "$TV_PAUSE_FLAG" ]; then
    sleep 2
    continue
  fi

  # A queued playlist (a chosen show) takes priority, played once in order.
  if [ -s "$TV_QUEUE_FILE" ]; then
    mpv "${MPV_COMMON[@]}" --playlist="$TV_QUEUE_FILE"
    rm -f "$TV_QUEUE_FILE"
    sleep 1
    continue
  fi

  # Default: shuffle the whole library.
  mapfile -d '' -t files < <(find "$VIDEO_DIR" -type f \
      \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.avi' \
         -o -iname '*.mov' -o -iname '*.webm' -o -iname '*.m4v' \) -print0)

  if [ "${#files[@]}" -eq 0 ]; then
    echo "No videos found in $VIDEO_DIR — waiting 10s..."
    sleep 10
    continue
  fi

  mpv "${MPV_COMMON[@]}" --shuffle "${files[@]}"
  sleep 1
done
