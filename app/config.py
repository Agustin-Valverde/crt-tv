"""Central config for the crt-tv app. Reads env (from env.sh) with sane defaults."""
import os

HOME = os.path.expanduser("~")

VIDEO_DIR     = os.environ.get("VIDEO_DIR", os.path.join(HOME, "videos"))
MPV_SOCKET    = os.environ.get("MPV_SOCKET", "/tmp/mpvsocket")
TV_QUEUE_FILE = os.environ.get("TV_QUEUE_FILE", os.path.join(HOME, ".tv-queue.m3u"))
TV_PAUSE_FLAG = os.environ.get("TV_PAUSE_FLAG", os.path.join(HOME, ".tv-paused"))

CATEGORIES = os.environ.get("TV_CATEGORIES", "Anime Cartoons-Series Movies").split()

VIDEO_EXTS = {".mp4", ".mkv", ".avi", ".mov", ".webm", ".m4v"}

# Command used for the Spotify TUI (RADIO). Overridable via env.
SPOTIFY_CMD = os.environ.get("TV_SPOTIFY_CMD", "spotify_player")
