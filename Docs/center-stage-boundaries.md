# Center Stage: öffentliche Verträge, tatsächliche Kamera noch offen

20. Oktober 2026 · [#43 / COM-02](https://github.com/Olli0103/homeview/issues/43) · [Quellen und Compile-Verträge](verification/center-stage-boundaries.json)

**#43 bleibt OPEN, F055 research/parity=false.** Öffentliche API-Verfügbarkeit ist belegt, aber weder die konkrete physische Zielkamera noch Mehrpersonen-Bildführung wurden geprüft. Daraus wird kein „Hardware nicht unterstützt“ erfunden. Das ursprüngliche Kriterium verlangt eine bewusst gestartete Aufnahme auf geeignetem Testgerät oder einen tatsächlich dokumentierten nicht verfügbaren Zustand; der hier unbekannte physische Zustand erfüllt es nicht.

## Positive Systemfähigkeit und Hardware

Die vollständig gelesene [Apple-Anleitung](https://support.apple.com/en-us/111102), veröffentlicht am 12. Mai 2026, beschreibt automatische Bildführung ausdrücklich: Personen bleiben bei Bewegung im Bild; der Bildausschnitt wird angepasst. Auf dem iPhone unterscheidet sie zudem automatische Foto-Rotation/-Erweiterung von der Videoanruf-Bildführung. Diese zusätzlichen Fotofunktionen werden hier nicht als bereits implementierte AVFoundation-Videofunktionen ausgegeben.

Die Quelle nennt kompatible Apps und unter anderem folgende Hardware-/Kamerapfade:

- iPad Pro 11 Zoll ab 3. Generation beziehungsweise 12,9 Zoll ab 5. Generation, iPad Air ab 5., iPad ab 9. und iPad mini ab 6. Generation, jeweils Frontkamera. Dies ist Quellenwortlaut, kein negativer Eignungsbeweis für ein hier nicht separat untersuchtes anderes Modell.
- Mac über geeignete Continuity Camera mit iPhone 11 oder neuer ohne SE-Modelle; geeignete eingebaute Kameras neuer MacBook Pro ab 2024, Air ab 2025 und iMac ab 2024; Kamera von Studio Display oder Studio Display XDR. Das ist kein Nachweis für einen konkreten angeschlossenen Sensor, Account oder Verbindungspfad dieses Nutzers.
- Die Anleitung nennt außerdem die Frontkamera von iPhone 17, iPhone Air und iPhone 17 Pro. Kein pauschales „nur iPad“ oder „jede iPhone-Kamera“.

Auf iPad erfolgt die Nutzersteuerung in den App-Kontrollen des Kontrollzentrums, bei iPadOS 17 oder älter unter Video Effects; FaceTime bietet zusätzlich eigene Kameraeffekt-Bedienelemente. Auf macOS 14+ gibt es das Video-Menü, auf macOS 12/13 die Video Effects im Kontrollzentrum. Diese dokumentierten Bedienwege wurden nicht aufgerufen oder verändert.

## Drei Zustände, die nicht gleichgesetzt werden dürfen

| Öffentlicher Vertrag | Bedeutung | Noch kein Beweis für |
| --- | --- | --- |
| [activeFormat.isCenterStageSupported](https://developer.apple.com/documentation/avfoundation/avcapturedevice/format/iscenterstagesupported) | Das konkrete Aufnahmeformat unterstützt die Funktion. | Dass Nutzer/App sie aktiviert haben oder sie gerade Bilder führt. |
| [AVCaptureDevice.isCenterStageEnabled](https://developer.apple.com/documentation/avfoundation/avcapturedevice/iscenterstageenabled) | Die Funktion ist durch Nutzer oder App aktiviert. | Dass die aktuelle Kamera-/Sessionkonfiguration sie tatsächlich ausführt. |
| [device.isCenterStageActive](https://developer.apple.com/documentation/avfoundation/avcapturedevice/iscenterstageactive) | Auf diesem Gerät in dieser Konfiguration tatsächlich aktiv. | Dass die Bildführung mit mehreren Personen auf dem Zielgerät bereits abgenommen wurde. |

Bei aktivem Center Stage können sich verfügbare Zoom- und Framerate-Grenzen ändern. Tiefendatenausgabe kann es deaktivieren; bei unterstützter geometrischer Verzerrungskorrektur muss diese aktiviert sein. Die tatsächliche Kombination aus Format, Sessionausgaben und aktueller Konfiguration muss deshalb geprüft werden. Ein einmaliges globales Enabled-Flag reicht nicht. Active und Enabled sind laut Vertrag KVO-beobachtbar; hier wurden keine Werte abgefragt.

## Nutzerkontrolle nicht stillschweigend übernehmen

[centerStageControlMode](https://developer.apple.com/documentation/avfoundation/avcapturedevice/centerstagecontrolmode-swift.type.property) und die vollständig gelesenen drei Modi definieren unterschiedliche Rechte:

- [.user](https://developer.apple.com/documentation/avfoundation/avcapturedevice/centerstagecontrolmode-swift.enum/user): ausschließliche Nutzersteuerung im Kontrollzentrum. Ein programmatisches Enabled-Setzen löst in diesem Modus eine Exception aus. Der öffentliche Header bezeichnet ihn als Default, nicht als hier gemessenen aktuellen Wert.
- [.app](https://developer.apple.com/documentation/avfoundation/avcapturedevice/centerstagecontrolmode-swift.enum/app): ausschließliche App-Steuerung, Nutzersteuerung im Kontrollzentrum wird unterbunden. Kein harmloser automatischer Setup-Schritt.
- [.cooperative](https://developer.apple.com/documentation/avfoundation/avcapturedevice/centerstagecontrolmode-swift.enum/cooperative): geteilte Steuerung; die App muss Nutzerabsicht respektieren, Enabled-Änderungen beobachten und ihre Konfiguration entsprechend nachführen.

Hier wurde kein Modus ausgewählt, kein Setter aufgerufen und keine Systemeinstellung verändert. Das API-Angebot ist eine vorhandene öffentliche Lösung; ein eigener Gesichtsverfolgungs-/Crop-Algorithmus oder eine neue Bibliothek ist dafür nicht automatisch nötig und wurde nicht eingebaut.

## SDK, HomeView und FaceTime getrennt

Fünf gezielt gelesene öffentliche AVCaptureDevice-Header und acht aktuelle DocC-Verträge belegen den beschriebenen API-Umfang. Dieselbe unaufgerufene Swift-Funktion wurde ausschließlich typegeprüft: iOS/iPadOS, natives macOS und tvOS positiv; watchOS und visionOS mit erwarteten ausdrücklichen Unavailable-Diagnosen für diese Center-Stage-Properties. Deklarierte Mindeststände sind iOS/Catalyst 14.5, macOS 12.3, tvOS 17. Catalyst wurde hier nicht zusätzlich kompiliert. Kein pauschales „kein AVFoundation auf visionOS“ und keine Hardwareableitung aus erfolgreichem Typecheck.

HomeViews aktueller NativeMirror-Pfad ist enger als das öffentliche SDK: Live-Capture-Code ist auf iOS/macOS begrenzt. Erst das ausdrückliche Use Camera erzeugt den Controller und fragt Videoberechtigung an. Er wählt derzeit Front-Wide-Angle beziehungsweise eine Default-Kamera, ohne Center-Stage-fähiges Format oder aktiven Center-Stage-Zustand zu belegen. Spiegelung und SwiftUI-mirrorZoom sind keine automatische Bildführung. Die Mockansicht startet keine Kamera; auf anderen App-Zielen ist der vorhandene Mirror ein Mock-Fallback, nicht der Beweis einer generellen SDK-Unmöglichkeit.

Eine eigene AVFoundation-Session und deren Kameraeigenschaften sind **keine Steuerung der fremden FaceTime-Sitzung**. FaceTimes dokumentierte Bedienelemente und ein normaler System-Handoff verleihen HomeView keinen Zugriff auf dessen laufende Teilnehmer-/Kamerakonfiguration. Siehe die bereits getrennte [FaceTime-Grenze](facetime-control-boundary.md). Kein Anruf wurde gestartet.

## Geräteplan – nicht ausgeführt

1. Bewusst gewähltes physisches Zielgerät und tatsächlich verwendete Kamera/Format lokal erfassen; Berechtigung nur aus ausdrücklicher App-Aktion. Unbekannt, verweigert, keine Kamera und Format nicht unterstützt getrennt ausweisen.
2. Supported/Enabled/Active getrennt beobachten; Kamera-/Formatwechsel und relevante Session-/Zoom-/Framerate-Grenzen nachführen.
3. Nutzersteuerung prüfen, ohne eigenmächtig exklusiven App-Modus zu setzen; ein Ausschalten durch den Nutzer darf nicht als weiter aktive Bildführung angezeigt werden.
4. Bewusster Ein-/Mehrpersonen-Bewegungsfall mit dem geeigneten Kamerabild, Aktivitätsnachweis und beobachteter Ausschnittänderung; keine synthetische App-Zoomanimation als Hardware-PASS.
5. Stop/Neustart, Hintergrund und Format-/Output-Konflikte prüfen. Eigene Session von separatem FaceTime-Systembedienweg unterscheiden.

Keine dieser Geräte-Lanes wurde ausgeführt. Keine neue App gebaut oder gestartet, keine UI-/Modelltests oder Bilder für diese Recherche beansprucht. Alle 206 Produkt-/Test-/Ressourcen-/Projekt-/Scriptdateien bleiben bytegleich zu 13782ca. Keine Capture-Session, Discovery oder Kamera instanziiert, keine Berechtigung angefragt, keine Frames aufgenommen, keine Property gelesen/gesetzt und keine Home-Anbindung.
