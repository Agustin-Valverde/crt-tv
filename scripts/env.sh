#!/usr/bin/env bash
# Central config for the CRT-TV project. Edit paths HERE only.
# When you migrate to an SSD, change VIDEO_DIR and everything follows.
export VIDEO_DIR="${VIDEO_DIR:-$HOME/videos}"
export MPV_SOCKET="${MPV_SOCKET:-/tmp/mpvsocket}"
export TV_PAUSE_FLAG="${TV_PAUSE_FLAG:-$HOME/.tv-paused}"
export TV_QUEUE_FILE="${TV_QUEUE_FILE:-$HOME/.tv-queue.m3u}"
export TV_DRM_MODE="${TV_DRM_MODE:-1024x768}"
export CRT_TV_DIR="${CRT_TV_DIR:-$HOME/crt-tv}"
# Categories (top-level folders under VIDEO_DIR; also qBittorrent categories)
export TV_CATEGORIES="${TV_CATEGORIES:-Anime Cartoons-Series Movies}"
