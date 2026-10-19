# Cancelled personal requests · #80

19 October 2026. Existing DeviceConnections controller, controlled synthetic providers, no personal source/account access or Home connection.

## Before-fix reproduction

Test-only `34bc072797db3bf2f9913b019b8870fb45604ff1` preserves production from published `bd53901810ae2a1ecf056a1747f9b3d857d108d0`. Six tests fail with **21 assertions**: a cancelled calendar/reminder read still installs its returned records; an already-cancelled task can still invoke valid reminder add/complete/remove operations; cancellation after a submitted write starts a further read-back; cancellation during that read-back still installs/confirms records; a late cancelled refresh error clears an existing valid cache and changes its status.

The tests manually suspend provider operations with continuations, cancel the owning task, then release its original success/error. They do not depend on timing sleeps or a provider honouring cancellation itself. A submitted provider mutation is deliberately allowed to complete in the fixture, so preservation of its external effect is explicit, not a falsely asserted rollback. [Baseline archive inventory](verification/personal-cancel-baseline-inputs.json).

## Correction

`483284bffbebebd25c35603903c6ad6628a101c0` checks Task cancellation before valid reminder mutations and after each awaited mutation/read-back. Personal connection reads check cancellation before installing results; cancelled personal errors cannot clear caches or replace status. Same-generation cleanup clears its loading flag and restores the previous status (or “Not connected” for a new connection). Existing generation guards still prevent an old cancelled request from cleaning up a newer one. Permission-revocation checks remain in place.

The six tests now pass in the **279-test full Core suite**. Separate external native compilation uses six exact production Core files, with no replacement methods or system providers. Its **22 assertions pass**: seven cancellation assertions plus the fifteen retained permission/reconnect controls. Pre-cancelled valid reminder actions call no provider write/read-back; late cancelled read success/error preserves the valid previous cache/status and clears only its own busy state. [Native probe](verification/personal-cancel-native-probe.swift) · [results](verification/personal-cancel-native-results.json).

Five current arm64 SDK builds pass (iOS/macOS/tvOS/visionOS/watchOS). Source manifests are equal before/after; all 189 source/test/resource/project inputs are bound to digest `ac7de87babbaddbbc195908158accb7ae7283dc1117a3e9b130fda7f510c6d05`. Core baseline/final archives each contain 197 source/gate/executed-test entries; native archive contains 17 entries. Every entry is read back, with exact hashes in the [receipt](verification/personal-cancel.json).

No view source or interaction changed. **No new UI execution or image is claimed.** Previous calendar/reminder UI regression remains at its separately documented [permission-revocation checkpoints](personal-source-revocation.md), not relabeled as a new suite. Current SDK builds prove compilation, not runtime/hardware acceptance on all platforms.

Cancellation cannot retract a write or read already handed to a provider. This fix prevents subsequent calls and acceptance of returned values after cancellation is observed; it does not promise to undo source changes or revoke OS authorization. Invalid/read-only input validation is not reclassified as a provider mutation. Original interface, physical device/authentication, presence, snapshot and the rest of #80's migration/offline/native-alarm matrix remain unaccepted. **#80 stays OPEN.** No real records, messages, alarms or Home operations were used.
