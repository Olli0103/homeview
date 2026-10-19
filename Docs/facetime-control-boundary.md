# FaceTime handoff, own VoIP and local call preview · #42

19 October 2026. This report decides the current public capability boundary and separates the product's local preview. It does not implement or accept the original FaceTime session. F053/F054 remain blocked/parity=false.

## Action-by-action decision

| Action | Public evidence / limitation | Actual HomeView behavior |
| --- | --- | --- |
| Start an outgoing FaceTime call | Apple's archived FaceTime URL reference documents handing an address to FaceTime. Native iOS opening can initiate a call without a further system prompt; macOS differs. The archive is not current physical-device verification. | A nonempty recipient and explicit “Call in FaceTime” action are required. The existing system handoff remains separate. Tests use `--uitesting` and return before openURL; no call is placed. A URL being accepted is not proof that a call connected. |
| Receive a FaceTime call | CallKit/LiveCommunicationKit documentation describes integrating an app's own VoIP service and its backend with system calling UI. No documented FaceTime-session feed/control entitlement is established by the inspected sources. | No FaceTime incoming-call provider or identity import. The ordinary page exposes no accept/decline actions; a separately opened local-preview section can create a synthetic incoming state. |
| Accept or decline | Public `CXAnswerCallAction`/`CXEndCallAction` types exist on supported targets. Their existence and a UUID do not establish authorization to operate an existing FaceTime session. No transaction against a real/foreign call was attempted. | Buttons change local state/navigation only and are labeled Accept/Decline demo call. Incoming text says “Incoming local demo · No connection”. |
| Microphone mute | An own CallKit calling service can request a mute action; backend/audio-session responsibility remains with that service. This is not access to FaceTime's microphone stream. | Toggle demo microphone changes only the existing local Boolean. Its accessible value explicitly says “On (demo)” or “Muted (demo)”. No microphone permission/capture starts. |
| Camera on/off | An app's own authorized camera/video engine is distinct from embedding FaceTime or controlling its session. Building an own video service is possible software work, not an implemented FaceTime adapter. | Toggle demo video changes only the local Boolean, with explicit demo values. No camera/capture or network stream starts. Center Stage/own camera checks remain #43/#64. |
| End active call | The public own-call end action and generic transaction interface do not prove a usable FaceTime endpoint. | End demo call closes the local preview and returns to local navigation. It sends no external end action. |
| Observe call state / identify caller | The compile probe references coarse `CXCall` UUID/outgoing/connected/ended properties. This is neither a caller/address/video feed nor proof of FaceTime classification or control rights. | No observer is created, no active-call list is read, and no caller history is imported. Jamie is synthetic demo content. |

LiveCommunicationKit's current documentation also discusses own VoIP services and cellular/default-dialer integration. Those are not rebranded as FaceTime access. The generic CallKit controller documentation permits requesting transactions and describes possible system rejection; this report does **not** infer a universal platform impossibility merely from SDK symbol absence, a guessed method or an unexecuted action type. Current FaceTime control is unimplemented/unestablished and stays blocked; a future documented entitlement or controlled owner-authorized hardware proof would require its own acceptance.

## Product separation

The normal FaceTime page keeps the explicit system handoff and explains that HomeView does not receive/control FaceTime calls. “Show local call preview” is closed by default. Expanding it explicitly states no call, camera or microphone connection and reveals the synthetic preview action. The incoming/active views and accessible microphone/video controls identify themselves as demos. An own CallKit/video engine is not presented as FaceTime.

The URL action and its test guard are unchanged. The call preview still changes only local route/Booleans; no new framework import, call provider, transaction, capture, account, permission, remote message or network operation is introduced. No real call is used as an automation fixture.

## Evidence lanes

[Receipt](verification/facetime-boundary.json) · [source](verification/facetime-boundary-source.json) · [public sources](verification/facetime-boundary-sources.json) · [own compile-only probes](verification/facetime-boundary-api).

Product pin `c24563bcb9324eaa2fc9d99f69a16f80af9372a5`: six UI executions (three methods on each iPad/iPhone) passed with zero failures/skips/structured runtime warnings. Five current SDK builds passed. Six PNGs decoded, two actual contact sheets reviewed and six own captures selected. Normal handoff vs incoming/active local preview is visible in those images. The frozen source manifest contains 190 files, digest `90c651d34135dab29b1f84eea3a5288508ae138cdf4c71bd32714c45ee9ad182`; 22 compiled inputs and installed app files match before/after. The 212-entry UI source/compiled archive is completely read back.

Ten API typechecks have six compiled outcomes (both probes on iOS/visionOS/watchOS) and four explicit unavailability outcomes: the probed CallKit action types and LiveCommunicationKit manager are unavailable on macOS; these modules are absent from the checked tvOS SDK. That does not replace the separately successful app builds, whose local simulation does not import these frameworks.

The SDK probes are limited to own action objects/coarse state and a LiveCommunicationKit manager type. Functions are never executed: no provider/controller/observer instance is created at runtime, no transaction/report/call is submitted, no dialer preference changes. Platform compile/unavailability outcomes are recorded individually, not generalized into live FaceTime support. No SDK headers or private Apple interfaces are redistributed.

Simulator cases check default isolation of the preview, explicit opening/closing, accept/decline/end navigation, demo microphone/video values and system communication test guards. They are local synthetic acceptance, not physical FaceTime, microphone/camera, incoming-call delivery or original geometry. Current SDK builds and actual saved images are separately source-bound in the receipt. Core/controller code and all 66 Core/CoreTests files remain byte-identical to the historical pinned 279-test PASS; no new Core run is claimed for view/test changes.

The public forum thread consulted for a FaceTime question returned a human-verification page, not its discussion. It is retained as unavailable research, never cited as an Apple denial or evidence of support. Current framework docs and the explicitly dated archived URL reference are the evidence used.

Completing this bounded capability report and product/demo separation is not completion of F053/F054 or a claim that a simulated call is live. Those original functions remain blocked pending a documented usable FaceTime path and separate device/service acceptance. Home remains disconnected.
