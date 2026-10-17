# HomeView

Independent native Swift/SwiftUI prototype for a shared home display. This project is not affiliated with Apple and is not a complete reproduction of the reference product.

Public source snapshot, 17 October 2026. Includes the spatial face editor, separate modular layouts, CPU fluid simulation, original Metal glyph material, local everyday apps and opt-in public-system adapters. Apple Home is deliberately disconnected.

## Build

Requires macOS, Xcode 27 and its installed SDKs. No third-party Swift packages.

```sh
python3 Scripts/generate_project.py
open HomeViewReplica.xcodeproj
swift test --scratch-path "$HOME/Library/Developer/HomeViewPublicBuild/CoreTests"
python3 Scripts/build_platforms.py
```

The default build cache is under the current user's Library/Developer/HomeViewPublicBuild. Override HOMEVIEW_BUILD_DIR to use another suitable volume. Choose your own signing team and bundle identifier for physical-device use. MusicKit needs appropriate capabilities and service provisioning. Nothing in this repository provides credentials or account access.

## Current scope

- iPad and iPhone share the square display UI. Mac, TV and Vision targets share adapted views. Watch is a reduced companion.
- Editable faces and per-face complication persistence, photos, calendar, weather, timers, alarms, recipes, browser, music, mirror and local communication simulations.
- Opt-in EventKit, MusicKit, selected-photo/shared-album import, public weather, on-device Speech and explicit Messages/FaceTime system handoffs where supported.
- Mock smart home only. No real home discovery. No automatic message sending or calls.

## Parity backlog

[Complete backlog](Docs/backlog.md) and [105-reference-function coverage](Docs/function-coverage.json). Issues distinguish missing implementation, visual calibration, hardware acceptance and unavailable public APIs. Additional watch-face experiments and universal-platform adaptations are not requirements for the core iPad parity target.

## Publication differences

The private development baseline contains reference artwork and extracted OS digit contours. These are **not included**, nor are private research, original screenshots, test logs or previous Git history. This snapshot uses original geometric artwork and original seven-segment Flow glyphs. Public visuals therefore differ from the private research build. See [publication notes](Docs/publication.md).

No full visual, hardware or system-service parity is claimed. Existing historical test counts do not certify this modified public snapshot. Fresh verification is recorded separately in Docs/public-verification.md.

## Rights

No open-source license has been selected yet. Public visibility alone does not grant a license. Third-party product names identify compatibility or research targets. Do not upload proprietary reference assets or extracted operating-system code.
