# Native visionOS-Fenster, Eingabe und gebundene Simulatorbilder

29. Oktober 2026 · Teilumfang [#79](https://github.com/Olli0103/homeview/issues/79), keine physische Headset-/Originalabnahme.

## Tatsächlich ausgeführter Umfang

Offizielle arm64-Laufzeit **visionOS27.0 / 24M362**,7,52GB, durch Xcode installiert und extern exportiert. Eigener konto-freier Vision-Pro-4K-Simulator `D52824FF-D0CF-4397-A0C5-4E21F26CE31D`. Apple verwaltet die installierte Laufzeit intern; Exporte, Testbuilds und Rohbelege liegen extern.

Das neue `HomeViewVision`-Scheme / `HomeViewVisionUITests`-Target wird vom Projektgenerator reproduzierbar erzeugt. [Vier native Methoden](../Tests/VisionUITests/HomeViewVisionUITests.swift) bestehen aktuell:

| Methode | Beobachtete Wirkung |
|---|---|
| Fenster und Mock-Thermostat | Vollständiger Referenz-Viewport und alle vier Footer-Kontrollen innerhalb des tatsächlichen AX-Fensters, hittable; echter Tap öffnet68°-Mock-Thermostat |
| Lokaler Timer | Start, Pause mit sichtbarem Resume-Control, Löschen zurück zur Startansicht |
| Assistenteneingabe | Tatsächliches Textfeld enthält `OWNED VISION DRAFT`; nichts gesendet |
| Lokaler Browser | Tatsächlicher WebKit-Inhalt `Garden Tomato Pasta`, gebündelte Fixture ohne Netzanforderung |

**4/4 aktuelle UI-Ausführungen**, null Fehler/Skips/strukturierte Laufzeitwarnungen. Eigene UUID-Stores, UITesting-/Referenzuhr-Fixtures. Alle **165 Produktquell-/Ressourcendateien unverändert** zum Watch-Stand `6eaf5f7`: kein Vision-Renderer oder Dienst für diesen Nachweis erfunden.231 gesamte Quellen einschließlich eigener Targets/Tests/Capture-Helfer, kompilierte App-/Test-/Launcheingaben und vier Ausführungsarchive vollständig zurückgelesen; installierte Appbytes jeweils geprüft.

Aktueller Quelldigest `e6750e21f2597249e4669b00d77876859e8b0483aca8bf7804dadd500c5aabaa`.88 Core-/Paket-/Testinputs unverändert, kein neuer Core-Lauf. Neuer visionOS-Testbuild; die [vorherigen fünf SDK-Builds](watch-native-runtime.md) bleiben separat datiert, keine vier neuen anderen Plattformbuilds behauptet.

## Capture-Grenze ist kein Produkt-Layoutfix

`app.screenshot()` liefert hier1280×720-PNGs mit einem abgeschnittenen Renderausschnitt. Die AX-Geometrie und die tatsächliche virtuelle Simulatoransicht zeigen dagegen den vollständigen Inhalt. `XCUIScreen.main.screenshot()` ergab im gezielten Probeversuch nur1×1Pixel. Ein zunächst verwendeter falscher Test-API-Aufruf kompilierte nicht; **null UI-Methoden** aus diesem Vorbereitungsschritt, kein Appfehler daraus.

Der Bildnachweis verwendet daher die öffentliche **`simctl io screenshot`-Ansicht des virtuellen Simulators**, keine physische Kamera. Die Tests markieren und halten fünf konkrete Zustände. [Capture-Helfer](../Scripts/capture_vision_states.py) liest diese Marker, sichert ohne Überschreiben und bindet Anfang/Ende jeder Aufnahme an das native READY/DONE-Zeitfenster. Ein früher5-Sekunden-Halt hatte zwei zu spät abgeschlossene Aufnahmen; dieser Stand bleibt für die Bildabnahme unzureichend.

Im aktuellen10-Sekunden-Runloop-Halt liegen **alle fünf vollständigen Capture-Operationen innerhalb ihres jeweiligen Fensters** (beobachtet0,398–0,785Sekunden). Alle fünf3840×2160-Kamerabilder dekodiert und tatsächlich gesichtet. Öffentlich liegen nur ausgewiesene eigene Fenster-Crops, ohne Skalierung oder Perspektivkorrektur; Originalframes einschließlich Simulatorumgebung bleiben privat. Das ist kein nativer600-Pixel-Originalvergleich und kein Nachweis physischer Blick-/Handbedienung.

```sh
python3 Scripts/generate_project.py
python3 Scripts/capture_vision_states.py \
  --device '<eigener-Vision-Simulator>' --output '<neues-Artefaktverzeichnis>' \
  --expected-states 5 -- xcodebuild test \
  -project HomeViewReplica.xcodeproj -scheme HomeViewVision \
  -sdk xrsimulator -destination 'id=<eigener-Vision-Simulator>' \
  -derivedDataPath '<externes-Buildverzeichnis>' \
  CODE_SIGNING_ALLOWED=NO
```

Die UI-Methoden sind auch direkt per `xcodebuild test` ausführbar; ohne Capture-Helfer werden die Haltezustände nicht automatisch zu vollständigen Systembildern. Historie13 erfolgreiche Methoden-Ausführungen über getrennte QA-Pins, nicht13 aktuelle Methoden.19 XCTest-PNGs einschließlich zweier unbrauchbarer1×1-Bilder sind erhalten; vier Übersichten und die fünf aktuellen vollen Kameraframes wurden gesichtet. [Quellen-/Zeit-/Ergebnis-/Cropbindung](verification/vision-native-runtime.json), Rohbelege `research/homeview-vision-runtime-20261029` extern.

## Offen

Nur kontrollierte Simulator-Fixtures und eine beobachtete Fensterkonfiguration. Keine Größenänderungs-/Mehrfensterabnahme, normaler signierter Headsetbetrieb, ältere OS-Version, Blick-/Handtracking, räumliche Gesten, reale Quellenfreigaben, Kamera/Mikrofon, externe Webdienste, Anrufe oder Home-Anbindung. **#79 bleibt offen** für seine übrigen Plattform-/Gerätekriterien; Signing-/Geräte-Hold und Home-Sperre unverändert. Andere Softwarearbeit läuft weiter.
