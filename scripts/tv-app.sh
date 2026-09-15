#!/usr/bin/env bash
# Launch the crt-tv remote app. Returns to the shell when you EXIT.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/env.sh"
python3 "$CRT_TV_DIR/app/remote.py" "$@"
