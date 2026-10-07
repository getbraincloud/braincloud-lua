#!/usr/bin/env bash
# Runs the LÖVE smoke test as a folder and as a packed .love (native extraction path).
set -e
cd "$(dirname "$0")"
IDS="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
LOVE="${LOVE:-$(command -v love || echo "$HOME/Applications/love.app/Contents/MacOS/love")}"
STAGE="$(mktemp -d)"
cp main.lua conf.lua "$STAGE/" && cp -R ../../braincloud "$STAGE/braincloud"
echo "== folder"; "$LOVE" "$STAGE" "$IDS"
(cd "$STAGE" && zip -qr ../lovetest.love .)
echo "== .love"; "$LOVE" "$STAGE/../lovetest.love" "$IDS"
rm -rf "$STAGE" "$STAGE/../lovetest.love"
