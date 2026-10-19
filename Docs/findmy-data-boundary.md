# Find My devices, items and people: data vs handoff · #46

19 October 2026. A public-capability decision and honest local preview, not an Apple location-data integration. F059 remains blocked/parity=false. No Apple Account, private service, live location, nearby peer, accessory or person is queried.

## Separate the data types

| Data/path | Public evidence | What HomeView does / does not do |
| --- | --- | --- |
| Apple devices | Apple documents Find Devices at `https://www.icloud.com/find/`, with account sign-in and existing sharing/setup requirements. This is a user-facing website, not a location-data API granted to our app. | An explicit button hands this fixed public HTTPS URL to the OS. It imports no device list, coordinates, identity, credentials or cookies. Handler acceptance is not proof of sign-in, a loaded site or a located device. |
| AirTags / Find My network accessories | Apple's support 104978 explicitly says these use the Find My app, not the device-finding website. Apple's developer Find My page describes MFi enrollment for building accessories. | No AirTag lookup, sound command, token/ownership import or network query. An accessory-development program is not a general consumer-account reader; no enrollment/spend or accessory implementation is introduced. |
| Shared people | Apple's Find My app provides person/location sharing under its own permissions. No usable general shared-people read endpoint is established in the inspected public app sources. | No contacts/account scraping, friend list or shared coordinates. The device-website handoff is not advertised as person tracking. |
| Core Location | Public CLLocationManager supplies a permissioned app's own device-related location events. | It is not the user's entire Find My device/person graph. The probe references a supplied manager parameter only; no instance or permission request/read is executed, and no location service is added to the app. |
| Nearby Interaction | Public UWB interaction concerns physically nearby participating peers/accessories and exchanged discovery/configuration data. It can support an own proximity feature under its requirements. | This is not Find My network history, an AirTag account list or remote friend location. No session/token exchange or radio request starts. Own proximity software remains unimplemented, not mislabeled as a universal API impossibility. |
| Native Find My app launch | The inspected sources establish a public device website, not a supported general native-app scheme plus data return. | No guessed/private `findmy:` URL or embedded account browser is added. The fixed Apple HTTPS handoff is separately labeled and returns no locations. |

The readable extraction of Apple's per-device guide omitted its detailed table. Missing extracted cells are not treated as evidence of an unavailable feature. Its visible overview and the explicit current support 104978 device/item distinction are the relevant evidence. Absence of an SDK symbol is not a proof of universal future impossibility; current Original F059 remains unimplemented/unestablished in this app.

## Product behavior

“Local demo · No Apple location data” stays above the scrollable content. The drawn schematic has a visible “SCHEMATIC DEMO · NOT LIVE” badge and an equivalent accessibility label. Demo Keys / Simulated item · Living Room are fixed synthetic content, not coordinates, a last-seen timestamp or a live signal.

“Play local demo tone” requests the existing bundled local chime. Its banner says “Local demo tone requested · No remote item contacted”, not that an AirTag sounded or acoustic playback completed. Actual sound/output can still fail and is not asserted by this request label. No remote device is contacted.

The separate “Open Apple's Find Devices website” button is preceded by its device-only purpose and the explanation that no location is imported. Its resulting status stays in the fixed header, not below the scroll viewport. Only a deliberate action reaches openURL. The test guard returns before the OS handoff; tests do not open a login site, read a session or use an account. Production only reports URL-handler acceptance/failure, not successful website loading, authentication or device discovery. Browser/account state stays outside HomeView.

## Evidence lanes

[Receipt](verification/findmy-boundary.json) · [source manifest](verification/findmy-boundary-source.json) · [public source locators](verification/findmy-boundary-sources.json) · [own compile-only probes](verification/findmy-boundary-api).

Final product pin `f698a78231a5908e83a5eb959503a29d14298ed8`: the two affected handoff executions pass on iPad/iPhone, including full-frame interaction and resulting status within the viewport. Fourteen UI executions across three checkpoints: thirteen successful, one historical failed execution retained, three unique methods and two final-revision executions. No checkpoint has a skip/structured runtime warning. Earlier schematic/tone successes remain at their recorded revision; this is not a relabeled complete final-revision suite. Five final SDK builds pass.

All checkpoints freeze 190 source and 22 compiled inputs and read back installed app files. Their separate 212-entry archives are fully read back. Final source digest: `8dca2803d17ea0bc2115156fd606a006ca1c8b544b49fcd0d857254eb6d9a067`. Thirteen exported PNGs decoded, six contact sheets and one decoded failure-recording frame reviewed; nine selected images retain the initial hidden-feedback captures and the intermediate full-touch-frame failure. This is inspected local-state/usability acceptance, not original pixels, general accessibility or physical-device acceptance.

Ten SDK typechecks have seven compiled outcomes: own-device location value on all five targets and the nearby-peer probe on iOS/watchOS. The remaining three specifically report nearby-object types unavailable on macOS and no NearbyInteraction module in the checked tvOS/visionOS SDKs. No hardware capability is inferred from compilation.

The two probes check own-device CLLocationManager.location and a supplied nearby object's distance / peer-token configuration. They are never executed. They do not construct a location manager/session, generate a discovery token, request permission, start a radio, or read real location. Platform compile/unavailability outcomes are individually recorded, not presented as Find My data access or hardware ranging acceptance.

The initial six functional UI executions passed, but manual image review found the website-result message below the visible scroll area. That checkpoint remains retained as a visual/usability failure at the feedback scope, not silently accepted because its AX text existed. The final source moves status to the fixed header, puts purpose text before the action and adds a viewport-frame assertion for the resulting feedback.

The feedback refinement passes five of six UI executions. The remaining iPhone handoff case stops before tapping: the existing measured visibility helper cannot bring the last action's entire touch frame inside its conservative 40-point viewport inset at scroll end. A frame decoded from the retained failure recording shows the text already visible; this is not a claim that its label is missing or that the website declined a request. The final correction adds bottom scroll space, retaining the original full-frame visibility assertion and the new status-frame assertion rather than weakening them. Only that affected handoff method is selected on the final revision; other successes remain at their separately pinned checkpoint.

Simulator selections test persistent demo labeling, accessible schematic identity, no website handoff before deliberate action, its automation guard and truthful local-tone request wording. Own bundled audio inside Simulator is not an acoustic, remote-accessory or hardware test. Source/build/install binding and actual image review are recorded in the receipt. All Core/CoreTests and the actual audio engine remain unchanged from the previous delivered source; historical 279-test acceptance is not rerun or relabeled for these view-only changes.

Completing this public-boundary/handoff decision and demo qualification does not complete Original F059. Actual Apple device/item/person data, precision finding, remote sound and hardware/identity/service acceptance remain blocked. No private APIs, reverse-engineered account client, fabricated live locations, real Home discovery, automatic messages or calls are introduced.
