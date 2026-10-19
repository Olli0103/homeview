# Sprache und Untertitel: eigene App, OS-Hilfsmittel und offene Arbeit

20. Oktober 2026 · [#74 / SYS-11](https://github.com/Olli0103/homeview/issues/74) · Codebefund `441f78a`.

**Recherche und Quellprüfung, keine Hilfsmittel-/Hardwareabnahme. #74 bleibt offen; F104/F105 bleiben ohne Parity.** Diese Funktionen sind nicht durch ein einziges Textfeld erfüllt.

**Fortschritt nach diesem Quellbefund:** [Eigener App-Shortcut-Einstieg](assistant-app-shortcut.md) mit Compilermetadaten und direkter nativer Body-/Root-Prüfung. Die unten beschriebene fehlende Registrierung gilt für den datierten Stand `441f78a`; tatsächliche Systemausführung bleibt offen.

## Eigener Lieferumfang

| Funktion | Tatsächlicher HomeView-Code | Was daraus nicht folgt |
| --- | --- | --- |
| Assistententext | Eigene Eingabe/Vorschau, ausdrücklich senden; reguläre RootView auf iOS/iPadOS, macOS, tvOS und visionOS. WatchRoot enthält keinen Assistenten | kein „Type to Siri“, kein Zugriff auf Siris Gespräch |
| Spracheingabe | Eigener Speech-/AVAudioEngine-Pfad nur iOS/iPadOS und macOS; explizites Speak, Berechtigungen, vorhandenes On-device-Modell, kein Cloud-Fallback | keine systemweite Dictation und keine akustische Hardwareabnahme; andere Ziele verwenden diesen Capture-Pfad nicht |
| Antwort vorlesen | AVSpeechSynthesizer auf iOS/iPadOS, macOS und visionOS; tvOS/watchOS ausgeschlossen. Persönliche Stimmen werden herausgefiltert; kein Telephony-Uplink | kein System-Live-Speech, kein Personal Voice, keine eingespeiste Telefonstimme |
| Live Captions | kein eigener kontinuierlicher Medien-/Umgebungstranskriptionsdienst | Apples OS-Hilfsmittel ist keine eigene Integration |
| RTT | kein eigener RTT-Transport, Zeichensendeprozess oder Telefonie-Stack | Chatentwurf und externe Telefonübergabe sind kein RTT |
| App Shortcuts | kein `AppIntent` oder `AppShortcutsProvider` in Sources | vorhandene Tastaturkürzel sind keine registrierten Sprach-/App-Kurzbefehle |
| Medienuntertitel | eigener Podcastpfad spielt Audio über AVPlayer; keine eigene Legible-Track-Auswahl oder Video-Caption-Oberfläche | Antworttext, Kalender-„subtitle“ und Songtexte sind keine zeitcodierten Untertitel |

Quellorte: `NativeVoice.swift`, `NativeAnswerSpeech.swift`, `Controls.swift`, `PodcastPlayback.swift`, `RootView.swift`, `HomeViewApp.swift`, `WatchRoot.swift`. [Dateidigests und abgegrenzte Befunde](verification/speech-feature-boundaries.json). Die kompilierten Guards sind Quellbefunde, keine neuen Plattform-Laufzeittests.

## OS-Unterstützung getrennt je Ziel

„Dokumentiert“ bedeutet nur: Die genannte Apple-Seite beschreibt die OS-Funktion. **Keine davon wurde eingeschaltet oder mit HomeView bedient.** „Ungeklärt“ ist kein „API unmöglich“ oder „OS nicht unterstützt“. Sprach-, Regions-, Geräte- und Anbieterbedingungen gelten zusätzlich.

| Ziel | Live Speech | Live Captions | RTT | Vocal Shortcuts |
| --- | --- | --- | --- | --- |
| iPhone | dokumentiert [S1] | dokumentiert, iPhone 11+, Sprache/Region [S3] | Mac-Dokument nennt aktiviertes iPhone-RTT als Voraussetzung; eigene iPhone-RTT-Abnahme fehlt [S6] | dokumentiert, vom Nutzer trainiert [S7] |
| iPad | dokumentiert [S1] | dokumentiert; eigene aktuelle Modellliste [S2, S13] | in diesem Paket ungeklärt | dokumentiert, vom Nutzer trainiert [S8] |
| Mac | dokumentiert; Apple-Silicon-Bedingung in S1 | dokumentiert, Apple Silicon, Sprache/Region; erster Sprachdatendownload [S4] | dokumentiert, gekoppeltes iPhone/WLAN-Telefonie, aktiviertes RTT, Anbieter/Region [S6] | dokumentiert, Apple Silicon, vom Nutzer trainiert [S9] |
| Apple TV | in diesem Paket ungeklärt | in diesem Paket ungeklärt; nicht mit Medienuntertiteln verwechseln | in diesem Paket ungeklärt | in diesem Paket ungeklärt |
| Vision Pro | in diesem Paket ungeklärt | ausdrücklich dokumentiert; eingeschaltet kein Aufzeichnen/Spiegeln der Ansicht [S5] | in diesem Paket ungeklärt | ausdrücklich dokumentiert, vom Nutzer trainiert [S10] |
| Apple Watch | dokumentiert [S1] | in diesem Paket ungeklärt | in diesem Paket ungeklärt | in diesem Paket ungeklärt |

S1 ist ein weiterhin abrufbarer Apple-Supportartikel mit Veröffentlichungsdatum **14. Dezember 2023**. Er belegt die genannten Produktfamilien und damaligen Voraussetzungen, keine vollständige aktuelle Gerätekatalog-Zertifizierung. Neuere Guide-Seiten zeigen teils Version 27. Beispielsweise listet die aktuelle iPad-Live-Captions-Seite mehr unterstützte Modelle als der alte Live-Speech-Artikel; die zwei Listen dürfen nicht vermischt werden.

## Öffentliche umsetzbare App-Arbeit

### App Intents und App Shortcuts

Apple beschreibt `AppIntent`, `AppShortcutsProvider` und `AppShortcut` als öffentliche deklarative App-Einstiegspunkte [S11]. Der Compiler erzeugt Metadaten; deren Existenz ist weder eine ausgeführte Siri-Sitzung noch Besitz eines systemweiten Wakewords. Die installierte öffentliche SDK-27-Schnittstelle enthält diese Verträge und `supportedModes`; `openAppWhenRun` verweist für neuere Systeme auf `supportedModes`. SDK-Deklaration, jeweilige Plattformdarstellung und tatsächliche Ausführung bleiben getrennte Nachweise.

**Konkrete Softwarelücke:** HomeView stellt noch keinen solchen Einstieg bereit. Ein begrenzter nächster Schritt ist „HomeView-Assistent öffnen“: ausschließlich eigene Oberfläche in den Vordergrund, kein automatisches Senden/Abspielen, keine Aufnahme, keine Freigabe persönlicher Inhalte und kein Home-Zugriff. Eine fehlende Registrierung ist keine öffentliche API-Blockade. App-Ausführung, kalter/warm gestarteter Zustand und Metadatenextraktion sind vor einer Integrationsbehauptung zu prüfen; Siri-/Vocal-Shortcut-Ausführung bleibt eigene Geräteabnahme.

### Untertitel für eigene Medien

AVFoundation bietet `AVMediaSelectionGroup`, `AVMediaSelectionOption`, die Mediencharakteristik `.legible` und Auswahl über `AVPlayerItem.select(_:in:)`; AVKit/AVPlayerLayer können entsprechende Spuren darstellen [S12]. Das setzt tatsächlich vorhandene Medien-/Untertitelspuren voraus. Die API erzeugt aus einem Audio-Podcast keine Untertitel und liest nicht automatisch fremde App-/Anrufinhalte aus.

**Konkrete Softwarelücke:** kein eigener Caption-fähiger Video-/Track-Auswahlpfad und kein synthetischer Untertitel-Playbacknachweis. Falls eigene Videoangebote aufgenommen werden, zuerst eigenes Video plus eigene WebVTT-/Untertitelspur, Auswahl/Aus/fehlende Spur und Rendernachweis prüfen. Für den vorhandenen Audio-Podcast keine leeren Caption-Schalter oder erfundenen Texte anbieten.

### OS-Hilfsmittel und Telefonie

Live Speech, Live Captions und Vocal Shortcuts werden laut Apple bewusst in den Systemeinstellungen eingerichtet; Vocal Shortcuts verlangen eigenes Training. HomeView aktiviert oder trainiert hier nichts. Eigene Antwortausgabe und Speech-Erkennung ersetzen diese Dienste nicht. RTT auf dem Mac hängt laut Apple von der Telefonieeinrichtung und Anbieterbedingungen ab [S6]; HomeView besitzt weder den Anruf noch einen RTT-Kanal. Daraus wird keine pauschale Aussage abgeleitet, dass sämtliche denkbaren RTT-APIs unmöglich seien.

## Noch benötigte Abnahme

- Eigener öffentlicher App-Einstieg und synthetischer Kalt-/Warmstartnachweis, ohne implizite Aktion.
- OS-Funktion je tatsächlich vorhandenem Zielgerät, Sprache/Region und Hilfsmittel protokollieren; echte Dictation und Type to Siri ausdrücklich separat.
- Für eigene Medien tatsächliche Untertitelspuren prüfen; kontinuierliche Live Captions nicht mit Textdarstellung gleichsetzen.
- RTT nur mit ausdrücklich autorisierter passender Telefonie-/Anbieterkonfiguration prüfen. Keine Anrufe oder Nachrichten als Teil dieser Recherche.
- Die als ungeklärt markierten Zellen weiter klären, nicht aus einer leeren Suche als „nicht unterstützt“ deklarieren.

## Quellen

Abruf 20. Oktober 2026 (Europe/Berlin), sofern nicht anders datiert. Nur die hier benannten Abschnitte wurden ausgewertet. Einige normale Guide-Abrufe enthielten nur Navigation; verwertbare Haupttexte wurden anschließend separat extrahiert. Ein Suchprovider lieferte zeitweise 429; fehlende Suchresultate werden nicht als fehlende Fähigkeit gewertet. Bei S4, S11 und S12 ist der Abruf nach den für die Aussagen benötigten Abschnitten gekürzt, nicht die gesamte verlinkte API-Sammlung geprüft.

- **S1:** [Apple: Live Speech auf iPhone, iPad, Mac oder Watch](https://support.apple.com/en-us/105018), veröffentlicht 14.12.2023.
- **S2:** [Apple: Live Captions auf iPad](https://support.apple.com/guide/ipad/get-live-captions-of-spoken-audio-ipad0bbca12e/ipados).
- **S3:** [Apple: Live Captions auf iPhone](https://support.apple.com/guide/iphone/get-live-captions-of-spoken-audio-iphe0990f7bb/ios).
- **S4:** [Apple: Live Captions auf Mac](https://support.apple.com/guide/mac-help/get-live-captions-of-spoken-audio-mchldd11f4fd/mac).
- **S5:** [Apple: Live Captions auf Vision Pro](https://support.apple.com/guide/apple-vision-pro/live-captions-tan0b3d5c0c9/visionos).
- **S6:** [Apple: RTT-Einstellungen auf Mac](https://support.apple.com/en-us/guide/mac-help/mchlf4b091e8/mac).
- **S7:** [Apple: Vocal Shortcuts auf iPhone](https://support.apple.com/guide/iphone/use-vocal-shortcuts-iph7f242ea2c/ios).
- **S8:** [Apple: Vocal Shortcuts auf iPad](https://support.apple.com/guide/ipad/use-vocal-shortcuts-ipaddc8c53732/ipados).
- **S9:** [Apple: Vocal Shortcuts auf Mac](https://support.apple.com/guide/mac-help/use-vocal-shortcuts-mchlf4548bb6/mac).
- **S10:** [Apple: Vocal Shortcuts auf Vision Pro](https://support.apple.com/guide/apple-vision-pro/use-vocal-shortcuts-tan268d29519/visionos).
- **S11:** [Apple Developer: App Shortcuts](https://developer.apple.com/documentation/appintents/app-shortcuts), Overview und Provider/Metadatenerzeugung.
- **S12:** [Apple Developer: Untertitel und alternative Audiospuren](https://developer.apple.com/documentation/avfoundation/selecting-subtitles-and-alternative-audio-tracks), Mediencharakteristiken, Gruppen und Auswahl.
- **S13:** [Apple: Aktuelle iPad-Live-Captions-Modelle](https://support.apple.com/guide/ipad/aside/ipadceadad54/27/ipados/27).

Keine Rohlogs, SDK-Header oder proprietären Bilder veröffentlicht. Kein neuer Build-/UI-/Hardware-PASS und **keine Home-Anbindung** durch dieses Dokumentationspaket.
