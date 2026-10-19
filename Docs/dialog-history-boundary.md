# Dialog history and device continuation · #39

19 October 2026. **Clarification and own temporary-context controls, not Siri/iCloud conversation continuation.** Original F050 remains blocked and parity is false.

## What the app does

The assistant visibly labels its own answer mode **Temporary · Not Siri history · No device sync**. Capabilities explains the separation from Apple history. The current conversation lives only in app memory and its own on-device model session; four exchanges / 6000 aggregate characters maximum. Nothing is exported via CloudKit, Handoff, NSUserActivity or a transcript file. There is no history import, cloud retrieval or sync indicator.

**New** removes all displayed pairs and resets the native session; **Stop** does that for a pending request too. Exiting the assistant clears; background, lock and display-profile changes additionally revoke selection and clear the draft. A new process starts empty. Generation cancellation prevents old replies/errors from reappearing. This is app-managed discarding, not a guarantee of physical RAM overwriting or deletion of Apple's own retention. HomeView neither reads nor deletes Siri history. Local display profiles are not account authentication.

## Public API boundary

| Existing public surface | Meaning | What it does not prove |
| --- | --- | --- |
| Foundation Models LanguageModelSession.transcript / Transcript | App’s own session entries; new session has no old context unless supplied by the app. Encoding or reconstructing these entries is possible. | Not the user's Siri-app archive. The app does not persist or restore these transcripts. |
| SiriKit INInteraction | An app-owned intent and its response, including donation and deleting app-donated interactions. | Not a general conversational-history query or Siri-history deletion operation. No donation/delete is performed here. |
| CloudKit CKContainer.privateCloudDatabase | User-private content in containers for which the app has entitlements. Requires an iCloud account for database use. | Not authority to access Apple's Siri containers. No CloudKit container is constructed, account queried, entitlement requested or request sent. |

No supported original-service import/resume path was demonstrated in the inspected public declarations and documentation. This is a bounded evidence conclusion, not proof that an exhaustive search can rule out every future API. No original Siri-history capability is inferred from local demo messages. Two Newsroom search snippets were not substantiated by the fetched article text and are not used as proof of that feature's current availability.

## Own persisted or cross-device alternative — design only

No such alternative is enabled or delivered. It would be **HomeView history**, not Siri sync. Require explicit opt-in, genuine per-account authentication, isolated private app storage, bounded retention, clear/export controls and minimal approved app messages only; never raw speech, Siri archives or provider diagnostics. CloudKit is an existing possible backend, with app provisioning, entitlement and user-quota requirements, not a reason to build an ad-hoc paid service.

Clear/delete must revoke pending writes and generations, remove local content and remote records, and keep only a minimal non-content deletion epoch until devices reconcile. Stable message/session IDs and revision epochs are needed for conflicts; deletion wins stale offline edits and reconnect must never re-upload deleted content. Account switches revoke readers/writers and cached context. Offline/denied/quota failures must show honest local-only status without fallback or false sync success. Before enabling, test two-device account isolation, offline edit vs delete, signout during a pending write, revoked permission, partial deletion/retry, and the no-history default. None of these remote conflict scenarios is claimed tested by the current local-only app.

## Sources read

Apple documentation fetched 19 October 2026, with local Xcode 27 SDK interfaces/headers inspected:

- [Session transcript](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/transcript)
- [Transcript and new-session context](https://developer.apple.com/documentation/foundationmodels/transcript)
- [INInteraction](https://developer.apple.com/documentation/intents/ininteraction)
- [CloudKit container boundary](https://developer.apple.com/documentation/cloudkit/ckcontainer)
- [Private database](https://developer.apple.com/documentation/cloudkit/ckcontainer/privateclouddatabase)
- [App's entitled containers](https://developer.apple.com/documentation/cloudkit/identifying-an-app-s-containers)

## Verification actually performed

[Receipt](verification/dialog-history.json) · [final source manifest](verification/dialog-history-source.json).

- Five external isolation cases compiled against the production Core pass: clear A rejects its late reply while B remains intact, successor has fresh context, deselection revokes content/requests, a new owner begins empty. Synthetic provider, not Siri or cloud inference.
- Ten simulator executions over two checkpoints, three distinct methods: six initial; four strengthened final cases, two per device. Zero failures/skips/runtime warnings. Final tests use an owned UUID Snapshot, persisted synthetic Alex data, restart with identical arguments and no reset, then empty dialogue; separate actual Alex→Jamie transition keeps no prior conversation. Read back both 2056-byte Snapshot files: synthetic Alex data present, no assistant fields or question/answer canaries, only the Snapshot file in each test store. Initial ephemeral restart/anonymous→Jamie pilot is not substituted for this proof.
- Existing229 Core tests remain applicable by exact unchanged Core/test hashes; no fresh full Core run claimed. Five SDK builds pass; the only subsequent source difference is the two stronger UI tests, all product sources byte-identical. Six public API typechecks pass (including Catalyst/watchOS27); probe functions are never executed. No CloudKit account query, container construction, SiriKit donation/deletion, live history access or physical two-device sync test occurred.
- Each UI checkpoint binds176 sources and22 compiled inputs; before/after hashes and installed app bytes match. Each198-entry ZIP was independently read back; digests in receipt. Generator externally byte-identical, Python AST checked.36 PNGs decoded on four reviewed contacts;11 selected images published. The iPad scrolled capability image does not show the full entry and is not used as full-entry layout proof.

[Public surface probe](verification/dialog-history-public-surfaces.swift) is typecheck-only. [Independent context harness](verification/dialog-history-context-isolation.swift) compiles with Sources/Core/AssistantConversation.swift via `xcrun swiftc -parse-as-library -swift-version 6 <core-file> <harness-file> -o <output>` and runs entirely with synthetic delayed providers. No new model/network service is installed.

This closes the clarification tasks, not original history/continuation functionality. F050 remains explicitly blocked. Apple Home stays disconnected.
