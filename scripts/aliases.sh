#!/usr/bin/env bash
# CRT TV control functions (sourced from ~/.bashrc via install.sh)
CRT_TV_DIR="$HOME/crt-tv"
source "$CRT_TV_DIR/scripts/env.sh" 2>/dev/null

tv-stop()    { touch "$TV_PAUSE_FLAG"; pkill mpv; echo "TV stopped."; }
tv-start()   {
  rm -f "$TV_PAUSE_FLAG"
  # If no player loop is running (e.g. dev over SSH), start one detached.
  pgrep -f play-tv.sh >/dev/null || nohup "$CRT_TV_DIR/scripts/play-tv.sh" >/dev/null 2>&1 &
  echo "TV started."
}
tv-restart() { tv-stop; sleep 1; tv-start; }
tv-status()  {
  if [ -f "$TV_PAUSE_FLAG" ]; then echo "TV is STOPPED (paused)";
  elif pgrep -a mpv >/dev/null;   then echo "TV is PLAYING";
  else echo "TV is idle (no video yet)"; fi
}
tv-update()  { git -C "$CRT_TV_DIR" pull; }
