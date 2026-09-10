#!/usr/bin/env bash
# CRT TV control aliases (sourced from ~/.bashrc via install.sh)
CRT_TV_DIR="$HOME/crt-tv"
alias tv-stop='pkill -f play-tv.sh; pkill mpv'
alias tv-start="nohup $CRT_TV_DIR/scripts/play-tv.sh >/dev/null 2>&1 &"
alias tv-restart='tv-stop; sleep 1; tv-start'
alias tv-status='pgrep -a mpv >/dev/null && echo "TV is PLAYING" || echo "TV is stopped"'
alias tv-update="git -C $CRT_TV_DIR pull"
