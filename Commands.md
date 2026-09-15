# Commands

Quick reference for the CRT-TV Raspberry Pi project. See [[App]] for the app plan.

## Connect
```bash
ssh avalverde@raspberrypi.local     # SSH into the Pi
```

## Move files to the Pi
```bash
# SFTP (paste in file manager address bar):
sftp://avalverde@raspberrypi.local/home/avalverde/videos

# Samba share (needs gvfs-smb on CachyOS):
smb://raspberrypi.local/videos

# scp a single file from this PC -> Pi:
scp some-episode.mp4 avalverde@raspberrypi.local:~/videos/
```

## Play video
```bash
# Full command for the CRT (fills screen + HDMI audio):
mpv --fullscreen --panscan=1.0 ~/videos/*.mp4

mpv --fullscreen --panscan=1.0 --shuffle ~/videos/   # shuffled
mpv --no-video ~/videos/file.mp4                     # audio only (test without display)
# in mpv: q = quit, space = pause, arrows = seek, < > = prev/next
```

**CRT display notes:**
- `--panscan=1.0` fills the screen (kills the black side bars). Lower it (e.g. `0.5`) if it over-zooms.
- `--audio-device='alsa/sysdefault:CARD=vc4hdmi0'` forces sound out over HDMI (needed for the HDMI2AV box). Also set globally via `sudo raspi-config` → System Options → Audio → HDMI.
- A little overscan/border is normal and expected on a CRT.

## The app (remote control)
On an interactive SSH login the retro **TV / RADIO / EXIT** app opens automatically
(`app/remote.py`). EXIT drops you to a shell; reopen with `tv-app`.
- **TV → SHUFFLE**: randomized broadcast across everything.
- **TV → Category → Show**: play a show in order (then auto-returns to shuffle).
- **NOW PLAYING**: live controls over the CRT — `SPACE` pause, `←/→` seek,
  `n/p` skip, `+/-` volume, `a` audio, `s` subs, `v` subs on/off,
  `[ ]` sub size, `,/.` sub position, `z` zoom-to-fill.
- Want a plain maintenance shell instead of the app: `TV_NO_APP=1 ssh …`, or EXIT.

## Control the TV (shell)
The Pi boots into shuffled playback (autologin on tty1 runs `play-tv.sh`).
Control functions (from `scripts/aliases.sh` via `~/.bashrc`):
```bash
tv-stop      # pause playback (creates ~/.tv-paused so it survives getty respawn)
tv-start     # resume
tv-restart   # stop + start
tv-status    # PLAYING / STOPPED / idle
tv-app       # open the remote app
tv-update    # git pull the latest project on the Pi
```
Manual equivalent:
```bash
touch ~/.tv-paused; pkill mpv    # stop
rm -f ~/.tv-paused               # start
```
- Stopping is temporary — auto-starts again on reboot.
- **Gotcha:** if `tv-stop` seems to "restart", stale OLD `alias tv-stop=...` lines
  in `~/.bashrc` are shadowing the function — remove them (aliases beat functions).
- Playlist switching uses a one-shot queue file `~/.tv-queue.m3u` + `pkill mpv`
  (~1s "channel change"); when it ends, playback returns to shuffle.
- Audio/subtitle rules live in `~/.config/mpv/scripts/autotracks.lua`
  (per-show fixes in `~/.config/mpv/overrides.json`).
- Sizing: 4:3 output is forced via `scripts/force-4x3.sh` (revertible: `force-4x3.sh off`).


## QoL / system info
```bash
vcgencmd measure_temp        # CPU temperature
vcgencmd measure_volts       # core voltage
vcgencmd get_throttled       # 0x0 = healthy; nonzero = under-volt/throttle happened
uptime                       # how long it's been on + load
free -h                      # RAM usage
df -h                        # disk space (watch the SD card filling up)
du -sh ~/videos              # size of the video library
htop                         # live CPU/RAM/process viewer (sudo apt install htop)
hostname -I                  # the Pi's IP address
ip a                         # network interfaces / IP detail
sensors                      # temps (needs: sudo apt install lm-sensors)
```

## Services (systemd)
```bash
systemctl status <name>          # is it running?
sudo systemctl restart <name>    # restart it
sudo systemctl enable <name>     # start on boot
journalctl -u <name> -e          # view its logs (end)
journalctl -u <name> -f          # follow logs live
```

## Samba
```bash
sudo systemctl restart smbd      # restart file sharing
sudo smbpasswd -a avalverde      # set/reset the Samba password
smbclient -L localhost -U avalverde   # list shares
```

## Torrent (qBittorrent-nox) — once installed
```bash
# Web UI (open in any browser / phone):
http://raspberrypi.local:8080
systemctl status qbittorrent-nox
sudo systemctl restart qbittorrent-nox
```

## Housekeeping
```bash
sudo apt update && sudo apt full-upgrade   # update the Pi
sudo reboot                                # restart
sudo poweroff                              # safe shutdown (wait for LED before unplugging)
```

## Fixes / gotchas
- **nano/editor "Error opening terminal: xterm-ghostty"** → prefix with `TERM=xterm`, e.g. `TERM=xterm sudo nano file`
- **Converter must be HDMI2AV** (HDMI in → RCA out). AV2HDTV is the WRONG direction.
- **Converter NTSC/PAL switch** → set to **NTSC** for the Sony Trinitron in Chile.

opens [[App]]
