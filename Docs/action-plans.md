# Explicit local demo action plans · #35

19 October 2026. This closes the issue's **synthetic software acceptance**, not original personal/Home integration. F043 remains partial; original parity is false. Apple Home stays disconnected.

## Flow and limits

Type, for example:

```
plan: temperature 72; brightness 30; timer for 1 hour named Synthetic plan timer
```

The explicit `plan:` grammar admits 2–6 semicolon-separated steps, at most 1,000 characters: mock thermostat temperature 50–90, mock brightness 0–100, and an explicitly timed foreground demo timer (whole seconds, 1–86,400; title at most 80 characters). Existing strict local parsers are reused. Unsupported or invalid clauses reject the entire request before execution. No external planner/library or generated AI tool output is involved.

Sending creates only a readable preview. Run demo plan is a separate explicit tap, with scope and predecessor dependencies visible. Confirmation expires after 60 monotonic seconds and is bound to the exact plan ID and current active Assistant/session. This is consent for local mock mutations, **not device authentication**. The on-device AI branch remains answer-only.

There are no admitted messages, calls, security actions, scenes, personal-account operations, real Home writes or system-alarm scheduling. Plan timers are foreground demo countdowns, not promised background OS alerts. No arbitrary action/URL execution exists.

Each step must obtain a confirmed predecessor before it is claimed. A stable step identifier and one-use execution ticket prevent repeat confirmation or stale/out-of-order receipts from repeating the same plan. A genuinely new request requires a new preview/confirmation. Leaving, backgrounding, locking/resetting or changing mode invalidates the pending execution; late tasks cannot clear a newer plan. Confirmed resources remain, but plans/requests/approval exist only in RAM and never resume or replay after restart. Cancel does not pretend to roll back completed steps.

## Saved-state read-back

For durable stores, each local change is persisted and the exact canonical saved snapshot is read back before the next step. Read-back uses a bounded regular-file descriptor without following the final symlink. A failed save acknowledgement is reconciled against actual saved bytes: matching candidate means confirmed; a failed acknowledgement with verified old state means failed. Unknown/mismatched saved state is **unverified**, stops dependents, and fences further writes pending recovery. No automatic retry or invented overall success. Ephemeral demo runs explicitly identify their in-memory read-back instead of claiming disk persistence.

## Evidence and qualifications

Code: `b4b0a9a8f147a89d2569192638f38ccb2af0a118`. [Receipt](verification/action-plans.json), [source manifest](verification/action-plans-source.json), [native verdict](verification/action-plans-native-verdict.json), [native results](verification/action-plans-native-results.json), [four durable UI stores](verification/action-plans-store-readback.json).

- 254 Core tests passed. Final Core/test bytes are identical to that full run; later changes were App/UI code, not an unrecorded Core rerun.
- Actual production AppModel passed ten native scenarios / 81 assertions at the clean code pin, with source/compiled/executed input binding unchanged before/after. Cases cover preview, three saved actions and duplicate confirmation, middle offline failure, expiry/context, cancellation before and between steps, a late old task versus a new plan, actual write denial, unreadable store/read-only recovery, and AI answer-only behavior. Only owned synthetic stores and own-class test accessors are used; no real Home, recording or OS alarms.
- Six successful native UI executions on iPad/iPhone, three unique methods, zero failures/skips/runtime warnings. Two disjoint selections use identical 186 source files and 22 compiled inputs, with installed bytes read back. They verify preview/cancel and whole-request rejection without thermostat change; three saved steps plus restart without replay; and a first timer preserved when the middle offline step fails and the last step is not run. Four owned stores were independently read back.
- Five SDK builds passed: iOS, macOS, tvOS, visionOS and watchOS. External project regeneration is byte-equivalent; Python AST valid. These are build boundaries, not physical-device or original UI acceptance.
- All 28 delivery PNGs decoded, four contact sheets visually reviewed; ten selected images are in [action-plans-images](verification/action-plans-images). No private original references are published.

Eight earlier UI failures remain recorded: helpers refused visible controls whose AX hittability reported false. The accepted helper requires fully contained nonempty bounds and performs an actual measured-coordinate tap, with callers requiring the resulting real state transition. This does not establish the underlying AX cause or physical VoiceOver acceptance. Two initially missed diagnostic attachments (dot-suffixed export names) were recovered unfiltered, not regenerated. An initial native harness also failed before execution because it assumed initialization had already saved a baseline; only its owned baseline setup was corrected. None of these failures is relabeled as passing.

All four 208-entry UI checkpoint archives were fully read back; their individual digests are in the receipt. The 130-entry native release input archive SHA-256 is `fc4e8fcef21adf2745d21f93a4ff9dde75c63b5391413984ef847a8088ec2a4a`; all entries read back. External research storage retains compiled products, inputs, logs and result bundles. [Native input inventory](verification/action-plans-native-inputs.json), [probe](verification/action-plans-native-probe.swift) and [test-only accessor suffix](verification/action-plans-native-accessors.swift) describe the native harness: append the suffix to the exact production AppModel, compile the recorded production Swift sources excluding HomeViewApp with its recorded FeedKit/XMLKit objects and own test bundle, and run only against fresh owned test stores. This is not an Apple private-API probe.

Original flight-arrival/personal-context/coffee-machine behavior, real service permission chains, physical assistive technology and system timer alerts remain separate, unaccepted capabilities. No Home connection was added.
