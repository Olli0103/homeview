# Hearthside performance repair — 2 November 2026

The owner reports unusably poor performance in TestFlight 0.1.0 (1).
The exact device and affected interactions have not yet been supplied. These
changes address demonstrated rendering costs; they do not establish that the
reported physical-device problem is completely resolved.

## Changes

- Personal and All Apps menus no longer run their decorative face timelines.
  Their blurred face remains visible, but Flow also deactivates its simulation
  owner rather than merely suppressing display updates. Returning to the face
  resumes animation. Foreground faces and weather screens retain motion.
- Paused motion uses a static view rather than an animation timeline.
- Prism lighting skips layers outside their antialiased coverage.
- Weather skips the sixteen volumetric steps below its zero-opacity cloud band,
  retaining the original sky and solar glow.
- Flow builds one RGBA byte buffer instead of two temporary arrays per pixel
  on MainActor. The output bytes are unchanged.

## Measured scope

Actual Apple M1 Max, isolated optimized Metal dispatches at 1200×1200, ten timed
samples after two warmups per case. These are **not SwiftUI frame times, energy
measurements, or measurements from the owner's iPhone/iPad**.

| Work | Before | After |
|---|---:|---:|
| Weather, four time/day/night cases | 15.48–15.83 ms | 8.26–8.68 ms |
| Prism, four time/theme cases | 0.54–0.98 ms | 0.17–0.40 ms |
| Flow RGBA preparation, 128×128, 200 iterations | 0.916 ms | 0.049 ms |

The Flow comparison requires exact byte equality. All eight shader output pairs
were compared as half-float channels. Two weather cases are byte-identical;
remaining cases have a maximum channel difference of 0.00048828125 after Metal
compilation, affecting fewer than 0.015% of channels per case. No numerical
identity is claimed for these shader cases. The actual decoded prism and weather
outputs were inspected; no artwork, typography or layout was replaced.

Two focused UI tests pass on each iPhone 18 Pro and iPad Air 11-inch simulator:
Flow → Personal → All Apps → Flow resumes; existing reduced-motion and night-mode
guards remain valid. Simulator tests prove those paths, not physical fluidity.
All five final SDK builds pass at the unchanged source pin. The final iOS pass
used the builder's existing metadata clean/build recovery; the earlier SDK pass
predated the last Flow-buffer edit and is not substituted for this final gate.

## Prepared internal beta

Signed archive and App Store distribution IPA **0.1.0 (2)** are prepared locally.
Host/widget IDs, build numbers, strict signatures, distribution profiles,
`get-task-allow=false`, matching archive dSYMs and internal-only distribution
were checked. IPA SHA-256:
`3501929794cbe2662f51003f92a429f66d6d2c0a417fb080d6ecc0aa18c61179`.

**Not uploaded / not Ready to Test.** A fresh App Store Connect navigation
redirects to login with `authResult=FAILED`. The owner needs to restore the
existing Chrome login, then the next unused build number must be reconciled
before Apple validation/upload and Owner-group read-back. No new API key was
created; the first release's temporary key remains revoked. The initial local
archive verifier wrongly expected the widget's name to equal the host's;
the established `Hearthside Timers` name was verified without changing/rebuilding
the product. Private release receipts:
`/Volumes/Extern/OpenClaw/releases/hearthside-performance-20261102/`.

Private raw benchmarks, commands, source manifest, GPU output matrices and native
test bundles: `/Volumes/Extern/OpenClaw/qa/hearthside-performance-20261102/`.
No real Home discovery, personal-provider access, dependency addition or new
background service is involved. Physical frame-time/thermal acceptance remains open.
