# Pico Peaks — Release

Current release: **1.0.0**

Builds: **Windows x86_64 (.exe)** · **Linux x86_64** · **Android (APK)**

## What's new in 1.0.0

- **Windows + Linux desktop builds** — single self-contained executable (embedded PCK),
  x86_64.<br>Note: the Windows .exe is unsigned, so SmartScreen will show a "More info →
  Run anyway" prompt on first launch.

- **Mobile (Android) support** — floating joystick, touch look, and on-screen buttons
  (shoot, jump, sprint, interact, flashlight, reload, phone, camera view, chat, pause).
- **Mobile UI scaling** — baked into layout/hit-tests so buttons land where they're drawn;
  touch controls no longer disappear when you touch the screen.
- **Mobile multiplayer** — network client builds touch controls and uses the touch joystick;
  a LAN client can move, look, and interact.
- **Pause / chat / phone** reachable from touch screen without a keyboard.
- **Netcode fixes** — correct `view_toggle` action routing, polled touch actions (shoot,
  reload), and cleared input state on pause.
- **App icon + Android adaptive launcher icons**.
- **Rebranded to 1.0.0** (removed "BETA" branding; version now consistent across project,
  HUD, menu, phone System screen, and Android package).

## Versioning

Version lives in several places — keep them in sync on release:

| Location | Field |
|---|---|
| `project.godot` | `config/version` |
| `scripts/main_menu.gd` | subtitle string |
| `scripts/world.gd` | HUD watermark string |
| `scripts/phone.gd` | System screen `_sys_ver` |
| `scripts/debug_menu.gd` | `VERSION` constant |
| `export_presets.cfg` (Android) | `version/name`, `version/code` |
| `scripts/server_wrapper.sh` | binary name (`build/pico-peaks-<ver>`) |

## Building

Requires the Godot export templates matching the engine version (4.7.1) and, for Android,
the Android SDK + OpenJDK configured in `editor_settings-4.7.tres`.

```bash
./build_release.sh   # exports Linux release + Android debug-signed APK
```

Individual exports:

```bash
# Linux x86_64 → build/pico-peaks-1.0.0
godot --headless --path . --export-release "Linux x86_64" build/pico-peaks-1.0.0

# Windows x86_64 → build/pico-peaks-1.0.0.exe
godot --headless --path . --export-release "Windows Desktop" build/pico-peaks-1.0.0.exe

# Android APK → build/pico-peaks-android.apk
godot --headless --path . --export-debug "Android" build/pico-peaks-android.apk
```

The player-visible APK is currently **debug-signed**, which is fine for sideloading and
distribution as an installable package, but not accepted by Google Play.

## Android signing (Google Play)

To publish to Google Play you need a self-owned release keystore. Do this once:

1. Create a keystore (keep this file + passwords **private** and backed up — you cannot
   update the Play listing without the same key):
   ```bash
   keytool -genkey -v -keystore picopeaks-release.keystore \
     -alias picopeaks -keyalg RSA -keysize 2048 -validity 10000 \
     -dname "CN=Pico Peaks, O=Pico Peaks, C=US"
   ```
2. Add the Android preset options to `export_presets.cfg` (`[preset.1.options]`):

   ```ini
   keystore/debug=""
   keystore/release="<absolute path to>/picopeaks-release.keystore"
   keystore/release_user="picopeaks"
   keystore/release_password="<store password>"
   ```
3. Export a signed debug-free release:
   ```bash
   godot --headless --path . --export-release "Android" build/pico-peaks-android-release.apk
   ```
4. `version/code` must be **incremented for every upload** to Google Play.

## Dedicated server

```bash
# Terminal
godot --headless --path . -- --server --port 25565 --max-players 8 --seed 2024 --ram-mb 2048 --server-name "Pico Peaks Server"
```

The in-game **Server Launcher app** (`--launcher`) wraps this via `scripts/server_wrapper.sh`
and writes PID/log under `/tmp/opencode/`. Point `server_wrapper.sh` at your
`build/pico-peaks-<ver>` binary.

## CLI options (developer/test)

Passed after `--` with `godot --path . -- <args>`:

- `--server`, `--connect`, `--host`, `--port`, `--max-players`, `--seed`, `--ram-mb`,
  `--player-name`, `--server-name`, `--net-test`, `--night`
- `--launcher` (Server Launcher UI)
- `--shot`, `--walk`, `--drive`, `--ztest`, `--sanity`, `--rooftest` (auto-capture tests)
- `--fx-sdfgi`, `--fx-volumetric`, `--fx-glow`, `--fx-ssr`, `--fx-ssao`, `--fx-dof`,
  `--fx-autoexp`, `--fx-fog` (force toggles)

The in-game console (backtick `` ` ``) is available to all builds and exposes developer
commands including `/give`, `/time`, `/quality`, `/tornado`. Disable it before a public
release by gating console construction in `scripts/world.gd` behind
`OS.is_debug_build()` if desired.