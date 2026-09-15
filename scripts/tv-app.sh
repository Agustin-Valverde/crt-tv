#!/usr/bin/env bash
# Launch the crt-tv remote app. Returns to the shell when you EXIT.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"

# Fall back to a known TERM if the current one isn't in the Pi's terminfo
# (e.g. xterm-ghostty), so curses can always start.
if ! infocmp "${TERM:-dumb}" >/dev/null 2>&1; then
  export TERM=xterm-256color
fi

python3 "$CRT_TV_DIR/app/remote.py" "$@"
