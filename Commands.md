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

## Control the TV
The Pi boots into shuffled playback automatically (autologin on tty1 runs
`~/play-tv.sh`, which loops mpv forever). These aliases (in `~/.bashrc`) control it over SSH:
```bash
tv-stop      # stop playback (kills the loop + mpv)
tv-start     # start playback again (detached, survives logout)
tv-restart   # stop + start
tv-status    # is it playing?
```
Manual equivalent if aliases aren't loaded:
```bash
pkill -f play-tv.sh; pkill mpv          # stop
nohup ~/play-tv.sh >/dev/null 2>&1 &    # start
```
- Stopping is temporary — it auto-starts again on the next reboot (`sudo reboot`).
- The player script lives at `~/play-tv.sh` (reference copy in `scripts/play-tv.sh`).
- Autostart is guarded to tty1 only, so SSH sessions stay a normal shell.

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
