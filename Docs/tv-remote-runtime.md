# Native tvOS-Remote und erreichbare Timeraktionen

**Separater späterer Prüfstand:** [Native Kamera-Gegenkontrolle und fokussierbare Demo-Galerie](tv-camera-photos.md). Die hier folgenden früheren Timerzahlen bleiben an ihren ursprünglichen Stand gebunden.

29. Oktober 2026 · Teilumfang [#79](https://github.com/Olli0103/homeview/issues/79). **Tatsächlicher tvOS-Simulatorlauf**, kein umetikettierter iOS-/SDK-PASS.

## Laufzeit und reproduzierbarer Testaufbau

Über Xcodes offiziellen `-downloadPlatform tvOS -buildVersion 27.0 -architectureVariant arm64` wurden 3,76 GB heruntergeladen, extern exportiert **und durch Xcode installiert**. Der beobachtete Installer ist nicht nur ein Export. tvOS 27.0 / **24J360** ist verfügbar; eigener Apple-TV-4K-1080p-Simulator `DF210DF5-9CF4-4FBB-A9BA-6C6D59254324`. Export/QA-Artefakte liegen extern; die installierte Laufzeit liegt im von Apple verwalteten internen Runtime-Speicher. Keine Gateway-/TCC-/Developer-Tools-Konfiguration geändert.

Anfangs getrenntes Testprojekt mit bytegeprüfter Kopie der echten Produktquellen, keine nachgebaute Timer-/Fokuslogik. Danach direkt im Repository integriert: **`HomeViewTV`-Scheme**, `HomeViewTVUITests`-Target und [native Remote-Tests](../Tests/TVUITests/HomeViewTVUITests.swift). Der Projektgenerator erzeugt das Target reproduzierbar; iOS-/Watch-Schemes bleiben unverändert.

```sh
python3 Scripts/generate_project.py
xcodebuild test -project HomeViewReplica.xcodeproj -scheme HomeViewTV \
  -sdk appletvsimulator -destination 'id=<eigener-TV-Simulator>' \
  CODE_SIGNING_ALLOWED=NO
```

Jeder Test startet einen eigenen synthetischen UUID-Store. Tasten werden mit `XCUIRemote` gesendet; vor jeder Auswahl muss **das beabsichtigte Element tatsächlich `hasFocus` melden**. Geometrie, Fokuswechsel und echte Screenshots werden erhalten. Ein fixes Tastenmuster ist kein belastbarer Fokusbeleg.

## Reproduzierter Produktfehler und Korrektur

Nach Timerstart lag Fokus oben bei Schließen. Wiederholtes Abwärts erreichte die unteren Pause-/Löschaktionen nicht; auch Rechts zum oberen Plusknopf und Abwärts führte nicht dorthin. Die tatsächlichen Fokus-/Geometriereceipts zeigen zwei getrennte horizontale Bereiche ohne erreichbare vertikale Verbindung.

**Nur tvOS:** Die vorhandene Aktionszeile erhält eine über die freie Breite reichende SwiftUI-`focusSection()`. Keine neue Timer-/Fristen-/Speicherlogik, kein anderer Plattformzweig geändert. Die identische eingefrorene Dreiermatrix besteht anschließend vollständig: vorher **2 bestanden / 1 echter Timer-Fokusfehler**, danach **3 bestanden / 0 Fehler**. Pause und Löschen werden danach tatsächlich per Remote ausgewählt; nicht programmatisch im Modell ausgelöst.

Frühere Testfehler bleiben separat: Das feste Starttastenmuster war unzuverlässig; „Apps“ öffnet zunächst den persönlichen Home Screen, nicht direkt das Raster. Der korrigierte Ablauf benutzt den sichtbaren „All Apps“-Knopf. Diese Vorbereitung wird nicht als zusätzlicher Produktfehler gezählt.

## Aktueller integrierter Stand

| Ziel | Tatsächliche Ausführung | Ergebnis |
|---|---|---|
| tvOS 27.0 / 24J360 | Start und sechs Remote-Richtungsaktionen; persönliche Home-/All-Apps-/Timer-Navigation; Timer starten/pausieren/löschen; Browser-Demogrenze und Menü-Rückkehr | **4/4 Methoden bestanden** |
| iPhone 18 Pro, iOS 27.0 / 24A434 | Bestehende Touch-Timerregression: starten/pausieren/fortsetzen/löschen | **1/1 bestanden** |
| iPad Air 11-inch M4, iPadOS 27.0 / 24A434 | Dieselbe bestehende Touch-Timerregression | **1/1 bestanden** |
| Fünf SDK-Ziele | arm64-Builds aus identischen aktuellen Quellen | **5/5 bestanden**, nicht fünf Runtime-Abnahmen |

**Sechs aktuelle UI-Ausführungen**, null Fehler/Skips/strukturierte Runtime-Warnungen. Alle **227 Quellen**, neun gesamte Ausführungsarchive und jeweilige installierte Appbytes geprüft. Aktueller Quelldigest `31546980f5c68179c3571b71d56c67699fd94cfc900b1f4cc2109fcb2061a93d`.73 SDK-Produktdateien archiviert/zurückgelesen,88 Core-/Paket-/Testinputs unverändert, kein neuer Core-Lauf.77 PNGs dekodiert, elf tatsächliche Übersichtsseiten gesichtet; acht eigene Bilder veröffentlicht.

Die vollständige Historie umfasst23 Ausführungen:18 bestanden,5 frühere Fehler. Frühere grüne Wiederholungen werden nicht zur aktuellen Sechserabnahme addiert. Ein Wrapper übergab im ersten integrierten TV-Lauf irrtümlich zusätzlich `iphonesimulator`; die strukturierte Ausführung war trotzdem tvOS, aber der aktuelle finale Viererlauf wurde mit korrigiertem `appletvsimulator`-Argument gegen **identische kompilierte TV-Dateien** ausgeführt. Ein vorzeitiger Attachment-Leseversuch vor fertigem Ergebnis wird nicht als App-Fehler gewertet.

[Quellen, Einzelstände, Fokus-/Archiv-/Produktbindung und Bilder](verification/tv-remote-runtime.json). Private Rohdaten: `research/homeview-tv-runtime-20261029` auf externem Artefaktspeicher.

## Weiter offen

TV verwendet hier keinen WebKit-Browser; tatsächlich sichtbar ist die gebündelte Offline-Kochbuch-Demoseite ohne Adressfeld. Das ist kein Web-Browsing-PASS. Kamera-/Fotopfade sind in diesem Paket noch nicht nativ abgenommen. Kein echtes TV-Gerät, Mikrofon, gekoppelte Remote-/Audiohardware, Energie-/Framezeitmessung, persönliche Accounts, Anruf oder Home-Zugriff.

Mac-, Vision- und Watch-Bedienung bleiben eigene Teilabnahmen. Der frische Gateway-Screenshotversuch meldet weiter einen nicht verfügbaren Computerprovider; nichts dafür eingeschaltet oder umgangen. Watch-Runtime wurde inzwischen separat offiziell installiert, daraus allein folgt noch kein Watch-Funktionstest. **#79 bleibt offen.** Geräte-/Signing-Hold bleibt bestehen und pausiert nicht die übrige Softwarearbeit.
