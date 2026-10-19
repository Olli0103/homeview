# Local photo layout writes · #80

19 October 2026. Synthetic geometric images and owned UUID stores only. No photo library/account, camera, microphone, biometric identification or Apple Home operation.

## Reproduced failures

Actual AppModel at clean `0eccf62e9d1d650f1fbaf38d43f26c52e04aef58` saved a generated geometric PNG through its normal setPhoto path. A checked nonempty directory then occupied the snapshot file path to force actual atomic-write failure.

Three native scenarios failed ten assertions: changing an existing adjustment left unsaved adjustment/composition values; adding an adjustment to a 100-entry cache also displaced a previous entry; opening the photo face changed selected face and route despite failure. Original JSON, image bytes, displayed image and restart-from-original checks already passed. This was a layout/metadata/navigation defect, not newly repaired corruption of the image file itself.

[Original results](verification/photo-write-baseline-results.json). Baseline archive: 112 entries, SHA-256 `c92f12d42b413f495f4d5213d089a276c68c462e9fcf1bf2fdef0011e8465594`, every entry read back.

## Repair boundary

Product `f489aef5982df122c5a4770917234e78f2650642` places adjustment insertion/eviction within the existing commit/rollback helper. Composition is recomputed only after successful save. Photo-face selection is committed before route changes. Cache limit and existing lexical eviction policy are unchanged; this does not claim a new recency algorithm, crop algorithm, segmentation model or original pixel match.

The existing gallery-rotation binding also uses that same helper instead of directly mutating then ignoring persist's result. Its normal UI off/restart behavior is separately tested. Rotation was not a fourth reproduced native baseline case.

## Acceptance at the tested scope

Production/native/SDK pin: `f489aef5982df122c5a4770917234e78f2650642`. Final test-only interaction pin: `e20c843b0dcd94789266f3d4b8d0a95454ad687e`; the sole later changed source is HomeViewUITests.swift. All production files remain unchanged. Final 189-file manifest digest: `55e2686bae524db87f57429900730a2ab0b55d13fe3ebe957c1406639d4edbfc`.

Three actual native scenarios / **55 assertions passed**. Each genuine failed write preserves complete Snapshot, current adjustment/composition, prior cache entries, route, original JSON, image bytes and displayed image. Restoring the owned path and explicitly retrying writes the exact expected adjustment or photo-face choice; composition updates only after successful save, cache stays bounded, original image bytes remain equal, and a second restart reads the committed metadata/photo. [Native results](verification/photo-write-native-results.json), [probe](verification/photo-write-native-probe.swift), [owned accessor](verification/persistence-write-model-accessor.swift).

| UI checkpoint | Passed | Failed | Scope |
| --- | ---: | ---: | --- |
| Product `f489aef`, both devices | 5 | 1 | Clock position/restart and gallery rotation/restart pass; iPad crop slider not found hittable |
| Targeted diagnostic `d5bd711`, both devices | 1 | 1 | iPad automatic framing remains on, slider absent; actual image shows clipped switch |
| Measured interaction `e20c843`, both devices | 2 | 0 | Same crop/reset outcomes, controls fully within viewport and switch explicitly off |

Ten UI executions, eight successful, two historical failures retained; three unique methods. Only the affected crop method was rerun on the final test revision. Other successful cases remain separately pinned to the original product checkpoint, not relabeled as a complete final-revision suite. Every checkpoint has zero skips/structured runtime warnings, frozen 189-source/22-compiled-input manifests and installed-app byte read-back.

The diagnostic did not establish a crop/persistence regression: its iPad switch value stayed 1 and no slider existed; iPhone value was 0 with a slider. The actual iPad screenshot shows the automatic-framing control still clipped below the rounded viewport, despite the old isHittable-only guard. The existing measured visibility helper now reveals the full control before tapping; an explicit off-state assertion precedes slider lookup. Slider and Reset use the same full-visibility rule. Manual crop/full-framing outcome assertions were not removed. A separate intermediate diagnostic build was prepared but not executed before its absent-element logging was guarded; it is not counted as a UI execution.

Five final arm64 SDK builds passed at the production pin (iOS/macOS/tvOS/watchOS/visionOS). No relabeled native/SDK rerun after test-only changes. All 66 Core/CoreTests files remain byte-identical to the historical pinned 264-test PASS; no new full Core run.

24 PNGs decoded; four contact sheets and the individual diagnostic failure image reviewed; nine selected images include the explicitly historical clipped-switch capture. Two owned rotation stores directly confirm rotatePhotos=false and two gallery IDs after restart without selecting the gallery again. Selected images establish these tested states, not original geometry, general contrast/accessibility or pixel equivalence.

[Receipt, separate checkpoints and images](verification/photo-write.json). Native archive: 113 entries, SHA-256 `9ba62eb221b9139cfa59708131dcb1a49aec31e5a41858f7965038a9bc895e96`. UI archives each have 211 source/compiled entries; exact separate hashes are in the receipt, all entries read back. The native policy and final test source manifests remain distinct.

The read-only unknown-version loader deliberately does not restore private selected-photo/cache data. Tests do not override that protection merely to display a photo in a future-version UI fixture. Valid-photo failure behavior is tested at the actual AppModel/file boundary instead. Original algorithm/parity, real library permission behavior, hardware and the rest of #80 remain unaccepted; #80 stays OPEN. Apple Home remains disconnected.
