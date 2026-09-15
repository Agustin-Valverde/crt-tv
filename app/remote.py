#!/usr/bin/env python3
"""crt-tv remote — a retro white-on-blue TUI to drive the CRT over SSH.

Menus switch what plays (via player.py); the NOW PLAYING screen live-controls
the running mpv over its IPC socket (mpvipc.py). EXIT drops to a shell.
"""
import curses
import locale
import os
import subprocess
import sys

import config
import library
import player
from mpvipc import MPV

locale.setlocale(locale.LC_ALL, "")

mpv = MPV(config.MPV_SOCKET)

# box-drawing (falls back to ASCII if the terminal can't encode them)
TL, TR, BL, BR, HZ, VT = "╔", "╗", "╚", "╝", "═", "║"

BANNER = [
    "╔═══════════════════════════════════╗",
    "║   ▄▄· ▄▄▄  ▄▄▄▄▄     ▄▄▄▄▄▌ ▐·     ║",
    "║   ▐█ ▌▪▀▄ █·•██      •██  █▌▐█     ║",
    "║   ██ ▄▄▐▀▀▄  ▐█.▪     ▐█.▪▐█▐█•    ║",
    "║   ▐███▌▐█•█▌ ▐█▌·     ▐█▌· █▌▐█▌   ║",
    "║   ·▀▀▀ .▀  ▀ ▀▀▀      ▀▀▀  ▀▀ █▪   ║",
    "╚═══════════════════════════════════╝",
]

# color pair ids
C_NORMAL, C_SELECT, C_ACCENT, C_DIM = 1, 2, 3, 4


def init_colors():
    curses.start_color()
    # Use fixed 256-cube indices so a themed ANSI palette (matugen) can't wash
    # out the blue/white. Fall back to the 8 base colors on limited terminals.
    if curses.COLORS >= 256:
        BLUE, WHITE, YELLOW, CYAN, BLACK, GRAY = 19, 231, 226, 51, 16, 253
    else:
        BLUE, WHITE, YELLOW, CYAN, BLACK, GRAY = (
            curses.COLOR_BLUE, curses.COLOR_WHITE, curses.COLOR_YELLOW,
            curses.COLOR_CYAN, curses.COLOR_BLACK, curses.COLOR_WHITE)
    curses.init_pair(C_NORMAL, WHITE, BLUE)
    curses.init_pair(C_SELECT, BLACK, CYAN)
    curses.init_pair(C_ACCENT, YELLOW, BLUE)
    curses.init_pair(C_DIM, GRAY, BLUE)


def safe_add(win, y, x, text, attr=0):
    h, w = win.getmaxyx()
    if 0 <= y < h and x < w:
        try:
            win.addstr(y, x, text[: max(0, w - x - 1)], attr)
        except curses.error:
            pass


def draw_box(win, y, x, h, w, attr):
    try:
        safe_add(win, y, x, TL + HZ * (w - 2) + TR, attr)
        for i in range(1, h - 1):
            safe_add(win, y + i, x, VT, attr)
            safe_add(win, y + i, x + w - 1, VT, attr)
        safe_add(win, y + h - 1, x, BL + HZ * (w - 2) + BR, attr)
    except curses.error:
        pass


