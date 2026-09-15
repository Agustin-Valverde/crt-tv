#!/usr/bin/env bash
# Install spotify_player (RADIO) from the prebuilt aarch64 binary.
# Requires Spotify Premium. 64-bit Raspberry Pi OS only.
set -e
VER="v0.25.1"
URL="https://github.com/aome510/spotify-player/releases/download/${VER}/spotify_player-aarch64-unknown-linux-gnu.tar.gz"

[ "$(uname -m)" = "aarch64" ] || { echo "Need 64-bit OS (aarch64); got $(uname -m)"; exit 1; }

mkdir -p "$HOME/.local/bin"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
echo ">> Downloading spotify_player ${VER}"
curl -fsSL "$URL" -o "$tmp/sp.tar.gz"
tar xzf "$tmp/sp.tar.gz" -C "$tmp"
install -m755 "$tmp/spotify_player" "$HOME/.local/bin/spotify_player"
"$HOME/.local/bin/spotify_player" --version

cat <<'MSG'

Installed to ~/.local/bin/spotify_player

NEXT: authenticate once (Premium required). From your PC, open an SSH session
that forwards the OAuth callback port, then run the auth command:

    ssh -L 8989:localhost:8989 avalverde@raspberrypi.local
    # EXIT the TV app to a shell, then:
    ~/.local/bin/spotify_player authenticate

It prints a URL - open it in your PC browser, approve, and the redirect to
127.0.0.1:8989 is forwarded to the Pi. Credentials are cached after that.
Then RADIO in the app just works.
MSG
