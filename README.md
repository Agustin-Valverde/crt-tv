# crt-tv

Turn a Raspberry Pi + a CRT television into an always-on, shuffled retro-TV
channel. Power on the TV and something is already playing — like broadcast.

See **App.md** for the app plan and **Commands.md** for the command reference.

## Layout
- `scripts/env.sh` — central config (paths). Edit here when moving to an SSD.
- `scripts/play-tv.sh` — endless shuffled mpv playback (exposes an IPC socket).
- `scripts/aliases.sh` — `tv-stop` / `tv-start` / `tv-restart` / `tv-status` / `tv-update`.
- `scripts/profile.sh` — autostarts the TV on the physical console (tty1) only.
- `app/` — the remote-control app (navigated over SSH).
- `install.sh` — one-time wiring on the Pi (idempotent).

## Deploy on the Pi
```bash
git clone <this-repo-url> ~/crt-tv
~/crt-tv/install.sh
# remove old ~/play-tv.sh and old autostart/alias lines, then reboot
```

## Update the Pi later
```bash
tv-update   # = git -C ~/crt-tv pull
```

## Workflow
Edit + test on the PC, push, then `tv-update` (git pull) on the Pi.
