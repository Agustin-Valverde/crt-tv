"""Scan the Category/Show/episodes library and build playlists."""
import os
import re

from config import CATEGORIES, VIDEO_DIR, VIDEO_EXTS

UNCATEGORIZED = "Uncategorized"


def _natural_key(s):
    """Sort like a human: ep2 before ep10."""
    return [int(t) if t.isdigit() else t.lower()
            for t in re.split(r"(\d+)", s)]


def _is_video(name):
    return os.path.splitext(name)[1].lower() in VIDEO_EXTS


def _videos_in(path):
    """All video files under path, recursively, natural-sorted by full path."""
    found = []
    for root, _dirs, files in os.walk(path):
        for f in files:
            if _is_video(f):
                found.append(os.path.join(root, f))
    found.sort(key=lambda p: (_natural_key(os.path.dirname(p)), _natural_key(os.path.basename(p))))
    return found


def list_categories():
    """Known categories that exist on disk, plus Uncategorized if loose files exist."""
    cats = []
    for c in CATEGORIES:
        if os.path.isdir(os.path.join(VIDEO_DIR, c)):
            cats.append(c)
    # loose files directly under VIDEO_DIR -> Uncategorized bucket
    try:
        for name in os.listdir(VIDEO_DIR):
            full = os.path.join(VIDEO_DIR, name)
            if os.path.isfile(full) and _is_video(name):
                cats.append(UNCATEGORIZED)
                break
    except OSError:
        pass
    return cats


def list_shows(category):
    """Return [(show_name, path)] for a category (natural-sorted)."""
    if category == UNCATEGORIZED:
        # each loose file is its own 'show'
        shows = []
        try:
            for name in sorted(os.listdir(VIDEO_DIR), key=_natural_key):
                full = os.path.join(VIDEO_DIR, name)
                if os.path.isfile(full) and _is_video(name):
                    shows.append((name, full))
        except OSError:
            pass
        return shows

    base = os.path.join(VIDEO_DIR, category)
    shows = []
    try:
        for name in sorted(os.listdir(base), key=_natural_key):
            full = os.path.join(base, name)
            if os.path.isdir(full):
                shows.append((name, full))
    except OSError:
        pass
    return shows


def list_episodes(show_path):
    """Episodes for a show, in native (natural) order. A file returns itself."""
    if os.path.isfile(show_path):
        return [show_path]
    return _videos_in(show_path)


def all_videos():
    """Every video in the library (for shuffle)."""
    return _videos_in(VIDEO_DIR)
