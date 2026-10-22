# Day/night states: explicit policy and readable face palettes

22 October 2026 · [#13 / FACE-07](https://github.com/Olli0103/homeview/issues/13).

## Policy: observed original versus our fallback

The reference inventory distinguishes observed states from unknown switching rules. Snoopy's day/dark references UI03/UI06 and sampled animation exist, but licensed scenes/timelines are missing under #14. No Snoopy actor or automatic original time/ambient-light threshold is invented here. Other original face-specific night permissions, illumination thresholds, complete transitions and character schedules are not publicly established.

The current replica offers an **explicit manual red night override** for its 14 available faces: ten core layouts plus four separately optional Watch-inspired layouts. It is an app preference, not the OS color scheme, presence detection, ambient-light permission or physical display dimming. It stays chosen through local date, time-zone and DST changes until explicitly switched off. Missing ambient inputs leave that manual choice intact; there is no hidden guessed Auto schedule.

Displayed dates/times still use their existing IANA display zone. Weather uses its source's available observation/day fields and labels demo, unavailable or stale values separately; it does not grant another source or pretend that the global manual override is Apple's original weather algorithm. Date-dependent background/clock states and reduced-motion paths retain their existing controllers. Unavailable original rules remain explicit gaps rather than inferred night transitions.

## Available-face policy matrix

These are replica permissions, not asserted original per-face rules. All accept the same manual On/Off preference; day remains the existing rendered state.

| Current faces | Manual night / reduced rendering |
| --- | --- |
| Modular | Dark surface, bright date/clock/music/weather data; existing explicit source labels |
| Watch Modular, Infograph Modular, Modular Duo, Modular Compact | Existing black complication layouts through the full red viewport; optional layouts kept separate from original inventory |
| Home Modular, Home Modular Clock | Dark matte tile/circle surfaces instead of light native glass, existing mock data/actions |
| Photos | Same selected image/crop/mask dimmed; same own clock glyphs opaque, no invented subject extraction |
| Weather | Dark face with opaque existing temperature type; no guessed ambient sensor or changed weather observation |
| Calendar | Dark surface, subdued background day, readable month/weekday/42 date cells and Today marker |
| Flow | Same own Solid/Stencil geometry at fixed morph phase, opaque ink; fluid/material work bypassed in this state |
| Fade, Numerals | Dark surface, bright hands/numerals; Fade retains its time-dependent number window |
| Home Camera | Same labeled synthetic stills; dark caption backing, no real feed/capture |

The existing MotionTimeline continues to pause phase animation for inactive/reduced states; the main clock's semantic time is not frozen by Reduce Motion. The deterministic run uses the explicit test Reduce Motion option, not a claim that physical OS assistive settings were exercised. Unobserved original per-face exclusions and auto-switch thresholds remain unknown; Snoopy has no accepted substitute.

## Reproduced readability failure

A full red viewport can pass the existing hue test while containing nearly invisible data. The unchanged Calendar night renderer produced dark red dates over a similarly dark large background one, against a bright red surface. A three-render native test captures actual output, identical layout with date ink hidden, and white-control date ink. The ordinary day path of that diagnostic-only revision remains pixel-identical on both devices.

Before changing product colors, the external checker fixed a **3:1 minimum for large date text**, a 95%-observed-white-delta interior mask, at least ten interior samples per cell, and the existing whole-viewport hue criterion. On both devices **41 of 42 date cells contain sampled ink below 3:1**, worst ratio **1.0563**. Those failures and actual before images are retained. A passing UI interaction count is not accepted as a passing contrast result.

The Calendar night palette now has a dark background, a subdued large background date, bright month/weekday/current-date ink, distinct adjacent-month ink and a dark Today circle. Flow and Photos now use opaque versions of their same own glyphs at night; Weather uses its same system temperature typography without the night glass shader. Home surfaces, Modular, Fade and Numerals use dark night surfaces and bright semantic data. Camera captions have a near-opaque dark backing. Photos dims the same selected image and its existing actual foreground mask, without changing crop, source or occlusion. Flow skips its fluid/material timeline in this explicit matte state; no energy-saving measurement is inferred. Only night rendering changes; layout, digits, selected date, locale, clock preference, masks and source access are unchanged. The outer red treatment still includes the complete logical viewport, overlays and activity surfaces.

The white/hidden controls are gated by `--uitesting`, never imported as font assets or used as production content. Their screenshots are diagnostics, not reconstructed font alpha/contours. Relative luminance is measured in decoded PNG RGB; this is a software gate, not calibrated-display, physical VoiceOver or complete accessibility certification.

## Acceptance evidence

Final source `9e3c40b`: **ten successful UI executions** (five methods on each simulator), **five SDK builds**, 28 full day-state pairs pixel- and PNG-byte-identical to the pre-palette checkpoint. The unchanged large-date gate has zero failing cells, minimum **3.2991:1** on both simulators; the unchanged whole-viewport hue gate has zero leaks across 28 night face states. Core/CoreTests/package bytes equal the prior 375-test checkpoint; no new Core run is claimed. Actual final night contact sheets on both sizes were inspected, not accepted solely from hue. The first broad candidate build attached the new argument to the wrong SwiftUI call and failed compilation; it executed no UI assertions and is retained separately.

The final receipt records the 14 available-face native matrix, source/compiled/launch binding, own screenshots and exact contrast/hue output. Three timestamp/zone anchors cover local New Year in Kiritimati, the Berlin spring jump and the repeated Berlin autumn hour. They are distributed across the face matrix, **not a claimed 14×3 Cartesian run**. A separate owned UUID test keeps the manual choice through restart/DST, turns it off, and confirms the saved off state after another launch.

[Receipt](verification/night-state-acceptance.json) · [final source](verification/night-state-source.json) · [own night pictures](screenshots/night-state-acceptance). Earlier [primary-red correction](night-primary.md) remains a dated separate result. No changed RGB/hue tolerance, no new sensor, real Home, account, capture, alarm, call or message.

Exact original/night character behavior, licensed Snoopy, unobserved variants, physical display/energy characteristics and assistive technology remain their respective open gates; F014/F021 original parity is not inferred from this replica's manual state policy.
