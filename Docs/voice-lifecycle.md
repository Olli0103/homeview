# Timer/cooking speech drafts and capture ownership · #50

19 October 2026. This accepts the **synthetic transcript/command/lifecycle contract**, not real microphone quality, Siri or original-service parity. Physical recognition, quiet/noisy environments, audio routes and system permission timing remain [#75](https://github.com/Olli0103/homeview/issues/75). Apple Home stays disconnected.

## Supported request scope

The existing bounded German/English parser is reused: explicit timer durations/titles and next/previous/repeat cooking steps. Supported numeric forms, limits and examples remain in [everyday-commands.md](everyday-commands.md). Unsupported language/formulations are not guessed. This does not turn local commands into general Siri or enable commands from generated AI answers.

Only an explicitly started cooking session can move. Recognition and preview never create a timer or move a step. Send is the separate action boundary. A second tap after submission sees the cleared input rather than repeating the same speech draft. The optional on-device answer provider remains answer-only.

## Capture/session ownership

AssistantVoiceSession owns the queued start Task, not just the recognizer. Each start has a generation and current-context predicate: active/uncovered Assistant, captured personal-session generation and provider mode, and no competing AI/plan operation. Cancel invalidates the queued caller before it can invoke the controller. Old completions cannot clear a newer task's flags or capture.

VoiceInputController also rejects an already-cancelled caller before resetting any newer capture, and rechecks cancellation after permission/capture awaits. Its existing recognizer generation still gates callbacks. The UI only publishes a transcript while both context and controller phase allow it; changing profile/session, mode, call/doorbell coverage, leaving or background cancels ownership. Temporary permission-prompt inactivity is distinguished in the view; actual physical prompt timing is not accepted by these synthetic checks.

The keyboard field and Send are blocked during queued/capturing/finishing states. Stop completes only a preview. Cancel/failure restores the pre-capture typed draft **only in the same personal session**; an older session cannot overwrite a new user's draft. Completed, still-owned speech drafts can be edited and are shown in a wrapped read-only Draft to send view, reflecting the exact current input. The pinned editor remains separate. This is not an automatic Send or spoken action confirmation.

## Failure and limits

Recognition error, missing/empty final text, more than 1,000 characters and an unfinished final response discard the speech draft instead of presenting an old partial as complete. Later callbacks cannot revive failed/cancelled recognition or alter a completed final result. Failure explanation stays visible and typing remains available. No error string is parsed as a command.

The same production deadline method finishes normal and synthetic recording at 30 seconds. Native finish stops audio and allows at most six further seconds for a final result; absence of final text fails rather than elevating a partial. This is scheduled application timing, not a real-time/hardware guarantee. No transcript is persisted or sent automatically. On-device recognition requirements and lack of cloud fallback are unchanged.

Synthetic --voice-transcript / --voice-recognition-error inputs are read only behind --uitesting. Ordinary launches cannot select these fixtures through those flags alone. Automated checks construct no speech capture, recognizer or microphone engine and leave speech/microphone authorization states unchanged.

## Evidence

Policy/native gate: `28bef0cf25143cef9a7367d0b7226de9c9c250e7`; final rendering/UI/SDK code: `b00bf291c62677adeea6c7ccd13171b4d8a233cc`. The 189-file final source digest is `bc915a02eb47d575ccb6ff9f50454c42723f09125bed58a7b9b97a0b193fe17f`.

- Seven actual native controller/owner/AppModel scenarios, 120 assertions passed. Timer cases verify exact duration/title and persisted read-back; cooking cases verify the expected active step; ambiguous/error cases leave other resources unchanged. Actual shared synthetic recording deadline: 30.01816075 seconds within the predeclared 29–32 second interval. No microphone used; authorization states unchanged.
- Three UI checkpoints: 10 initial + 4 readable-preview + 10 final DE/EN-menu executions passed. These are 24 executions of five unique methods, not 24 independent tests. Final current revision: 10 executions, five methods on both iPad/iPhone; zero failures, skips or runtime warnings. Compiled/installed app bytes were read back and frozen per checkpoint.
- Image review: 84 PNGs decoded, six contact sheets reviewed; 16 final-revision images selected below. The initial successful test run still clipped the named request on iPhone. Wrapped exact-current-input preview fixed that; a still-wrapping Deutsch picker was then replaced by a compact DE/EN menu, with full language names in its choices. Language selection is frozen while starting/capturing. Earlier captures and defects remain recorded.
- Five final SDK builds passed (iOS, macOS, tvOS, watchOS, visionOS). The prior pinned 264-test Core PASS remains applicable to byte-identical Core/test inputs; no new 264-test run is claimed.
- The native integration product remains bound to its policy revision. Final view-only changes are separately verified by exact transformation: read-only wrapped draft rendering and the language menu, with controller/owner/model/Core and all action handlers unchanged. The earlier binary is not relabeled as a new native run.

[Receipt, exact archives and selected images](verification/voice-lifecycle.json), [native results](verification/voice-lifecycle-native-results.json), [native input inventory](verification/voice-lifecycle-native-inputs.json), [view equivalence](verification/voice-lifecycle-language-equivalence.json). Native archive: 127 entries, SHA-256 `ec5345cf7b7805db07e2733ea70a86f5eaf3eb8945a66f869714ee611d9b9b1f`; every entry read back. The three UI archives each contain 211 source/compiled entries; their separate SHA-256 values are in the receipt, all entries read back.

Original F065/F075 coverage stays partial and parity_accepted=false. Closing #50 accepts the specified synthetic command/lifecycle software work only; physical recognition remains #75.

The baseline uses actual VoiceInputController with controlled caller ordering: queued start after cleanup returned to synthetic listening; a cancelled old caller changed a newer capture's generation. This is not a claim that physical audio or the exact UIKit timing was observed. A second development baseline showed an empty final callback incorrectly retaining its partial. Both remain archived, alongside the earlier six-case development gate; they are not relabeled as final acceptance.

Real speech availability/accuracy, distance/music/noise, hardware permission UI, acoustic interruption/route handling, original Siri invocation and original visual parity remain unaccepted. iOS/macOS expose the recognition path; builds on other targets do not assert that their unavailable voice UI became supported. No real account, Home, call/message or microphone operation was exercised.
