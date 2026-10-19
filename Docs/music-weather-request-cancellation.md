# Cancelled music authorization and weather completion · #80

19 October 2026. Existing DeviceConnections controller, controlled synthetic providers and fresh private test UserDefaults suites. No real account, subscription, permission dialog, weather service or Home connection used.

## Before-fix evidence

Test-only `6e4d20443cb1339d164ac8ec63002000da693e90` preserves production from published `464486df96b3e0f33314d345c61a43764c1db3fd`. Three tests fail six assertions:

- An explicitly cancelled Music connection still becomes enabled after its outstanding authorization callback returns and sets its local restore-preference flag; it also displays a connected status.
- A cancelled weather refresh's late error sets the failed-fetch marker and replaces the previous good connection status. **The existing weather reading was already preserved**; no newly repaired forecast-data loss is claimed.
- A cancelled new weather read's success already drops returned data and does not enable the source, but leaves “Connecting…” after its busy state has ended. **Late weather success data rejection was already correct**; the remaining failure was status cleanup.

Callbacks are held by continuations, cancelled, then explicitly released. There are no timing sleeps or assumptions that a provider cooperates with cancellation. The Music preference is inspected in a fresh UUID-named suite, not real app defaults. This demonstrates a flag write/read-back, not crash durability or a physical app restart. [Baseline inventory](verification/remaining-source-cancel-baseline-inputs.json).

## Bounded correction

`987f6fdb5573e5d6fb49812b5a6cc6479d74d633` applies the existing same-generation cancellation cleanup to every connection kind, checks cancellation before final connection/preference commit and rejects a cancelled completion's error. Old-generation callbacks still cannot clean up a newer request. Explicitly cancelled current work restores its prior status, or “Not connected” for a new source.

This does not retract an already submitted OS permission request, revoke granted source rights, erase a previously saved requested connection/consent choice or undo the existing queue pause/clear at the start of a Music reconnect. AppModel.connectService deliberately records requested consent before awaiting the provider; that code is unchanged. The fix prevents a cancelled late callback from adding the successful enabled/restore-preference result. It is cooperative cancellation observed at those boundaries, not an atomic OS authorization transaction.

All three before-fix tests pass in the **282-test full Core suite**. A separate external executable directly compiles six exact production Core files with its own provider: **28 assertions pass**, comprising six additional Music/weather checks and 22 retained personal-read/cancellation/permission controls. Its fresh Music defaults suite confirms no newly enabled/restore flag after cancelled permission completion; weather checks retain valid reading/status and reject a cancelled new result without stuck connecting/busy state. [Probe](verification/remaining-source-cancel-native-probe.swift) · [results](verification/remaining-source-cancel-native-results.json).

Five current arm64 SDK builds pass: iOS/macOS/tvOS/visionOS/watchOS. All 190 recorded source/test/resource/project files match before/after, digest `d45cc1defd6373ecb0f9d667dc3ccba910e9a09e935df57a48e59e9414435b55`. Separate baseline/final archives each have 198 source/gate/executed-test entries; native archive has 17. Every entry is read back. [Receipt and hashes](verification/remaining-source-cancel.json).

No view source or interaction changed; **no new UI execution or image is claimed**. Previous UI results remain separately bound to their previous product/test revisions. These gates do not establish live MusicKit permission timing, subscription playback, actual weather transport cancellation, hardware or original parity. The rest of #80's migration/offline/provider/native-alarm matrix remains OPEN. Home stays disconnected.
