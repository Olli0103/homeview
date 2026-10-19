# Foreground timer and local alarm writes · #80

19 October 2026. Bounded local-write repair, not a complete #80 or AlarmKit acceptance. No system alarms, accounts, microphone or Home operations in these checks.

## Reproduction

Actual AppModel from clean `60115ecbadc7f5b66511ff031b58e7481f62dd7e` was compiled with only an accessor exposing its owned UUID test-store URL. A valid Snapshot was written first. A nonempty directory with a checked canary then occupied the snapshot file path, causing the actual atomic write to fail.

All six scenarios failed their unchanged-Snapshot assertion: timer pause, resume and removal; local alarm switching in both directions and removal. Original bytes, canary, selection, empty native-ID sets and restart-from-original checks passed. This demonstrates unsaved **in-memory** changes, not an erroneous successful disk write. The baseline alarm cases selected the existing default 07:00 demo alarm, not the newly appended 10:30 alarm; their enable/disable labels were reversed relative to that default's initial state. Both toggle directions were exercised; this qualification is retained rather than rewriting history.

Baseline archive: 121 entries, SHA-256 `1aacd0d37c2d63a397e8ad954ca4abab596893cda44927192b36b12ee2932c0e`, all read back.

## Repair

`66f6ad0cb5e4fe9bb6c88b4c2c93e49db047231e` changes only AppModel. The existing local commit/rollback helper now owns pause/resume/remove and local alarm changes. A failed write restores the full previous Snapshot. A permitted alarm enable is committed before scheduleNativeAlarm can be queued. Add-timer/add-alarm already had separate failure rollback and are not presented as newly repaired.

Already registered AlarmKit pause/resume/cancel branches retain their existing system-operation ordering and remain explicitly separate: rolling back an in-memory object cannot undo an already performed OS operation. Native-operation/disk reconciliation and asynchronous schedule-completion persistence are **not fixed or accepted** by this local gate. No new system-alarm atomicity is claimed. Those boundaries and physical delivery remain open.

## Final gate

Code/source pin: `66f6ad0cb5e4fe9bb6c88b4c2c93e49db047231e`; 189 source/test/resource files, manifest digest `9ffbda97eaf9479200564f0f8dd4f2a8be7e4fd7b138b8bdc60c40d56cea40a7`.

- Six actual native AppModel scenarios, **78 assertions passed**. Genuine failed write preserves Snapshot, selection, original bytes and canary. Restoring only the owned fault path allows an explicit retry with the expected effect, exact stored bytes and second restart. Corrected alarm fixtures target the newly appended alarm and separately verify the original peer remains unchanged. Native IDs stay empty.
- Six UI executions passed: three existing methods on both iPad/iPhone. They cover pause/resume/delete, independently running/paused peers and actual process restart from an owned store without reinjecting the fixture. Zero failures, skips or runtime warnings. Source and all 22 compiled/launch inputs remain unchanged; installed app bytes read back.
- Five final arm64 SDK builds passed: iOS, macOS, tvOS, watchOS, visionOS. This is compilation on the other targets, not physical alarm delivery.
- 26 PNGs decoded, two contact sheets reviewed, ten selected images. Timer readouts change with real elapsed time; no pixel-equality or original-geometry acceptance is claimed.
- All 66 Core/CoreTests file bytes remain identical to the historical pinned 264-test PASS. No new full Core run is invented.

[Receipt and images](verification/timer-write.json), [native results](verification/timer-write-native-results.json), [probe](verification/timer-write-native-probe.swift), [store accessor](verification/persistence-write-model-accessor.swift). Native archive: 122 entries, SHA-256 `640c0fb853d3675b723d1dd774aab6961e6320b7bc61ce526f39037de93fd83c`. UI source/compiled archive: 211 entries, SHA-256 `ae2caa1b5648d37397eca569bab269d48bf03d554b8af132340dd9270e1d03b4`. All archive entries read back.

## Preserved harness failures

The first post-fix native probe passed the three timer scenarios, then failed its requested-effect assertion for the alarm. All actual rollback/save/restart checks passed. It had targeted the existing disabled default alarm and assumed there was only one alarm, despite adding a second. The newly corrected probe selects the intended appended alarm, uses the actual count and requires unchanged peer state. No product code was changed to satisfy that assertion. Two remaining cases were not run by the first probe. Its 113-entry archive remains separately bound (`3a9c5248220ec9c1f712310c65ed960afb9b95e0a5333ce74fb0ef39ba2f31c3`).

The first UI runner preparation collided with the native gate's existing output directory and stopped before any UI test. A distinct fresh `timer-write-ui` checkpoint was used; the failed preparation is not counted as a UI execution. Previously sealed prefixes were not deleted or reused.

This supplements [the earlier local-write and recipe-crash repair](persistence-write-boundaries.md). #80 remains OPEN for the rest of its migration/offline/lifecycle/write matrix; no universal persistence, original-service or hardware PASS.
