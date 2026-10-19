# Failed local edits and recipe-unpin crash · #80

19 October 2026. A bounded repair within #80, not a closure of its full migration/offline/lifecycle matrix. Synthetic local data only; no account, Home, system alarm, real message or permission operation.

## Reproduced failures

The native baseline compiled actual production AppModel and all production dependencies from clean `ec2a92ea3efb344bc1ec7c1dbc2b73088bacd0b7`, adding only an accessor for its owned test-store URL. It used fresh explicit UUID test roots, a successfully written snapshot and a nonempty directory at that snapshot's file path to cause a genuine atomic-write failure. It did not simulate a false return from persist.

Eight scenarios completed with ten failed assertions: pinning, next face, adding/removing a world city, replacing a recipe, local messages/reminders and first-time demo profile creation retained unsaved displayed state. Recipe replacement also cleared an active cooking context; failed profile creation still selected the new profile.

The ninth scenario, unpinning an existing recipe, aborted on Swift's simultaneous-access check. Its removeAll closure read computed recipe while mutating the same observed Snapshot. This is a native controlled reproduction, not an observed physical-device crash. The aborted scenario's owned fault directory was identified and its preserved snapshot restored separately before continuing; the first runner and original failure remain retained. No normal user store was touched.

Baseline archive: 132 entries, SHA-256 `5e4cb436ebede8e71a49a309a9779fa7077d530c3754b3edf2d9cf9de14c82d6`, every entry read back.

## Repair boundary

The existing updateLocalControls commit/rollback path now returns its actual success and rejects a read-only store before mutation. These local callers reuse it: recipe pin/unpin/selection, world-city add/remove, face gestures and editor selections/style/slots/Flow options, personal-home layout edits, local demo messages/reminders and creation of demo profile content.

Unpin captures the selected recipe before the Snapshot's mutating access. Failed recipe selection leaves cooking/handoff context unchanged; import/library navigation and clearing candidate choices occur only after a successful save. A new demo profile is selected only after its initial content is saved. Existing source authentication and lock revocation remain separate; this is not household identification or device authentication.

Local demo-message/reminder entry drafts are cleared only on successful commit. These methods do not send a real message or write an OS reminder. Existing setter paths also roll back. Done in the face editor closes the editor; each actual edit already has its own commit boundary, so Done is not a second attempt to save an earlier failed edit.

## Native and UI gates

Native policy/mutator code: `accabd6c11121dc1d5e424ffa207672048878171`. Final picker presentation and SDK/UI code: `2c964b6a9993b89de9db63a36a24f5a61f9ff90b`. Final source: 189 files, SHA-256 manifest digest `f31f74ae48c7a54db83e4c042ebb23b495690c45e64f5c2d2dea3d4bf7a39a69`.

Eleven actual AppModel scenarios/103 assertions passed. Every failed-write scenario verifies unchanged in-memory Snapshot, visible failure, original saved bytes and fault canary unchanged, then restart from the original. Removing the fault and explicitly retrying must change state, save the exact Snapshot and survive a second restart. Recipe context and new-profile selection have additional failure/success assertions. The two added cases exercise Flow settings and local entry-draft commit callbacks. This is an actual native AppModel probe, not a reimplemented model. The probe's only extension exposes its owned store URL.

Native archive: 137 entries, SHA-256 `19c2dd84ce1cce1fc89d9f38bccbf5cfc2780869c004c3da1c3634db57a6a7da`, all entries read back. [Native results](verification/persistence-write-native-results.json), [probe](verification/persistence-write-native-probe.swift), [owned model accessor](verification/persistence-write-model-accessor.swift).

| UI checkpoint | Passed executions | Failed executions | Meaning |
| --- | ---: | ---: | --- |
| Policy `accabd6`, both devices | 4 | 2 | Recipe failure and pin/unpin/restart pass; picker-retention assertion fails |
| Diagnostic `57ec676`, both devices | 4 | 2 | Actual image/tree plus bounded wait confirm root alert dismisses picker; current Date/Mist remain unchanged |
| Picker fix `2c964b6`, both devices | 2 | 0 | Failure presented within picker; picker retained, original slot/style unchanged, original version-99 bytes preserved after restart |

These are 14 executions of three unique methods, with ten successful executions and four retained historical failures. Only the final affected picker method was rerun on the final revision; the unchanged recipe component's latest four successful executions remain separately bound to the preceding checkpoint. They are not relabeled as a complete final-revision suite. All checkpoints have zero skips and runtime warnings, frozen source/compiled inputs and installed-app read-back.

The first failure was not dismissed as a timing issue: even a five-second wait failed. The diagnostic accessibility tree and image showed the main editor with Date/Mist intact but no picker. A locally presented error inside the picker now preserves that editing context; model error text is transferred to this local alert rather than silently dropped. The failed expectation was retained.

Five final arm64 SDK builds passed: iOS, macOS, tvOS, watchOS and visionOS. Native product remains at its policy pin; only the FaceEditor error presentation and test diagnostics changed afterward. AppModel, other mutator sources and all 66 Core/CoreTests files are verified unchanged. Historical pinned 264-test Core PASS is not a new run.

36 PNGs decoded; four contact sheets from diagnostic/final checkpoints reviewed and ten images selected. Picker images capture the native presentation immediately after alert dismissal, not a claim of stable original pixel geometry or full-sheet viewport containment. Six owned stores from the first UI checkpoint were independently read back: four future-version files byte-exact and two positive recipe stores unpinned after restart. Both final picker stores again preserve exact `{"version":99}` bytes. No normal store was enumerated or modified.

[Full receipt and selected images](verification/persistence-write.json). Each of the three UI input archives contains 211 entries, all read back; their independent hashes remain in the receipt. Earlier binaries and failures are not overwritten or retroactively repinned.

A supported legacy/corrupt migration fixture, late provider response, gallery grant/cache and system-alarm behavior are not newly certified by this bounded repair. Historical evidence remains in [state-recovery](state-recovery.md), [face recovery](face-configuration-recovery.md), [music search lifecycle](music-search-lifecycle.md) and [music playback lifecycle](music-playback-lifecycle.md). This is not a full #80 PASS, visual/original parity or physical-device acceptance. #80 stays OPEN; Apple Home stays disconnected.
