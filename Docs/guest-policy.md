# Guest access policy · #68

19 October 2026. This is a **local software policy with synthetic service acceptance**, not household identity, real Home setup or original-service parity. A demo profile is not device authentication. The authenticated column means a holder authenticated by this device, not proof of a named household administrator.

## Action/source matrix

All operations also require valid values, source availability/permission and their existing consent. No role enables Apple Home.

| Action/source | Guest | Demo user/profile | Device-authenticated holder |
| --- | --- | --- | --- |
| Mock temperature/lights/fan/blinds and nonsecurity scenes | Allowed | Allowed | Allowed |
| Mock door lock and Good Night (which changes the lock) | Denied | Denied | Explicit command allowed |
| Public city weather, communal local timers | Allowed | Allowed | Allowed |
| Bundled media and explicitly configured public RSS podcast feeds | Allowed | Allowed | Allowed |
| Apple Music connect or search | Denied | Denied | Explicit source connection/search allowed after device authentication |
| Apple Music playback/queue metadata without sharing | Denied | Denied | Allowed for the authorized connected source |
| Specifically shared current Apple Music queue | Playback/queue metadata only | Same guest grant | May explicitly approve or revoke current queue |
| Calendar/reminders from connected personal stores | Denied | Denied | Existing separate source consent, OS permission and device authentication required |
| Demo-profile synthetic lists/messages | No profile content | Own simulated profile UI only; no actual identity or source rights | Device authentication alone does not select a demo profile |
| Real messages/calls, Home operations | Not implemented/denied | Not implemented/denied | Not enabled by authentication |

Existing native authentication and service controllers are reused. The project specifically requires its own local policy; no external identity framework, service, plugin, account integration or paid platform is introduced. The reduced Watch has no device-authentication route in this build, so its security scenes are denied with a visible error. Five SDK builds are compilation evidence, not proof of equivalent service support on every platform.

## Sharing purpose and lifetime

Connecting Apple Music does not share it. An authenticated holder first chooses a queue and then explicitly taps Share current queue with guests. It approves that existing queue's titles/artwork and playback controls, **not search, account access, arbitrary replacement queues or personal lists**. Continue as guest clears profile/device-private access without starting a new song; only the approved queue remains available. A guest cannot create or renew the grant. Stop remains allowed; revocation also stops playback.

The grant is RAM-only, not Snapshot/UserDefaults or source permission. A new search revokes it before fetching a replacement queue. Background/Root disappearance, explicit revocation, source disconnect/reconnect, local reset and a new app session revoke sharing. An ordinary personal lock/profile switch may retain an explicitly shared queue; calendar/reminder caches still clear. Returning from a temporary authentication prompt is distinguished from actual background entry. Source permission is checked at access/mutation and polling; permission loss immediately denies access and polling stops/clears the queue. Physical account switching and acoustic/OS playback behavior have not been accepted by synthetic tests.

## Model enforcement

GuestAccessPolicy names the local capability matrix. Connected music additionally checks actual source permission and authentication/current-queue consent in DeviceConnections, including direct search/play/resume and asynchronous receipt guards. Lock clears unshared queue metadata and invalidates pending account work. Source connection requires authentication before requesting music permission or persisting the new source choice. Restoring an already approved source does not request music permission or grant guest sharing.

MockHome rejects a security command **before any scene mutation or success audit**. AppModel passes actual device authentication, not its demo-profile flag. Good Night is classified as security because it changes the door state; rejection leaves temperature/lights/blinds unchanged too. Assistant commands and app-owned widgets/complications/activity controls share these callable model paths. There is no new WidgetKit/Siri intent or real Home/communication adapter.

Metadata getters and activity display are gated as well as buttons. A locked private Apple Music entry routes to device authentication instead of resuming or exposing its queue. Owner search controls are absent in shared guest mode; direct model search remains denied even if called without that UI. Actual device authentication never performs a door action automatically; a separate explicit command is still needed.

## Evidence

[Receipt](verification/guest-policy.json) · [final source](verification/guest-policy-source.json) · [policy source](verification/guest-policy-policy-source.json) · [native results](verification/guest-policy-native-results.json) · [selected own images](verification/guest-policy-images).

