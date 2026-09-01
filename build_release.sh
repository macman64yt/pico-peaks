#!/usr/bin/env bash
# Builds the Pico Peaks 1.0.0 release (Linux + Windows + macOS .app + Android APK).
set -euo pipefail
cd "$(dirname "$0")"

echo "== Exporting Linux x86_64 build =="
DISPLAY=:1 godot --headless --path . --export-release "Linux x86_64" build/pico-peaks-1.0.0

echo "== Exporting Windows x86_64 build =="
DISPLAY=:1 godot --headless --path . --export-release "Windows Desktop" build/pico-peaks-1.0.0.exe

echo "== Exporting macOS universal .app =="
DISPLAY=:1 godot --headless --path . --export-release "macOS" build/pico-peaks.app
echo "== Packaging macOS app (pico-peaks-macos-universal.zip) =="
rm -f build/pico-peaks-macos-universal.zip
(cd build && zip -rq pico-peaks-macos-universal.zip pico-peaks.app)

echo "== Exporting Android APK (debug-signed, sideload-ready) =="
DISPLAY=:1 godot --headless --path . --export-debug "Android" build/pico-peaks-android.apk

echo "== Note: Android release signing (Play Store) is NOT configured. =="
echo "== See RELEASE.md for how to add a release keystore. =="

echo "== Done =="
ls -la build/