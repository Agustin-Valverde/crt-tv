#!/usr/bin/env bash
# Autostart the TV on the physical console (tty1) only — not over SSH.
# Sourced from ~/.bash_profile via install.sh.
if [[ "$(tty)" == "/dev/tty1" ]]; then
    exec "$HOME/crt-tv/scripts/play-tv.sh"
fi