Policy code `7e71e9742d16a7242e30f1d0a4fa1e65dcf58d5c`; final code `a7e251272428b9dad985241f9adfca577d6d0649`. Final 188-file source digest `3b8b05b7382b4d6b5d323fd70b77b13975212bef46e7beaaee009cd004d459da`.

- 264 Core tests passed at the policy pin, including all 66 capability/role/sharing matrix cells, zero private search/caches without permission, explicit queue-only sharing, source permission revocation, reconnect/reset/session end, and manually controlled permission/search completions after lock. No Core/test bytes changed in the final revision.
- The actual AppModel gate passed six cases / 64 assertions at the clean policy pin: guest/demo/authenticated security and saved read-back, private music metadata and direct/assistant/widget calls, explicit guest handover/playback/revocation, background-sequence lifetime, denied owner authentication, and fresh-session defaults. Compile/source/execution bytes bound before/after and production source prefixes checked against Git. These are synthetic native model paths, not a physical account or acoustic playback acceptance.
- Eight initial UI executions passed, four methods on iPad/iPhone, including real touch-based owner authentication/explicit lock, shared guest queue without search, owner revocation and background/Assistant denial, plus connected weather/music navigation/activity regression. Image review still found an obsolete Demo profile required caption on the lock view. That visual defect is retained, not hidden by the passing UI counts.
- The final revision changes **exactly that one view text literal**. Two affected UI executions then passed at the final pin, one method on both devices; corrected captions were visually reviewed. Ten successful executions total, four unique methods across two checkpoints, not a single final full-suite run. Each checkpoint has 188 source files / 22 compiled inputs unchanged, installed app byte read-back, zero failures/skips/runtime warnings. [Exact equivalence](verification/guest-policy-disclosure-equivalence.json) establishes all model/Core/service inputs unchanged; the older native product is not relabeled as a run of the final UI binary.
- Five SDK builds passed at the final revision. Project/schemes/MainInfo generation was externally byte-checked at the policy pin; generator inputs/file list and outputs are unchanged by the view literal. Python AST checked. 42 PNGs decoded, four contacts visually reviewed; 14 selected images include only the corrected lock caption, with checkpoint locators in the receipt.

Both 210-entry UI archives were completely read back: initial SHA-256 `ab02dfde1c7c2137859cc119980e640f1f012a8628624368b3db9939ca0a22ab`, final `ed369de4e08657fd94634b910fe93130856befcd8a5d3cd8eb5b2584b4d95a63`. The 121-entry native archive SHA-256 is `9c9c20132bee9f721420bb09af973a31d095479711067807bf56f1cdde704cec`, all entries read back. [Inventory](verification/guest-policy-native-inputs.json). After the view edit, the exact older native compile sources were recovered from their Git pin and verified against recorded input hashes, never substituted with current bytes.

The initial baseline genuinely failed two tests / five assertions: a locked session retained and refetched unshared music; Good Night changed an unauthenticated lock and other scene values. Its 69-entry source/result archive is retained and fully read back. A preliminary 60-test Core selection also retained one failed legacy positive-control case (two assertions): it tried to connect music without the newly required authentication. That control was changed to authenticate **only music**, then relock; the existing zero calendar/reminder reads and restored-private-music checks remain. Exact earlier fixture bytes were recovered from known edits and verified against the original SHA before archival. Final 264 tests pass; no failed checkpoint is relabeled.

[Native probe](verification/guest-policy-native-probe.swift) and [test-only own-class store accessor](verification/guest-policy-native-accessors.swift). Reproduce with the exact policy-pin production Swift sources (excluding HomeViewApp), append the accessor suffix to AppModel, and compile the recorded helper/dependency objects and own bundle. Run each case only with --uitesting and a fresh owned UUID store. No Apple private API or real service permission is exercised. External research storage retains commands, products, owned stores, result bundles and failures. Existing compiler warnings are not presented as a warning-free native build.

Automated sources, permissions, authentication outcomes, songs and personal content are synthetic. No real account, message/call, Home discovery/device action, microphone capture or paid service was used. Original F097 service/device/visual acceptance remains separate and parity false.