def draw_shell(stdscr, subtitle=""):
    stdscr.bkgd(" ", curses.color_pair(C_NORMAL))
    stdscr.erase()
    h, w = stdscr.getmaxyx()
    draw_box(stdscr, 0, 0, h, w, curses.color_pair(C_NORMAL) | curses.A_BOLD)
    # banner
    by = 1
    if h > len(BANNER) + 8 and w > 40:
        for i, line in enumerate(BANNER):
            safe_add(stdscr, by + i, max(1, (w - len(line)) // 2),
                     line, curses.color_pair(C_ACCENT) | curses.A_BOLD)
        by += len(BANNER)
    else:
        safe_add(stdscr, by, max(1, (w - 8) // 2), "C R T · T V",
                 curses.color_pair(C_ACCENT) | curses.A_BOLD)
        by += 1
    if subtitle:
        safe_add(stdscr, by, max(1, (w - len(subtitle)) // 2),
                 subtitle, curses.color_pair(C_DIM) | curses.A_BOLD)
    return by + 2  # first free row for content


def footer(stdscr, text):
    h, w = stdscr.getmaxyx()
    safe_add(stdscr, h - 2, 2, text.ljust(w - 4)[: w - 4],
             curses.color_pair(C_DIM))


def menu(stdscr, subtitle, items, hint="↑/↓ move   ENTER select   Q/ESC back"):
    """Draw a selectable menu. Returns selected index, or None on back/quit."""
    idx = 0
    while True:
        top = draw_shell(stdscr, subtitle)
        h, w = stdscr.getmaxyx()
        # visible window over items
        maxrows = max(1, h - top - 3)
        start = max(0, min(idx - maxrows // 2, max(0, len(items) - maxrows)))
        for row, i in enumerate(range(start, min(len(items), start + maxrows))):
            label = items[i]
            y = top + row
            if i == idx:
                bar = ("  ▶ " + label).ljust(w - 8)
                safe_add(stdscr, y, 4, bar, curses.color_pair(C_SELECT) | curses.A_BOLD)
            else:
                safe_add(stdscr, y, 4, "    " + label,
                         curses.color_pair(C_NORMAL))
        footer(stdscr, hint)
        stdscr.refresh()

        k = stdscr.getch()
        if k in (curses.KEY_UP, ord("k")):
            idx = (idx - 1) % len(items)
        elif k in (curses.KEY_DOWN, ord("j")):
            idx = (idx + 1) % len(items)
        elif k in (curses.KEY_ENTER, 10, 13, ord("l")):
            return idx
        elif k in (27, ord("q"), curses.KEY_BACKSPACE, 127, ord("h")):
            return None


def fmt_time(sec):
    if sec is None:
        return "--:--"
    sec = int(sec)
    return f"{sec // 60:d}:{sec % 60:02d}"


def now_playing(stdscr):
    stdscr.timeout(700)  # refresh even without keypress
    try:
        while True:
            top = draw_shell(stdscr, "NOW PLAYING")
            h, w = stdscr.getmaxyx()
            running = mpv.is_running()
            if not running:
                safe_add(stdscr, top + 1, 4, "TV is stopped.",
                         curses.color_pair(C_ACCENT) | curses.A_BOLD)
            else:
                title = mpv.get("media-title") or os.path.basename(mpv.get("path") or "")
                paused = mpv.get("pause")
                pos, dur = mpv.get("time-pos"), mpv.get("duration")
                vol = mpv.get("volume")
                aid, sid = mpv.get("aid"), mpv.get("sid")
                alang = mpv.get("current-tracks/audio/lang") or ""
                atitle = mpv.get("current-tracks/audio/title") or ""
                slang = mpv.get("current-tracks/sub/lang") or ""
                rows = [
                    ("Title ", (title or "?")[: w - 16]),
                    ("State ", "PAUSED" if paused else "PLAYING"),
                    ("Time  ", f"{fmt_time(pos)} / {fmt_time(dur)}"),
                    ("Audio ", f"#{aid}  {alang} {atitle}".strip()),
                    ("Subs  ", "off" if sid in (False, None, "no") else f"#{sid}  {slang}"),
                    ("Volume", f"{int(vol) if vol is not None else '?'}%"),
                ]
                for i, (k, v) in enumerate(rows):
                    safe_add(stdscr, top + i, 4, k + ": ",
                             curses.color_pair(C_ACCENT) | curses.A_BOLD)
                    safe_add(stdscr, top + i, 4 + len(k) + 2, str(v),
                             curses.color_pair(C_NORMAL))
            controls = [
                "SPACE pause   ←/→ seek   n/p skip   +/- volume",
                "a audio   s subs   v sub on/off",
                "[ ] sub size   ,/. sub pos   z zoom-to-fill",
                "Q/ESC back to menu",
            ]
            for i, c in enumerate(controls):
                safe_add(stdscr, h - 6 + i, 4, c, curses.color_pair(C_DIM))
            stdscr.refresh()

            k = stdscr.getch()
            if k == -1:
                continue
            if k in (27, ord("q"), curses.KEY_BACKSPACE, 127):
                return
            elif k == ord(" "):
                mpv.cycle("pause")
            elif k == curses.KEY_RIGHT:
                mpv.command("seek", 10)
            elif k == curses.KEY_LEFT:
                mpv.command("seek", -10)
            elif k in (ord("n"),):
                mpv.command("playlist-next")
            elif k in (ord("p"),):
                mpv.command("playlist-prev")
            elif k in (ord("+"), ord("=")):
                mpv.add("volume", 5)
            elif k in (ord("-"), ord("_")):
                mpv.add("volume", -5)
            elif k == ord("a"):
                mpv.cycle("aid")
            elif k == ord("s"):
                mpv.cycle("sid")
            elif k == ord("v"):
                mpv.cycle("sub-visibility")
            elif k == ord("["):
                mpv.add("sub-scale", -0.1)
            elif k == ord("]"):
                mpv.add("sub-scale", 0.1)
            elif k == ord(","):
                mpv.add("sub-pos", -1)
            elif k == ord("."):
                mpv.add("sub-pos", 1)
            elif k == ord("z"):
                cur = mpv.get("panscan") or 0.0
                mpv.set("panscan", 0.0 if cur and cur > 0.5 else 1.0)
    finally:
        stdscr.timeout(-1)


def browse_show(stdscr, category, show_name, show_path):
    episodes = library.list_episodes(show_path)
    labels = ["▶ Play whole show (in order)"] + [os.path.basename(e) for e in episodes]
    while True:
        sel = menu(stdscr, f"{category}  ›  {show_name}", labels)
        if sel is None:
            return "back"
        if sel == 0:
            player.play_paths(episodes)
        else:
            player.play_paths(episodes[sel - 1:])  # from chosen episode onward
        return "played"


def browse_category(stdscr, category):
    while True:
        shows = library.list_shows(category)
        if not shows:
            menu(stdscr, category, ["(empty — add content here)"])
            return
        sel = menu(stdscr, category, [s[0] for s in shows])
        if sel is None:
            return
        name, path = shows[sel]
        if browse_show(stdscr, category, name, path) == "played":
            return  # jump back out after starting playback


def tv_menu(stdscr):
    while True:
        cats = library.list_categories()
        items = ["🔀 SHUFFLE — all content (broadcast)"] + cats
        sel = menu(stdscr, "TV", items)
        if sel is None:
            return
        if sel == 0:
            player.play_shuffle()
            now_playing(stdscr)
            return
        browse_category(stdscr, cats[sel - 1])


def radio(stdscr):
    curses.endwin()
    # Pause the TV so its audio doesn't clash with the music.
    try:
        open(config.TV_PAUSE_FLAG, "w").close()
        subprocess.run(["pkill", "mpv"], check=False)
    except OSError:
        pass
    try:
        subprocess.call([config.SPOTIFY_CMD])
    except FileNotFoundError:
        input(f"\n'{config.SPOTIFY_CMD}' not installed. Run scripts/setup-spotify.sh.\n"
              "Press Enter to return...")
    finally:
        # Resume the TV when leaving RADIO.
        try:
            os.remove(config.TV_PAUSE_FLAG)
        except FileNotFoundError:
            pass
    stdscr.clear()
    stdscr.refresh()


def main(stdscr):
    curses.curs_set(0)
    init_colors()
    while True:
        sel = menu(stdscr, "MAIN MENU",
                   ["📺 TV", "📻 RADIO", "▶ NOW PLAYING", "⏻ EXIT"],
                   hint="↑/↓ move   ENTER select   Q quit to shell")
        if sel is None or sel == 3:
            return
        if sel == 0:
            tv_menu(stdscr)
        elif sel == 1:
            radio(stdscr)
        elif sel == 2:
            now_playing(stdscr)


def check():
    """Non-interactive smoke test (no curses)."""
    print("VIDEO_DIR   :", config.VIDEO_DIR)
    print("MPV_SOCKET  :", config.MPV_SOCKET, "(running)" if mpv.is_running() else "(not running)")
    print("Categories  :", library.list_categories())
    for c in library.list_categories():
        shows = library.list_shows(c)
        print(f"  {c}: {len(shows)} shows")
        for name, path in shows[:5]:
            print(f"    - {name}  ({len(library.list_episodes(path))} eps)")
    print("Total videos:", len(library.all_videos()))


if __name__ == "__main__":
    if "--check" in sys.argv:
        check()
    else:
        try:
            curses.wrapper(main)
        except KeyboardInterrupt:
            pass
