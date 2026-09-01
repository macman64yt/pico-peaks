# Pico Peaks

**PICO PEAKS 1.0.0 — every texture is procedural.**

A tiny file, a big view. Pico Peaks is a fully procedural survival sandbox running in Godot 4. No asset packs — mountains, trees, roads, buildings, weather, and NPCs are all generated at runtime.

## Features

- Entirely procedural open world (infinite curved terrain, biomes, rivers, roads, villages)
- Day/night cycle with dynamic weather: rain, wind, and tornadoes that tear up the world
- Survival: hunger, health, crafting from star shards, farming, fishing (from a boat!), hunting
- Buildable base with procedural structures (houses, taverns, church, reactor, towers)
- Vehicles: cars, boats, bikes
- NPC villagers who farm, wander, and talk (with push-to-talk chat, `/give`-style cash in the console)
- LAN multiplayer: play with friends, or run a dedicated server
- Mobile (Android) touch controls + desktop keyboard/mouse
- Settings screen with quality presets (low/medium/high/ultra), FOV, UI scale, and more

## Requirements

- Godot **4.7.1** (built against `4.7.1.stable.official`)
- Linux x86_64, Windows x86_64, macOS 11+ (universal: Apple Silicon + Intel), or Android 8+

## Building

```bash
# Linux release binary (build/pico-peaks-1.0.0)
godot --headless --path . --export-release "Linux x86_64" build/pico-peaks-1.0.0

# Windows release exe (build/pico-peaks-1.0.0.exe)
godot --headless --path . --export-release "Windows Desktop" build/pico-peaks-1.0.0.exe

# macOS universal app (build/pico-peaks.app) + zip
godot --headless --path . --export-release "macOS" build/pico-peaks.app
zip -rq build/pico-peaks-macos-universal.zip build/pico-peaks.app

# Android APK (debug-signed, sideload-ready)
godot --headless --path . --export-debug "Android" build/pico-peaks-android.apk

# iOS Xcode project (final .ipa requires macOS + Xcode + an Apple Developer account)
godot --headless --path . --export-debug "iOS" build/pico-peaks-ios
```

Or run `./build_release.sh`, which does all desktop + Android builds.

> For third-party powershell/jam: the Android export requires the Android export templates and SDK configured in the Godot editor settings. Release signing (for Google Play) is not configured — see [RELEASE.md](RELEASE.md).

## Running locally

```bash
godot --path .
```

Multiplayer — host a game from the main menu (Start → Cooperative) and join it, or run a dedicated server:

```bash
# Dedicated server on port 25565
godot --headless --path . -- --server --port 25565 --max-players 8 --seed 2024
```

Join with `--connect --host <lan-ip> --port 25565`.

## Controls

Desktop:

```
WASD   move            SHIFT  sprint / turbo
SPACE  jump            LMB    shoot
R      reload          F      flashlight
V      camera view     P      phone / inventory
T      chat            E      interact
C      fish (in boat)  M      radio mute
ESC    pause
```

Mobile: floating joystick (left), look (right), and on-screen buttons for shoot, jump, sprint, interact, flashlight, reload, phone, camera view, chat, and pause.

## Version

1.0.0 — see [RELEASE.md](RELEASE.md) for release notes and build/release details.