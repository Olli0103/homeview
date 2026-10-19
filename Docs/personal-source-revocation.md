# Personal source permission revocation · #67

19 October 2026. A bounded local software correction using the existing DeviceConnections/EventKit adapter, not a new identity system or integration. No real calendars, reminders, accounts, biometric prompts, microphone, Apple Home or system alarms used.

## Reproduced boundary failures

Seven new controlled-provider tests at `f3ddb9f9c3ea195720923cea5bc805cdf5f2cdac` exercise unchanged production sources from published `a257b7104f1d6239e34f3b2512762e1005a2fcf9`. All seven fail, with 23 failed assertions. They demonstrate:

- Already displayed calendar/reminder caches survive source permission revocation during ordinary polling.
- A source read begun with permission can return after revocation and install personal records, even before the next poll.
- Adding/completing/removing a reminder can still call the provider after permission has been revoked.
- A previously submitted write can perform a further private read-back after revocation.
- A completed authorization callback is trusted without checking the current permission status before reading.

These are deterministic app-boundary failures using deliberately controlled synthetic providers. They do not establish that every OS provider actually returns private records after revocation; the app must not depend on an outstanding provider read being cancelled or its returned bytes being empty. No real external write was performed. [Preserved baseline archive receipt](verification/personal-source-baseline-inputs.json).

## Repair

Product and full Core/native/SDK pin: `025185e1bac0bf275759c2cd7231f1e588fa7891`. A shared private source-status gate checks public authorization status after permission callbacks, before installing either personal read, before starting reminder mutations, and before/after a mutation's read-back. Ordinary tick checks already connected/in-flight personal sources without a permission prompt or personal read.

When permission is unavailable, it increments that source's generation, clears only its records and loading flag, removes its enabled state and displays a reconnect explanation. The user's requested connection choice remains, but permission returning does not automatically reconnect or enumerate data. An explicit Connect action is required. Other personal sources and device authentication are not revoked merely because one source lost access. Old responses and cleanup cannot alter a newer explicit reconnect.

A provider mutation already submitted before revocation may still complete externally. The app does not claim to undo it, confirm it from stale data or automatically retry it. It starts no subsequent read-back once revocation is observed; if revocation arrives during an already submitted read-back, its returned records are discarded. The next consciously reconnected session reads the actual source again. There is no atomic transaction between OS authorization changes and a synchronous authorization check: ongoing polling and response checks limit exposure once revocation is observed, not a guarantee of zero-time OS notification.

## Acceptance lanes

The full Core suite passes **273 tests**, including the seven previously failing cases and two added race controls: old read completion while a new reconnect is busy, and permission lost during reminder read-back. No skipped test, no changed expectation to accept the original failures. Source manifests are equal before/after. [Product source manifest](verification/personal-source-policy-source.json).

A separate external native executable compiles the six unchanged production Core files directly with its own controlled provider, without replacing any production method. Its **15 assertions pass**, covering per-source cache clearing, no prompts/reads during polling, no implicit reconnection, all three new reminder-write gates, late read rejection, old-error/new-busy isolation and successful explicit reconnect. [Probe](verification/personal-source-native-probe.swift) · [results](verification/personal-source-native-results.json). An earlier external probe failed only to compile due to assignment whitespace; it executed no scenarios and is preserved rather than counted as a product failure.

Initial UI selection at the product pin: eight executions, six successful, two failed. Both iPhone Reminder cases stayed “Not connected” before reaching their actual CRUD/read-only checks. The captured accessibility status and an actual frame decoded from the retained failure recording show the Reminder Connect button clipped below the rounded viewport despite isHittable. This was not evidence of denied source permission or a newly introduced model error. The existing measured full-visibility helper now reveals the entire button before tapping, including the second connect after music authentication. Only test interaction changed in `f2db488`; the same connection/status/CRUD/read-only expectations remain. Calendar/background successes remain separately pinned to the product revision, not relabeled as a complete final-revision suite.

The final affected selection at `f2db4880783d93ecbdf3f8993a8a10e3d7b6c7a1` passes all four executions (two Reminder methods on both devices). Total: twelve UI executions, ten successful, two historical failures retained; four unique methods, four final-revision executions. Both checkpoints have zero skips/structured runtime warnings, frozen 189-source/22-compiled-input manifests and installed-app byte read-back. All production and Core test files are unchanged after the product pin, so its 273-test/native/five-SDK results remain separately labeled rather than rerun or relabeled.

Ten exported PNGs decoded, four contact sheets and one frame decoded from the failure recording reviewed; nine selected captures include the clearly historical clipped-button frame. Own synthetic images document these states, not full accessibility or original layout acceptance.

UI regression and SDK results, exact source/build/install binding, own captures and qualified coverage are in the [receipt](verification/personal-source.json). The Simulator UI selections exercise normal calendar authentication, reminder CRUD/read-only source behavior and background/fresh unlock. They do **not** simulate a live Settings permission revocation; that boundary is tested with the controlled Core/native providers above. A first build-preparation command retained the preceding worktree path and ran no UI tests. It was preserved, then replaced by an explicitly checked current-worktree build before testing; no earlier binary is relabeled as this fix.

**#67 remains OPEN.** Actual departure/presence detection, hardware authentication, App Switcher snapshots and broader interruption/media/source behavior remain separately unaccepted. This is not an original-interface or full personal-data parity claim. Home remains disconnected.
