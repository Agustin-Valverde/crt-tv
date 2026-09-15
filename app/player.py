"""Switch what the CRT plays, by driving the play-tv.sh engine.

Playlist switching is done via the queue file + restarting mpv (a ~1s
"channel change"), NOT via live IPC playlist surgery. Live controls
(pause/seek/tracks/volume) go through mpvipc.MPV instead.
"""
import os
import subprocess

from config import TV_PAUSE_FLAG, TV_QUEUE_FILE


def _clear_pause():
    try:
        os.remove(TV_PAUSE_FLAG)
    except FileNotFoundError:
        pass


def _restart_mpv():
    """Kill the current mpv so the play-tv.sh loop picks up the new state."""
    subprocess.run(["pkill", "mpv"], check=False)


def play_shuffle():
    """Return to the randomized all-content channel."""
    _clear_pause()
    try:
        os.remove(TV_QUEUE_FILE)
    except FileNotFoundError:
        pass
    _restart_mpv()


def play_paths(paths):
    """Queue an ordered playlist (a show / episode) to play once, then shuffle."""
    if not paths:
        return
    _clear_pause()
    with open(TV_QUEUE_FILE, "w", encoding="utf-8") as f:
        for p in paths:
            f.write(p + "\n")
    _restart_mpv()
