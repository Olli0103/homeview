# Grouped synthetic house notices

22 October 2026 · [#31 / HOME-06](https://github.com/Olli0103/homeview/issues/31).

Control Center → **Mock house notices** opens an initially empty inbox. Loading the demo sequence is explicit. There is no HomeKit manager, real push subscription, notification authorization, security monitoring, camera stream or real alarm acknowledgement.

## Grouping and retention contract

Each typed event has a household, source, source-scoped ID, timestamp, kind and optional explicit incident correlation. Arrival, door and alarm events are grouped **only** when household, source and nonempty incident match, within a maximum 180-second span measured from the group's earliest event. Mere proximity is not correlation. Chaining cannot join an arbitrarily long incident. Sorting/grouping is deterministic across delivery order.

IDs are scoped by household and source. Exact replays are ignored; conflicting duplicate payloads reject the entire incoming batch. Invalid IDs/details/times, more than 200 input records or a resulting history over 200 are explicit failures. Candidate state is committed only after complete validation. No silent prefix, old-event eviction, partial batch success or replaced duplicate. Clear is a separate local action. History is RAM-only and cleared by local reset/new process.

## Privacy and actions

The current view is authorized only for **Demo house**. The demo-cabin event exists in the fixture to prove exclusion; device authentication does not expand household scope. Visible totals count only visible groups/events. Demo labels do not grant rights.

Personal demo text is absent from the returned guest presentation, not merely blurred. Unlock uses the existing device-authentication controller; a demo profile alone is insufficient. Lock immediately recomputes generic rows. Inactive views redact personal detail; disappearance cancels the owned authentication task and background locks/dismisses the view. These are synthetic app-level checks, not accepted physical authentication/App Switcher guarantees.

Records older than 300 seconds remain in history with **Old event · Actions unavailable**. New events more than five seconds in the future are rejected; clock rollback also disables now-future targets. Permission scope, freshness, current existence and MockHome online status are checked again at the action call, not just by the disabled button.

Destinations are a closed enum: mock home, mock cameras or the mock door-state view. An action opens a view only. It never executes a door command, acknowledges an alarm, opens an arbitrary URL, starts a capture or contacts a device. The app test opens the door notice and confirms **Locked / Authenticate Device** remains unchanged.

The existing HOME-01 pause remains absolute. Named household identity and production source binding remain #66/#23; this completes #31's explicitly synthetic acceptance, not F038 original/service parity. The reference reports grouping but supplies no exact original detail screen, so this inbox is not claimed as a pixel replica.

## Evidence and review

[Receipt](verification/house-notices.json) · [final source](verification/house-notices-source.json) · [independent probe](verification/house-notices-independent.swift) · [own images](screenshots/house-notices).

- **370 Core tests**, seven new notice methods, zero final failures. Replay/complete accepted IDs, permutations, source/household separation, bounded whole-window grouping, atomic conflict/invalid/capacity rejection, private redaction and scoped/fresh-only view destinations.
- **52 independent native assertions** against committed production code, not repository tests, with canary redaction and zero-effect checks. Final review tree clean and Core bytes unchanged. No dependency/Node/Python/shell implementation changed.
- **Six first UI executions**, three methods each on iPad/iPhone: grouping/replay/authentication/lock, offline/clear/safe door view, existing unfiltered Control Center hit regions (two empty audit lists). All functionally passed, but actual image review found the native sheet inherited black text on a dark system surface.
- **Four affected UI executions** at the final readable-sheet pin, two methods per device; Core, tests, services and Control Center bytes unchanged. The sheet explicitly sets white/black/light appearance. Final images visibly readable. **Ten successful executions across two checkpoints**, not a final full-suite rerun; zero failures/skips/structured runtime warnings. Source/compiled/launch inputs and installed apps read back at both checkpoints.
- Five SDK builds at the final pin, all successful. Generator outputs byte-idempotent. 28 PNGs decoded, four contact sheets viewed; 12 current own images use explicit checkpoint hashes. The two unchanged Control Center images remain from the earlier exact code pin.

A first new model test incorrectly expected a ten-second clock rollback to invalidate events already almost five minutes old; those events were still within the stated valid window. The probe was corrected to roll back 1,000 seconds, actually making every tested event future-dated. Two original failed assertions remain recorded; no production threshold changed. The first independent helper had an operator-whitespace compile error and never ran; its source/stderr are preserved separately. Neither is counted as a successful test.

No live household, personal account, camera/microphone capture, real alarm, message/call or paid service was used. Physical assistive technologies, real identity, service delivery and original visual equality are not accepted by this synthetic result.
