# Sprache: vollständige Abnahmematrix, ohne erfundene Blockaden

30. Oktober 2026 · [#74](https://github.com/Olli0103/homeview/issues/74) · **weiter offen; F104/F105 partial, parity=false.**

**48 einzelne Zellen = sechs Ziele × acht Hilfsmittel.** Vier historisch tatsächlich benutzbare Teilpfade, klar benannte Setup-/Host-/Appgrenzen, aber auch verbleibende Softwareprüfungen und ungeklärte OS-Pfade. Eine vollständige Tabelle ist noch keine vollständige Abnahme.

Der ursprüngliche research-Vertrag erlaubt Nutzbarkeit **oder konkrete Blockade**. Nicht ausgeführte, mit vorhandener Runtime prinzipiell prüfbare Softwarefälle werden deshalb nicht zu Hardwareblockaden umetikettiert. Vollständiger [maschinenlesbarer Befund](verification/speech-acceptance-ledger-20261030.json).

## iPhone

| Hilfsmittel | Belegter Umfang | Tatsächliche Grenze / Status |
|---|---|---|
| OS Live Speech | Apple documents the product family; S1 dated 2023, not a current model certification. [S1] | **blocked_setup** · No enabled/trained assistive session, chosen voice/model, acoustic or call acceptance in the current owner-held physical scope. |
| OS Live Captions | Apple guide documents the platform; model/language/region restrictions remain individual. [S3] | **blocked_setup** · No enabled OS transcription session or authorized microphone/call fixture; own legible media cues are not OS captions. |
| OS RTT | Documented phone/FaceTime RTT setup, distinct from own composer. [N2] | **blocked_setup** · No configured carrier/region/phone pair and authorized RTT conversation partner; app has no RTT transport. |
| OS Dictation | Documented system text dictation; iPad E11 specifically documents an Apple external-keyboard route. [E9] | **blocked_setup** · No enabled system dictation, chosen language/model and authorized acoustic session; own Speech/AVAudioEngine recognition is a separate API. |
| OS Type to Siri | Documented keyboard requests to Siri, not HomeView text entry. Mac E14 is specifically Siri AI Beta/macOS27 with language/model restrictions. [E10] | **blocked_setup** · No configured and authorized Siri service session. No own shortcut invocation is counted as a Siri conversation. |
| OS Vocal Shortcuts | User records/trains a phrase for a chosen action. [S7] | **blocked_setup** · No user-trained phrase or authorized acoustic invocation; AppShortcuts metadata does not train a Vocal Shortcut. |
| Own App Shortcut | Native OS discovery and terminated-process cold / same-process warm invocation observed. [assistant-os-shortcut.md, verification/assistant-os-shortcut.json] | **observed_usable** · Historical29Oct checkpoint, unlocked fresh account-free simulator only; no Siri, physical authentication, multiwindow or other OS-version acceptance. |
| Own source-media captions | Actual muted own timed-text cue / selection / seek / Off / source-change UI observed. [podcast-source-captions.md, verification/podcast-source-captions.json] | **observed_usable** · Historical22Oct checkpoint; bounded own tone/markers, not general streams, languages, format or acoustic/physical acceptance. |

## iPad

| Hilfsmittel | Belegter Umfang | Tatsächliche Grenze / Status |
|---|---|---|
| OS Live Speech | Apple documents the product family; S1 dated 2023, not a current model certification. [S1] | **blocked_setup** · No enabled/trained assistive session, chosen voice/model, acoustic or call acceptance in the current owner-held physical scope. |
| OS Live Captions | Apple guide documents the platform; model/language/region restrictions remain individual. [S2] | **blocked_setup** · No enabled OS transcription session or authorized microphone/call fixture; own legible media cues are not OS captions. |
| OS RTT | Documented phone/FaceTime RTT setup, distinct from own composer. [N1] | **blocked_setup** · No configured carrier/region/phone pair and authorized RTT conversation partner; app has no RTT transport. |
| OS Dictation | Documented system text dictation; iPad E11 specifically documents an Apple external-keyboard route. [E11] | **blocked_setup** · No enabled system dictation, chosen language/model and authorized acoustic session; own Speech/AVAudioEngine recognition is a separate API. |
| OS Type to Siri | Documented keyboard requests to Siri, not HomeView text entry. Mac E14 is specifically Siri AI Beta/macOS27 with language/model restrictions. [E12] | **blocked_setup** · No configured and authorized Siri service session. No own shortcut invocation is counted as a Siri conversation. |
| OS Vocal Shortcuts | User records/trains a phrase for a chosen action. [S8] | **blocked_setup** · No user-trained phrase or authorized acoustic invocation; AppShortcuts metadata does not train a Vocal Shortcut. |
| Own App Shortcut | Native OS discovery and terminated-process cold / same-process warm invocation observed. [assistant-os-shortcut.md, verification/assistant-os-shortcut.json] | **observed_usable** · Historical29Oct checkpoint, unlocked fresh account-free simulator only; no Siri, physical authentication, multiwindow or other OS-version acceptance. |
| Own source-media captions | Actual muted own timed-text cue / selection / seek / Off / source-change UI observed. [podcast-source-captions.md, verification/podcast-source-captions.json] | **observed_usable** · Historical22Oct checkpoint; bounded own tone/markers, not general streams, languages, format or acoustic/physical acceptance. |

## Mac

| Hilfsmittel | Belegter Umfang | Tatsächliche Grenze / Status |
|---|---|---|
| OS Live Speech | Apple documents the product family; S1 dated 2023, not a current model certification. [S1] | **blocked_setup** · No enabled/trained assistive session, chosen voice/model, acoustic or call acceptance in the current owner-held physical scope. Fresh Mac UI access unavailable; Developer mode disabled, prior two bounded runner starts executed zero methods; not a proved single cause. |
| OS Live Captions | Apple guide documents the platform; model/language/region restrictions remain individual. [S4] | **blocked_setup** · No enabled OS transcription session or authorized microphone/call fixture; own legible media cues are not OS captions. Fresh Mac UI access unavailable; Developer mode disabled, prior two bounded runner starts executed zero methods; not a proved single cause. |
| OS RTT | Documented phone/FaceTime RTT setup, distinct from own composer. [S6] | **blocked_setup** · No configured carrier/region/phone pair and authorized RTT conversation partner; app has no RTT transport. Fresh Mac UI access unavailable; Developer mode disabled, prior two bounded runner starts executed zero methods; not a proved single cause. |
| OS Dictation | Documented system text dictation; iPad E11 specifically documents an Apple external-keyboard route. [E7] | **blocked_setup** · No enabled system dictation, chosen language/model and authorized acoustic session; own Speech/AVAudioEngine recognition is a separate API. Fresh Mac UI access unavailable; Developer mode disabled, prior two bounded runner starts executed zero methods; not a proved single cause. |
| OS Type to Siri | Documented keyboard requests to Siri, not HomeView text entry. Mac E14 is specifically Siri AI Beta/macOS27 with language/model restrictions. [E14] | **blocked_setup** · No configured and authorized Siri service session. No own shortcut invocation is counted as a Siri conversation. Fresh Mac UI access unavailable; Developer mode disabled, prior two bounded runner starts executed zero methods; not a proved single cause. |
| OS Vocal Shortcuts | User records/trains a phrase for a chosen action. [S9] | **blocked_setup** · No user-trained phrase or authorized acoustic invocation; AppShortcuts metadata does not train a Vocal Shortcut. Fresh Mac UI access unavailable; Developer mode disabled, prior two bounded runner starts executed zero methods; not a proved single cause. |
| Own App Shortcut | Registration/SDK metadata and direct intent/root body probes, not native Mac OS invocation. [assistant-app-shortcut.md, mac-runtime-boundary.md, fresh-Mac-boundary] | **blocked_host** · Mac interactive desktop unavailable and zero-method runner attempts; no direct perform substitution for OS use. |
| Own source-media captions | Shared public AVPlayer legible implementation compiles; native controller evidence is not a Mac UI run. [podcast-source-captions.md, mac-runtime-boundary.md, fresh-Mac-boundary] | **blocked_host** · Mac interactive desktop unavailable; actual Mac selection/cue/return not executed. |

## Apple TV

| Hilfsmittel | Belegter Umfang | Tatsächliche Grenze / Status |
|---|---|---|
| OS Live Speech | No positive specialized OS route established; NOT an OS unsupported claim. [N7, os-speech-settings-inventory-20261029.md, fresh-TV-guide] | **unresolved_os_path** · Native simulator menu also omits documented VoiceOver; catalog/menu/search absence is not qualified negative evidence. A reliable target-specific capability route remains unresolved. |
| OS Live Captions | Documented specifically for FaceTime on Apple TV4K. [N4] | **blocked_setup** · No configured FaceTime endpoint, authorized counterpart, matching hardware and language/region acceptance; not ambient or own podcast captions. |
| OS RTT | No positive specialized OS route established; NOT an OS unsupported claim. [N7, os-speech-settings-inventory-20261029.md, bounded-TV-Vision-searches] | **unresolved_os_path** · Same failed known-positive menu control; guide searches return other-platform/global-nav matches, not a TV RTT transport. |
| OS Dictation | Documented Siri/Search-button text dictation. [N8] | **blocked_setup** · No authorized remote microphone / actual Siri-remote dictation session; TV assistant keyboard does not establish dictation. |
| OS Type to Siri | Documented Type to Siri and screen/Bluetooth/iPhone/iPad keyboard paths. [N7, N8] | **blocked_setup** · No configured authorized Siri service/keyboard pairing or real system request; own local assistant is not Siri. |
| OS Vocal Shortcuts | No positive target-specific trained Vocal Shortcuts route established. [bounded-Vocal-Shortcuts-searches, N7] | **unresolved_os_path** · Search results describe Voice Isolation/Recognize My Voice, not user-trained Vocal Shortcuts. No unsupported-OS conclusion. Target route still unresolved. |
| Own App Shortcut | Own AppIntent/Provider excluded by explicit platform guard; no own shortcut registered. [Sources/App/AssistantAppShortcut.swift, assistant-app-shortcut.md] | **not_exposed_app** · Concrete app-scope/software omission; TV does not expose this action. No claim that the OS lacks every possible shortcut capability. |
| Own source-media captions | Shared legible selector/output code is present; no target-specific remote selection/cue run in this receipt. [podcast-source-captions.md] | **pending_runtime_validation** · Available TV runtime has not yet qualified this own-media flow. This is remaining software validation, NOT a hardware/API blockade. |

## Vision Pro

| Hilfsmittel | Belegter Umfang | Tatsächliche Grenze / Status |
|---|---|---|
| OS Live Speech | Specialized guide explicitly: unavailable outside calls; output at other end of call. Native settings row visibly Off. [N5, fresh-Vision-Live-Speech, os-speech-settings-inventory-20261029.md] | **blocked_setup** · No authorized configured call/counterpart or physical device acceptance. Own AVSpeechSynthesizer has no telephony uplink. |
| OS Live Captions | Apple documents system captions; capture/mirroring unavailable while enabled. [S5] | **blocked_setup** · No enabled authorized OS caption session / acoustic or call fixture; not activated to work around the capture restriction. |
| OS RTT | No positive specialized route established; NOT an unsupported-OS claim. [os-speech-settings-inventory-20261029.md, bounded-TV-Vision-searches] | **unresolved_os_path** · Native RTT search returns no result, but known visible Live Speech also returns no result; search not qualified as capability enumeration. |
| OS Dictation | Documented virtual keyboard Dictation and some Look to Dictate fields. [E1] | **blocked_setup** · No authorized real microphone/gaze dictation session; no system dictation activated. |
| OS Type to Siri | Accessibility > Siri > Type to Siri explicitly documented. [E2] | **blocked_setup** · No configured/authorized system Siri session or actual Siri text request. |
| OS Vocal Shortcuts | Explicitly documented user training of a chosen phrase/action. [N9] | **blocked_setup** · No user phrase training or acoustic invocation / physical acceptance. |
| Own App Shortcut | Actual OS provider discovered; three cold branches open own assistant from terminated process. No complete cold/warm method passed. [current-Vision-probes] | **partial_observed_open** · Warm source.activate path was occluded; restart-source path visibly fronts Shortcuts but HomeView stays behind after tap. Same HomeViewPID14688/normal args observed; AX field/draft survival is not a visible warm-return PASS. Cause not established; no product change invented. |
| Own source-media captions | Shared selector/output implementation present; no target-specific visible cue/selection run in this receipt. [podcast-source-captions.md] | **pending_runtime_validation** · Available Vision runtime has not yet qualified this own-media flow; remaining software validation, not an invented API/hardware blockade. |

## Apple Watch

| Hilfsmittel | Belegter Umfang | Tatsächliche Grenze / Status |
|---|---|---|
| OS Live Speech | Current watchOS27 guide documents type-to-speak in person and phone/FaceTime audio calls. [E13] | **blocked_setup** · No enabled voice/download/accessibility shortcut, acoustic/physical session or authorized call. WatchRoot has no own assistant/TTS. |
| OS Live Captions | Documented remote transcript display from nearby paired iPhone Live Listen, not standalone WatchASR. [N6] | **blocked_setup** · No paired nearby same-account iPhone, selected audio hardware and authorized iPhone-microphone Live Listen session. |
| OS RTT | Cellular-Watch RTT explicitly documented. [N3] | **blocked_setup** · No configured Cellular carrier/region/watch/iPhone setup or authorized conversation counterpart; simulator is not carrier acceptance. |
| OS Dictation | Native text entry guide documents Dictation and language limits. [E4] | **blocked_setup** · No real enabled Dictation/acoustic session; current WatchRoot has no assistant composer to claim an integration. |
| OS Type to Siri | Settings > Accessibility > Siri > Type to Siri documented. [E3] | **blocked_setup** · Siri setup on iPhone and internet required by guide; no configured authorized paired service session/request. |
| OS Vocal Shortcuts | Watch can run compatible iPhone shortcuts, including by Siri; distinct from trained Vocal Shortcuts. [E6, bounded-Vocal-Shortcuts-searches] | **unresolved_os_path** · No positive Watch user-trained Vocal Shortcuts route established; generic Shortcuts/Siri is not substituted. |
| Own App Shortcut | Provider excluded from Watch bundle; current WatchRoot has no assistant. [Sources/App/AssistantAppShortcut.swift, Sources/App/WatchRoot.swift] | **not_exposed_app** · Concrete app-scope/software omission, not proof of OS-wide impossibility. |
| Own source-media captions | Current WatchRoot does not expose Podcast AVPlayer/caption UI. [Sources/App/WatchRoot.swift, podcast-source-captions.md] | **not_exposed_app** · Concrete app-scope/software omission; phone captions do not count as Watch UI. |

## Aktuelle Vision-Systemaktion: begrenzter positiver Befund, kein Gesamt-PASS

Eigener neuer accountfreier visionOS27.0/24M362-Simulator, normale Demo-Einrichtung. Kurzbefehle zeigt genau eine eigene Aktion. In drei getrennten, vollständig gebundenen Fehlversuchen startet der Kaltzweig HomeView tatsächlich über den OS-Aktionstaster und erreicht das Assistentenfeld mit unveränderter initialer Antwort. Kein direktes perform(), kein Send; synthetischer Entwurf `temperature 73`.

Erste zwei Warmwege: HomeView liegt sichtbar vor dem Shortcuts-Fenster; der AX-Tipp ist nicht als korrektes räumliches OS-Ereignis qualifiziert, danach persönliche Demo-Ansicht statt Composer. Der letzte Versuch startet **nur Shortcuts** neu: die Quelle liegt nun sichtbar vorn, HomeView bleibt mit derselben PID14688 und ohne Fixture-Startargumente dahinter. AX meldet beide Vordergrundzustände und den alten Composerwert, aber die tatsächliche virtuelle Kamera zeigt keine sichtbare Rückkehr. Der letzte Kontrolltipp erreicht den Thermostat nicht; gesamte Methode FAIL. Weder PID-Gleichheit, AX-exists noch ein weiter existierender Entwurf beweisen die Zielwahl.

**Vier Ausführungen: eine reine Inventur bestanden, drei vollständige Kalt-/Warmmethoden fehlgeschlagen.** 14 öffentliche virtuelle Simulator-Kamerabilder, Quellen/kompilierte Inputs unverändert, vier Archive vollständig zurückgelesen, installierte App-/Runnerbytes geprüft. Früher fehlende dritte Aufnahme im ersten Fehlversuch bleibt als erwartete-Zustandszahl-Fehler erhalten. Keine Produktursache geraten und kein Produktcode geändert. [Belege/Digests](verification/speech-acceptance-observations-20261030.json) · [exakter letzter ausgeführter Diagnosequelltext](verification/vision-os-shortcut-probes/README.md).

Die temporären strikt UUID-begrenzten Normal-Sandbox-Proben sind nach Archivierung aus dem Standardtarget entfernt; sämtliche242 gelieferten Inputs wieder `09f9116`-gleich. Keine neuen Core-/Fünf-SDK-/Hardware-PASSes aus diesen Diagnosen. Raw-Systembilder und AX-Bäume mit Apples virtueller Umgebung bleiben privat.

## Was #74 noch tatsächlich offen hält

- Sichtbarer Vision-Warmaufruf/Zielwahl ist nicht nachgewiesen; kein bloßer Kompilier- oder Feldexistenz-PASS.
- TV-/Vision-Quellmedien-Untertexte haben verfügbare Runtimes, aber noch keine eigene aktuelle Interaktions-/Cue-Abnahme. Das ist offene Softwareprüfung, keine erfundene fehlende Hardware.
- TV Live Speech/RTT/Vocal Shortcuts sowie Vision RTT und Watch Vocal Shortcuts bleiben ohne positiven OS-Pfad. Fehlende Such-/Menütreffer werden wegen gescheiterter bekannter Positivkontrollen nicht als OS-Unmöglichkeit benutzt.
- Dokumentierte Systemhilfsmittel verlangen einzelne bewusste Einrichtung/Training, gewählte Sprache/Modelle oder Telefonie-/Carrier-/Gesprächsgegenpart. Geräte-/Signing-Hold bleibt; Mac-Desktopzugang ist aktuell erneut unavailable und Developer mode disabled, nicht als alleinige Timeoutursache bewiesen.

Kein Mikrofon, reale Kamera, Hilfsmittel aktiviert/trainiert, Account, Anruf, Nachricht oder Home. Keine erneute Freigabe angefragt. Die übrige autorisierte Softwarearbeit läuft weiter.

## Ergänzende offizielle Quellen

S1–S13: [20.Oktober-Bericht](speech-feature-boundaries.md); N1–N10: [29.Oktober-Bericht](speech-platform-update-20261029.md). Neue Abrufe unten30.Oktober: alleHTTP200, als ungekappt zurückgegeben; E5 enthält trotzdem nur Navigation und wird **nicht** als Sachbeleg verwendet. E13 ist der erfolgreiche versionierte Retry. Mac-E8 enthält keine Type-to-Siri-Zeile, daher kein negativer Schluss; E14 belegt den konkreten Siri-AI-Beta-Textpfad, nicht jede historische Version.
- **E1**: https://support.apple.com/guide/apple-vision-pro/enter-text-and-use-dictation-tana14220eef/visionos
- **E2**: https://support.apple.com/guide/apple-vision-pro/change-siri-accessibility-features-tane21826ac2/visionos
- **E3**: https://support.apple.com/guide/watch/how-to-use-siri-apd02f71f945/watchos
- **E4**: https://support.apple.com/guide/watch/enter-text-apdaf7837856/watchos
- **E5**: https://support.apple.com/guide/watch/type-to-speak-apd86a007717/watchos — Navigation-only, kein Sachbeleg.
- **E6**: https://support.apple.com/guide/watch/shortcuts-apd99050d435/watchos
- **E7**: https://support.apple.com/guide/mac-help/use-dictation-mh40584/mac
- **E8**: https://support.apple.com/guide/mac-help/change-siri-settings-for-accessibility-mchl5715a9f2/mac
- **E9**: https://support.apple.com/guide/iphone/dictate-text-iph2c0651d2/ios
- **E10**: https://support.apple.com/guide/iphone/change-siri-accessibility-settings-iphaff1d606/ios
- **E11**: https://support.apple.com/guide/ipad/dictate-text-ipad55d35a41/ipados
- **E12**: https://support.apple.com/guide/ipad/change-siri-accessibility-settings-ipadd58b8673/ipados
- **E13**: https://support.apple.com/guide/watch/type-to-speak-apd86a007717/27/watchos/27
- **E14**: https://support.apple.com/guide/mac-help/siri-ai-use-the-siri-app-q7ny3g54v9lk/mac
