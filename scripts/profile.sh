#!/usr/bin/env bash
# Sourced from ~/.bash_profile.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

# Physical console (the CRT): become the playback engine.
if [[ "$(tty)" == "/dev/tty1" ]]; then
    exec "$SCRIPT_DIR/play-tv.sh"
fi

# Interactive SSH login: open the remote app (returns to shell on EXIT).
# Set TV_NO_APP=1 to get a plain maintenance shell instead.
case "$-" in
  *i*)
    if [[ -z "${TV_NO_APP:-}" ]]; then
        "$SCRIPT_DIR/tv-app.sh"
    fi
    ;;
esac
