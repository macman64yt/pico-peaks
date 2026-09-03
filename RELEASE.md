# Pico Peaks — Release

Current release: **1.1.0**

Builds: **Windows x86_64 (.exe)** · **Linux x86_64** · **macOS (universal .app)** · **Android (APK)** · **iOS (Xcode project — needs macOS to produce .ipa)**

## What's new in 1.1.0 — "Wild Horizons"

- **Meteor showers** — at night a meteor can streak across the sky and crash down,
  leaving a glowing crater with harvestable meteorite ore and star shards. Screen shake
  on the strike.
- **Mountain wolves** — wild wolves patrol in the mountains and hunt the player at night,
  fled back home come dawn. They can be shot and drop meat.
- **Hidden bunkers** — two secret underground bunkers spawn in the world with gun, ammo,
  medical, and star-shard loot to discover.
- **Dirt bikes** — a fast, low-slung off-road bike (boost with sprint) for zipping across
  the valley. Faster than the car.
- **Farming expansion** — six crop plots in the gardens now grow wheat, pumpkin, and corn
  over time; harvesting heals you.
- **New objectives** — added wolf, meteor, bunker, bike, and crop fetch/kill objectives to
  the phone's task list.
- New scripts: `wolf.gd`, `bike.gd`, `crop_plot.gd`, `mineral_pickup.gd`.

## What's new in 1.0.0

- **Windows + Linux desktop builds** — single self-contained executable (embedded PCK),
  x86_64.<br>Note: the Windows .exe is unsigned, so SmartScreen will show a "More info →
  Run anyway" prompt on first launch.
- **macOS universal .app** — single bundle (arm64 + x86_64), unsigned.<br>First launch
  will be blocked by Gatekeeper: right-click → Open → Open to run, then keep. Signing +
  notarization for distribution requires a Mac and an Apple Developer account.
- **iOS Xcode project** — a complete, buildable Xcode project is exported (icons, splash,
  launch screen, Godot engine framework, MoltenVK, embedded PCK, bundle id
  `com.nicholas.picopeaks`, target iOS 15.0). **Building the final `.ipa` requires macOS
  with Xcode** — see the iOS section below.

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
# Linux x86_64 → build/pico-peaks
godot --headless --path . --export-release "Linux x86_64" build/pico-peaks

# Windows x86_64 → build/pico-peaks.exe
godot --headless --path . --export-release "Windows Desktop" build/pico-peaks.exe

# macOS universal .app → build/pico-peaks.app
godot --headless --path . --export-release "macOS" build/pico-peaks.app

# Android APK → build/pico-peaks-android.apk
godot --headless --path . --export-debug "Android" build/pico-peaks-android.apk
```

macOS distribution note: the .app is unsigned, so right-click the zip-extracted app and
choose **Open** the first time (or `xattr -dr com.apple.quarantine /path/to/Pico\ Peaks.app`).
Codesigning + notarization for wide distribution requires a Mac (Developer ID cert +
Apple notarytool).

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

## iOS

A final `.ipa` can **only** be built on macOS with Xcode (Apple's toolchain, and the
engine's engine-framework link step). On Linux the export pipeline produces a complete
Xcode project instead, which you take to a Mac. The iOS preset (`export_presets.cfg`
`preset.3`) is configured for this:

```bash
# On Linux/macOS — generates build/pico-peaks-ios.xcodeproj + frameworks + resources
godot --headless --path . --export-debug "iOS" build/pico-peaks-ios
```

The release ships a ready-to-build zip (`pico-peaks-ios-project.zip`) containing the
Xcode project, Godot engine framework, MoltenVK, icons, splash, and embedded PCK.

To produce an .ipa on a Mac:
1. Install Xcode and open `pico-peaks-ios.xcodeproj`.
2. In the **Signing & Capabilities** tab, select your Apple Developer team. The preset
   currently contains a placeholder team id (`ABCDE12345`) — replace it, and update
   `application/app_store_team_id` in `export_presets.cfg` before re-exporting if you
   rebuild from source.
3. Set a unique bundle id (`com.nicholas.picopeaks` is a placeholder — change to your
   own reverse-domain before App Store submission) and a signing certificate +
   provisioning profile.
4. Product → Archive, or build to a connected device / simulator.
5. Export the archive to an .ipa (or upload via Transporter/Xcode Organizer).

Notes:
- iOS requires an active Apple Developer account (free tier runs on your own device;
  the $99/yr membership is needed for TestFlight / App Store distribution).
- `version/code` (CFBundleVersion) must be incremented for every upload.

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