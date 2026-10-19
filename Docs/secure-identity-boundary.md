# Secure Exclave / Secure Enclave identity boundary · #69

19 October 2026. **The documentation task is complete; F098 is not implemented and remains blocked, with parity_accepted=false.** Public device-owner authentication is not HomeView-owned face/voice identification or a Secure-Exclaves port. No alternative biometric enrollment system was added.

## What the public contracts establish

**Secure Exclave and Secure Enclave are not interchangeable names.** Apple’s [Face ID technology article](https://support.apple.com/en-us/102381), published 18 September 2026 and read on 19 October, describes supplemental image processing in a hardware-isolated Secure Exclave on some devices. It explicitly states:

> Data that is processed and analyzed in the Secure Exclave cannot be accessed by iOS, apps, the user, or Apple.

For application authentication the same article says:

> Apps are notified only as to whether the authentication is successful. Apps can’t access Face ID data associated with the enrolled face.

Apple’s [biometric-security architecture](https://support.apple.com/guide/security/face-id-security-sec067eb0c9e/web) describes sensor/enrollment/matching responsibilities within its protected system. These are not an application entitlement to export templates, choose a household member or run an arbitrary app-owned identity model there.

[LAContext](https://developer.apple.com/documentation/localauthentication/lacontext) evaluates authentication policies/access controls. The [deviceOwnerAuthentication policy](https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthentication) may use biometry, Apple Watch or a device passcode; Apple documents watchOS passcode authentication and macOS Touch ID/Apple Watch/password alternatives. HomeView’s actual evaluation returns Bool/error, not Alex/Jamie or an enrolled face/voice template. LocalAuthentication also has capability/domain metadata; that is not a named six-person identity result.

CryptoKit’s [SecureEnclave](https://developer.apple.com/documentation/cryptokit/secureenclave) represents a hardware-based **key manager**. Its P256 signing/key-agreement types do not provide app-owned face matching, voice matching or an arbitrary biometric-processing runtime. Protecting an app key, or encrypting a separately computed template, would not establish that the identification algorithm runs in the Secure Exclave. Neither successful compilation nor SecureEnclave availability would prove F098.

No proven public app-owned Secure-Exclave biometric-processing route was established by these consulted contracts. That is the bounded conclusion—not a claim to have audited every future/private Apple interface. A camera/ML-based custom enrollment system would be a different design, not an implementation of this reference feature, and is not part of this work.

## SDK and application matrix

The following are **compile-only API-shape checks**, not authentication, key generation or hardware tests. Both tiny probe functions were committed before testing (`d04f453ff1bc5143e844e1a60ed92d8b05e93818`) and never executed.

| Target SDK | LA device-owner Bool evaluation | SecureEnclave P256 key type | Current HomeView boundary |
| --- | --- | --- | --- |
| iOS Simulator 27 | Typechecks | Typechecks | Device authentication for separately consented source access; not profile identification |
| macOS 27.0 SDK, deployment target 15 | Typechecks | Typechecks | System policy can fall back to password/other supported factors; not proof of a particular sensor/person |
| tvOS Simulator 27 | **SDK marks LAContext and policy unavailable** | Typechecks | Native unlock path returns false; cryptographic type presence does not add authentication |
| watchOS Simulator 27 | Typechecks | Typechecks | Public policy can use passcode; HomeView’s watch target does not port its personal-source/DeviceConnections flow |
| visionOS Simulator 27 | Typechecks | Typechecks | Eligible hardware/system enrollment required; app-owned iris/face identity is not provided |

Observed: nine accepted API shapes and one expected tvOS unavailability, checked explicitly against the SDK diagnostic. No skipped branch is counted as support. SDK versions and exact targets are in the receipt. Type availability is not hardware availability, successful enrollment, active entitlement, public access to biometric data or operational acceptance on any of the five platforms. Face ID additionally needs eligible TrueDepth hardware and system enrollment; other Apple biometrics have their own sensors and enrollment prerequisites.

## Existing app paths audited

The 189 application/test/resource/build-input files remain byte-identical to published `91ff54fc8b5ed61036d0aa5bcd5ee9844eb5fcd5` (source digest `9ffbda97eaf9479200564f0f8dd4f2a8be7e4fd7b138b8bdc60c40d56cea40a7`). No production source, permission description, entitlement, project or package dependency changed.

- DeviceConnections and local reset call the public device-owner policy; test fixtures are separate. These are device-authentication grants, not household identification. The tvOS branch returns false.
- The six demo names are deliberately chosen; their UI explicitly says no camera/biometric recognition is used. Selecting a demo name does not authenticate against real personal sources. Multiuser/device binding remains [#66](https://github.com/Olli0103/homeview/issues/66).
- NativePhotos detects rectangles in an explicitly selected image to protect composition, not to enroll or recognize identity. Selected/cache photos can contain people; **this does not claim the app never stores face-containing pixels**. Those photos/regions are not Apple Face ID templates and are not mapped to a named household profile.
- NativeVoice produces a reviewed on-device transcript; it does not enroll/match speakers. Transcription is not voice identification.
- AppModel’s CryptoKit use includes hashing recovery data, not creating an identity model inside protected hardware. The declared FeedKit dependency is an RSS/XML parser, not a biometric enrollment dependency.

This is a bounded static audit of these app paths and their declared dependency, not a claim about every internal operation Apple frameworks perform. No demo face/voice matching templates were created by this work. No authentication evaluation, camera/microphone capture, real profile, private key creation or Home operation was performed.

## Evidence and remaining gate

[Source URLs, access dates and quoted-text bindings](verification/secure-identity-sources.json) · [SDK classifications and audited-source hashes](verification/secure-identity.json) · [authentication probe](verification/secure-identity-auth-shape.swift) · [key-type probe](verification/secure-identity-key-shape.swift).

The final probe inputs were frozen and rechecked, exact committed bytes verified, clean target checked before/after. Research/input archive: 61 entries, SHA-256 `969b9a8e947f961cb1c19c14e98ca01f48f391dc456e6c2d9f9bfc4f3e3b1d12`, all entries read back. Initial exploratory checks remain separate from the pinned final classification.

No new app build, UI execution, Core run or physical authentication is claimed for this documentation-only change. Earlier application gates remain bound to their existing revisions; they are not relabeled as Secure-Exclave acceptance. To reopen F098 implementation requires a documented public app-owned biometric-processing path, eligible hardware/entitlements and a separately authorized physical/privacy acceptance. LocalAuthentication alone does not satisfy it. Apple Home remains disconnected.
