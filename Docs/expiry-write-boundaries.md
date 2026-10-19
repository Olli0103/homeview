# Local expiry receipts before notification effects · #80

19 October 2026. Existing AppModel/local persistence path; synthetic data and fresh owned UUID stores only. No Home connection, real account, microphone, system alarm or physical audio acceptance.

## Actual before-fix failure

At clean published `46cc6724e55c981c251edbc06bdf89870b53e065`, two actual AppModel scenarios failed nine assertions: a due foreground timer and a current-minute local alarm changed the in-memory receipt, displayed a banner and requested a chime before a failed atomic save. The timer also changed selectedTimer. After restoring the unchanged original store and restarting, the same event was acknowledged again. Already-delivered and paused-timer controls passed. Original JSON bytes and the fault-directory canary were already preserved; this was an acknowledgement/order defect, not demonstrated disk corruption.

[Original native results](verification/expiry-write-baseline-results.json). Baseline archive: 124 entries, SHA-256 `6e9bee4ac360728d3fa84db78e7ed13227d1101c31d2d85e77ae812d26ca89d1`, all entries read back. An earlier probe preparation failed to compile because of a test-only assignment-spacing typo; it executed no native scenarios. That failed preparation is preserved separately within the archive, not counted as a product failure or silently overwritten.

## Bounded repair

`819ee8ffd01bc0d735f520458205ceed92cf4f4c` collects local timer/alarm receipts in a Snapshot copy, then commits them through the existing commit/rollback helper. Only successful persistence permits timer selection, banner and readout-interruption/chime request. Failed writes retain the previous Snapshot and do not acknowledge completion. The method does not return early on failure: its existing idle/privacy lock still executes.

Existing completion order, current-minute/calendar predicate and native-ID chime suppression remain unchanged. This is not a new alarm scheduler or catch-up algorithm. Marker-before-effect prevents the demonstrated duplicate acknowledgement after a failed save/restart; it is not an atomic transaction with the speaker or AlarmKit. A crash after saving the receipt but before its effect can omit that notification. Registered native operation/write reconciliation and asynchronous scheduling completions remain open.

## Source-bound acceptance

All new gates use the same clean product revision above. The sorted 189-file source manifest digest is `5f2fc194bb439ee7dd9b263ea02818908eb10192833e91ab9fda67c95dafd0f3`.

Five actual native scenarios / **72 assertions passed**: due timer, due alarm, already-delivered and paused controls, plus due timer during an idle personal-session lock. Real owned-path atomic-write failure preserves original bytes/canary, Snapshot, selection and absence of banner/chime request. Restoring the owned path and explicitly retrying commits the exact expected marker and permits one request; a further restart does not repeat it. The privacy control also verifies profile/draft clearing and return to the face despite the write failure. [Results](verification/expiry-write-native-results.json), [probe](verification/expiry-write-native-probe.swift), [sole model accessor](verification/persistence-write-model-accessor.swift).

The native probe deliberately contains **no demo-tone.wav resource** and guards that absence before any scenario. Unmodified LocalAudioEngine rejects the absent resource before creating a player. Its request counter is evidence of request ordering, not heard audio, routing, hardware interruption or system delivery. Production AppModel is byte-identical except for the separately documented private store-URL test accessor; no production method is replaced.

Six UI executions passed: three existing methods on each iPad/iPhone Simulator. They check a timer-completion banner remains visible under the synthetic doorbell, completion stops the synthetic answer-readout backend without resuming, and independent saved timer deadlines survive process restart. These use the app's own demo tone inside Simulator, not native physical audio acceptance. Zero failed/skipped tests or structured runtime warnings. Frozen 22 compiled inputs remain equal before/after, installed app files match the build, and the 211-entry source/compiled archive is completely read back. Five arm64 SDK builds passed: iOS, macOS, tvOS, visionOS and watchOS; build success is not runtime acceptance of the latter platforms.

20 PNGs decoded and two contact sheets reviewed; six selected captures document these tested states. The iPhone readout capture has the existing keyboard-present short viewport; it is not acceptance of full answer visibility or general accessibility. No original pixel/geometry match claimed. All 66 Core/CoreTests files remain byte-identical to the historical pinned 264-test full PASS; no new full Core run.

[Complete receipt, archive hashes, source binding and own images](verification/expiry-write.json). **#80 remains OPEN** for the broader persistence, migration, offline, provider and native-operation matrix. Home stays disconnected.
