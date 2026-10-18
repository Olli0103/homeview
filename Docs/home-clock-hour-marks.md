# Home Modular: Länge der Stundenmarkierungen

18. Oktober 2026 · [FACE-11 / #20](https://github.com/Olli0103/homeview/issues/20) bleibt offen.

Die zwölf Stundenmarkierungen der kleinen Glas-Uhr waren gegenüber UI07 zu kurz.
`AnalogClock` erhält einen Parameter `majorTickLength` mit dem bisherigen Standard
10. Nur die kleine Uhr von Home Modular verwendet 18 Entwurfspunkte. Strichstärke,
äußere Endpunkte, Winkel, Zeiger, Mittelpunkt, Layout und Glas bleiben unverändert.
Alle anderen Uhrenaufrufe behalten den bisherigen Standard. Keine kopierten
Originalgrafiken oder extrahierten Pfade.

[Eigene Vorher-/Nachher-Ansichten](screenshots/goal-20261018/home-clock-hour-marks-own-before-after.jpg) ·
[quellgebundener Nachweis und vorab gesetzte Grenzen](verification/home-clock-hour-marks.json) ·
[eigene Bilder/Hashes](screenshots/goal-20261018/home-clock-hour-marks-manifest.json).

## Kalibrierung und begrenzter Abschluss

Die erste 17-Punkte-Probe bestand ihre breiteren Grenzen, einige Querstriche
waren im direkten Originalvergleich noch kurz. Sie bleibt mit einem eigenen
Quellen-/Binärpaket erhalten. Die 18-Punkte-Kalibrierung erhielt vor dem Eingriff
engere normalisierte Längengrenzen von 0,0335 bis 0,0385. Weder der erste noch
der zweite einzelne Pilot wird zu den Abschlussausführungen addiert.

166 Modelltests, vierzehn gezielte iPad-/iPhone-Ausführungen und fünf SDK-Builds
bestanden. Keine UI-Fehler, Skips oder XCTest-Runtime-Warnungen. 142 Quellen und
das vollständige 20-Dateien-App-/Runner-/Testpaket blieben während der nativen
Prüfung unverändert. Feature-/Integrationsbytes exakt geprüft; Modelltests
danach wiederholt. Nur zwei App-Dateien geändert; alle bestehenden Tests und
140 anderen Quelldateien bytegleich zum Vorgänger.

Die isolierten 12-, 3- und 9-Uhr-Markierungen erfüllen tags/nachts auf beiden
Geräten die engeren Längengrenzen, bei erhaltener Strichstärke und pixelgenau
unveränderten äußeren Enden. Die iPad-Längen liegen um 0,0352 bis 0,0358;
die entsprechende Originalmessung liegt je Achse um 0,0349 bis 0,0368.
Das ist keine Behauptung identischer Originalkonturen.

**In vier Tages-/Nachtvergleichen außerhalb der Uhr exakt null geänderte Pixel.**
Auch innerhalb der Uhr liegen sämtliche Änderungen in den zwölf vorab aus der
eigenen öffentlichen Canvas-Geometrie definierten Markierungsbereichen. Die
lokale Intercom-Zielseite ist auf beiden Geräten RGBA-/PNG-bytegleich zum
Vorgänger; keine Durchsage. Thermostat-Symbol-/Rand-Taps, 68→69→68 und die
expliziten 62-Punkte-Rahmen bestehen unverändert.

146 finale eigene PNGs dekodiert; 64 repräsentative native Ansichten auf sechs
Kontaktbögen tatsächlich gesichtet. Je Gerät alle 32 Vollbilder über vier
Kaltstarts RGBA-/PNG-bytegleich; Bewegungs-Positivfall unterschiedlich,
Reduce-Motion-Paar exakt, ganze Nachtbilder ohne falsche Primärfarbpixel.
Keine neue RGB-Toleranz.

Acht unveränderte Ansichtsatlas-Ziele je Gerät sind RGBA-/PNG-exakt zu ihrem
separat eingefrorenen früheren Nachweisstand: Modular, Calendar, Numerals,
Fade, Wetter, Home Modular Clock, Home-Raster und Kalender-App. Das belegt
insbesondere den unveränderten Standard der anderen Uhren; es ist kein
vollständiger Pixelvergleich aller Atlas-Zustände oder aller App-Funktionen.

## Weiter offen

Zeigerform/-relief und Nabe der kleinen Uhr, Originalkonturen, Glaslicht,
Brechung, Schriftformen/andere Werte und physische Hardware bleiben offen.
Der frühere [echte OS-Schalter-Nachweis](prisms-system-reduce-motion.md) ist an
seinen älteren App-Payload gebunden und wurde hier nicht neu gezählt. Keine
Gesamt-Original-, Hardware- oder aktuelle vollständige UI-Suitenabnahme.
Nur synthetische Daten, keine realen Geräte, Konten oder Kommunikation.
