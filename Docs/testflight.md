# First TestFlight beta: 0.1.0 (1)

Prepared 2 November 2026 for **iPhone and iPad, iOS/iPadOS 26.1+**.
This independent reconstruction is incomplete and is not an Apple product.
Start with owner-only internal testing. No public link, external invitations or
App Store release is part of this step.

## Beta name

The TestFlight listing is **Hearthside Display** (the shorter name **Hearthside**
was unavailable in App Store Connect). The installed app is **Hearthside**, including
its display name, onboarding,
permission copy, assistant shortcut and timer widget. Internal source/target names
and existing persistence keys remain unchanged; historical receipts retain the old
working name. The pre-rename unsigned archive is not the release candidate.

## Scope and packaging

Faces/editor, local everyday apps, mock smart home, explicit opt-in data sources
and the embedded own-timer Live Activity extension. Real Apple Home stays disabled.
Physical-device, account, original-reference and performance gates remain open.
The owner resumed signing/distribution on 2 November; this does not resume every
physical acceptance or authorize Home discovery.

- Release builds now emit dSYMs for the app and timer widget.
- `HOMEVIEW_APP_BUNDLE_IDENTIFIER` sets both host and `.TimerWidget` identifiers.
  Development keeps its existing `org.example.HomeViewReplica` default.
- `PrivacyInfo.xcprivacy` declares own-container file metadata (C617.1), elapsed
  in-app event time (35F9.1) and app-local defaults (CA92.1).
  No tracking or developer-collected data is declared. Explicit weather/feed/web
  requests still contact selected third-party providers; this does not mean the
  app never uses the network.
- Existing opt-in usage descriptions and non-exempt-encryption declaration remain.
  The app uses platform networking/security, not custom cryptography.

## Apple handoff

1. Sign the paid Developer account into Xcode → Settings → Accounts. Verify its
   team and App Store Connect access. Credentials and 2FA belong in Apple's UI.
2. Check existing Hearthside apps, registered identifiers and uploaded build numbers
   before creating anything. `cloud.posselt.Hearthside` and its `.TimerWidget` child
   were registered on 2 November 2026. MusicKit is enabled for the host App ID.
   The App Store Connect app is Hearthside Display (6829618442).
3. Select that team for both targets. Generate project changes with
   `Scripts/generate_project.py`. Pass `DEVELOPMENT_TEAM` and
   `HOMEVIEW_APP_BUNDLE_IDENTIFIER` as build settings. Never override
   `PRODUCT_BUNDLE_IDENTIFIER` globally: that would duplicate the host ID in its
   extension. Confirm the next unused build number before signing.
4. Archive generic iOS, Release, signing enabled, version `0.1.0`. Reuse the
   external DerivedData and check at least 16 GiB free first. Enable automatic
   provisioning only once the account/team is available. Inspect actual signed
   identifiers, matching versions, distribution profiles/signatures/entitlements,
   icon, privacy manifest, App Intents metadata and matching dSYM UUIDs.
   The unsigned rehearsal cannot replace these checks or Apple's validation.
5. Xcode Organizer → Distribute App → App Store Connect. Validate and upload.
   Reconcile an uncertain upload against the exact stored version/build before
   retrying. Supply factual beta/test information and the owner's feedback email.
   Complete actual export-compliance prompts accurately.
6. Wait for processing; verify the build is available to the owner's internal
   group. Upload acknowledgement alone is not installability. First-device start,
   editor persistence, timer cancellation and denied-permission behavior are the
   initial physical smoke checks, not existing PASS claims.

Do not purchase membership, accept legal agreements for the owner, invite other
people or create a public testing link implicitly.

## What to Test (German, ready to paste)

Erste interne Hearthside-Beta für iPhone und iPad. Unabhängiger Prototyp,
keine Apple-App. Bitte Start, Face-Wechsel, Editor und gespeicherte Einstellungen,
lokale Timer sowie Verhalten nach App-Wechsel und Neustart prüfen. Persönliche
Datenquellen nur bewusst verbinden; auch abgelehnte Berechtigungen testen.
Apple Home bleibt vollständig getrennt und verwendet ausschließlich Demogeräte.
Systemwecker und Live Activities sind noch nicht auf echter Hardware abgenommen;
bitte nicht als alleinigen verlässlichen Wecker verwenden. Musik, Kamera und
Sprache hängen von Gerät, Berechtigungen und Kontozugang ab. Bitte Fehler mit
Schritten zur Reproduktion und Gerätemodell über TestFlight melden.

## Beta description (German)

Experimentelle native SwiftUI-Rekonstruktion mit anpassbaren Zifferblättern,
Face-Editor, Timern und lokalen Alltagsansichten. Optionale persönliche Datenquellen
werden nur nach ausdrücklicher Verbindung verwendet. Die Haussteuerung ist eine
Simulation. Die Rekonstruktion ist unvollständig und nicht mit Apple verbunden.

## References checked 2 November 2026

- [Apple TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview)
- [Apple required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Apple API categories and reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- [MusicKit App Service](https://developer.apple.com/help/account/services/musickit)


## Internal distribution boundary

The first beta is exported with `testFlightInternalTestingOnly=true`. Apple must
not distribute this build to external TestFlight groups or the App Store. This
does not close any physical-device, live-account or original-reference gate.
