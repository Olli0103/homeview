# Local MockHome command writes · #80

19 October 2026. This repairs the existing **local MockHome value**, not Apple Home, HomeKit discovery or real devices. HMHomeManager is not constructed, and no source account, message, system alarm, microphone or camera operation is part of this gate.

## What actually failed

Actual AppModel at clean `ce2582324792b8706426037be7b85e27a0a5c4b1` was compiled with only its owned test-store URL accessor. Fresh UUID stores were saved successfully, then a checked nonempty directory occupied the snapshot file path to cause a genuine atomic-write failure.

Seven of ten native scenarios failed unchanged-Snapshot assertions: direct mock temperature, brightness, entry light and compound scene, plus explicitly sent assistant temperature/light/Good Morning commands. Unsaved values and the local completed-action audit remained changed in RAM, while original disk bytes and restart state were unchanged.

**The assistant’s error replies were already correct in all three assistant cases.** No false success reply was observed; that hypothesis was not turned into a new fix. Invalid-value, unauthorized Good Night and offline rejection controls already passed with no mutation. Baseline: ten scenarios, seven failed assertions, three rejection controls passed. [Preserved baseline results](verification/mock-command-baseline-results.json). Archive: 133 entries, SHA-256 `2731b9091d5b56d5df7e6ee76bd08efe3482527155de4d8a9a5b0aa96203d7cb`, every entry read back.

## Repair

Product commit `420cdd78699591e9bd940db031f552c9b5c259e7` first rejects a read-only store, then validates/transacts on a copied local MockHome. Only the existing local commit/rollback helper installs that candidate. Failed persistence restores the previous Snapshot, including its audit. No command grammar, authorization rule, assistant reply, AI path or demo-plan execution logic changed.

The local command path contains no external device operation to undo. This must not be confused with a transaction spanning actual Home/AlarmKit effects. The HomeKit adapter remains deliberately unavailable. Security/offline/value prechecks are unchanged; Good Night is not granted to an unauthenticated demo profile.

## Bound evidence

Source pin: `420cdd78699591e9bd940db031f552c9b5c259e7`; 189 code/test/resource/build-input files, digest `eaab9c2a479583e5fa8d758db24a02ae26de7808689b045c969011479505464f`.

- **Ten actual native scenarios / 126 assertions passed.** Failed writes preserve Snapshot, original bytes and canary; error replies are accurate. Explicit retry after restoring the owned path saves exactly once, produces one expected audit entry, keeps other Snapshot fields unchanged and survives another restart. Rejected requests remain rejected without mutation.
- **Six UI executions passed**, three methods on both iPad/iPhone: the version-99 read-only thermostat retains the displayed value; an explicitly sent local assistant command still acts; local state and a selected synthetic gallery survive process restart in an owned store. Zero failures/skips/runtime warnings. This is not a full UI suite or a real-library test.
- Source and all 22 compiled/launch inputs are unchanged through the UI run; installed app bytes read back. Two exact owned version-99 files were independently read back after UI/restart and still contain the original 13 bytes.
- **Five final arm64 SDK builds passed:** iOS, macOS, tvOS, watchOS, visionOS. Builds are not physical-device or original-service acceptance.
- Six PNGs decoded, two contact sheets reviewed, four read-only-state images selected. No pixel-equality or original-geometry claim.
- All 66 Core/CoreTests files remain byte-identical to the historical pinned 264-test PASS. No new full Core run is claimed.

[Receipt and images](verification/mock-command.json) · [native results](verification/mock-command-native-results.json) · [native probe](verification/mock-command-native-probe.swift) · [owned accessor](verification/persistence-write-model-accessor.swift).

Native archive: 134 entries, SHA-256 `ef084a00eb663183e33711b66ec46faad5bce428d92ba7dd60d59196faa32d73`. UI source/compiled archive: 211 entries, SHA-256 `9fe5eb1de5c9fc27130aaf4fe3881b5252f94d5641173f97d5c4627d1db19da4`. All entries read back, exact clean native source pin verified. Documentation-only delivery is checked against the tested source manifest, not relabeled as another test run.

This supplements [local editor/recipe writes](persistence-write-boundaries.md) and [foreground timer writes](timer-write-boundaries.md). **#80 stays OPEN** for the remaining migration/offline/lifecycle/write matrix; registered native alarm reconciliation and physical behavior remain separate. No Home connection was enabled.
