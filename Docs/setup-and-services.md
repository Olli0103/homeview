# Introduction and connected services · #71

19 October 2026. Introduction, explicit connection lifecycle and [authenticated local reset](local-data-reset.md) delivered as the software setup package. This is an independent prototype introduction, not Apple's setup/owner pairing or app-store UI.

## Delivered

A three-step, scrollable welcome sheet explains device/OS limitations, synthetic content, Home remaining disconnected, six demo profiles vs actual device authentication, optional account/service requirements, no Siri history/sync and no arbitrary third-party installation. It creates no owner identity, binding, subscription or permission grant. Existing native connection controls remain explicit actions outside the introduction.

**Not now** durably defers; **Use the demo** or **Open Settings** records completion. A normal pending first launch shows the introduction; Settings → Welcome and service overview can reopen it. Reopening and closing does not downgrade completed status. Closing while storage cannot be written still works but leaves the old state pending and explicitly reports that the closure was not saved. Completing on a write failure fails visibly; no success is recorded. Read-only/newer-version stores do not auto-trap in onboarding, and a manually opened sheet can close without changing bytes. Legacy state migrates additively without dropping existing synthetic personal data. Closing/backgrounding the app is not silent completion.

No permission is requested by paging through or dismissing the introduction. Calendar/reminders, Music, photos and other native capabilities use their existing explicit in-app connection/picker controls. Denied permission does not mark a service connected; it can be forgotten and retried later. Disconnect does not delete the source account/library or revoke system permission. Real service and physical-device acceptance remain separate. No Home manager is constructed or home discovered.

## Verification

[Receipt](verification/setup-introduction.json) · [source manifest](verification/setup-introduction-source.json).

- 232 Core tests passed; stronger legacy-personal-data preservation then passed all3 affected tests. Same product Core throughout.
- 4 UI executions passed (2 per iPad/iPhone simulator), zero failures/skips/runtime warnings: defer, completion, same-argument restarts, reopen, synthetic denied connection, forget, later explicit successful connection and disconnect. Existing support for an explicitly owned UUID test store exercises actual Snapshot persistence; not real accounts.
- The final production AppModel was independently compiled outside the repository at the exact clean code commit.13 cases passed: startup/default/zero connections, durable deferral/completion and restart, reopening, failed completion, failed deferral with escape/no fabricated stored success, and read-only/newer bytes unchanged. It uses only --uitesting providers and unique test stores; no live permissions/data request. [Harness](verification/setup-introduction-appmodel-gate.swift) compiles with all Sources Swift files except HomeViewApp.swift and the existing pinned FeedKit/XMLKit objects, as captured in the external archive.
- Five final native SDK builds passed after the failure-escape correction. The earlier UI checkpoint differs only in the guarded AppModel storage-failure path; it is not relabeled a current full UI-suite run.22 UI compiled inputs unchanged before/after and installed apps read back.16 PNGs decoded on two reviewed contacts;8 selected images published. Generator regenerated externally byte-identically; Python AST checked. No changed Node/POSIX/Linux suite applies to this Apple Swift package.
- 201-entry UI source/compiled-input ZIP read back; separate final-source/native-gate/five-product archive also read back entry by entry, exact counts/digests in receipt. These are software/simulator proofs, not original visual parity or physical ownership/permissions acceptance.

## Local reset delivered

Settings now offers a separately authenticated, short-lived, exact-confirmation local reset. Old imported files/recovery copies and late writers are handled; outstanding native scheduling/registered alarm IDs block reset rather than being forgotten. Incomplete old-file cleanup is explicit and can be retried after restart without deleting new content. [Implementation, final verification and limits](local-data-reset.md).

The introduction proof above remains its original checkpoint. Reset has separate current-code receipts and images. Physical permissions/accounts/owner binding and original reference parity remain separate; Home stays disconnected.
