#!/usr/bin/env bash
# Install spotify_player (RADIO). Requires Spotify Premium for playback.
# NOTE: builds from source on the Pi (can take a while).
set -e
echo ">> Installing build dependencies"
sudo apt-get update
sudo apt-get install -y build-essential pkg-config cmake \
    libssl-dev libasound2-dev libdbus-1-dev

if ! command -v cargo >/dev/null 2>&1; then
  echo ">> Installing Rust (rustup)"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi

echo ">> Building spotify_player (streaming + media control)"
cargo install spotify_player --locked --features streaming,media-control

echo
echo "Done. First run does an interactive Spotify login:"
echo "    spotify_player"
echo "Then RADIO in the app will launch it. (Premium required for playback.)"
