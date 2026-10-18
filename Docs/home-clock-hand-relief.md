# Home Modular: Zeigerrelief, Minutenlänge und offene Nabe

18. Oktober 2026 · [FACE-11 / #20](https://github.com/Olli0103/homeview/issues/20) bleibt offen.

Nur die kleine Home-Modular-Uhr verwendet jetzt den bereits vorhandenen
Relief-Renderer: schmale Ansätze statt breiter gekreuzter Rückenden, leichte
Schattierung und Minutenreichweite 0,96 statt 0,84. Stundenreichweite, Zeitwinkel,
Stundenmarkierungen, Layout und Glas bleiben erhalten. Eine optionale eigene
Ringnabe aus zwei analytischen Ellipsen lässt den Hintergrund in der Mitte
sichtbar; die Zeigerzeichnung spart diesen Innenbereich aus. Andere Uhren
behalten ihre vorherige gefüllte Nabe und ihre bisherigen Aufrufparameter.
Keine kopierten Originalkonturen oder Referenzgrafiken.

[Eigene Vorher-/Nachher-Ansichten](screenshots/goal-20261018/home-clock-hand-relief-own-before-after.jpg) ·
[quellgebundener Nachweis mit vorab gesetzten Grenzen](verification/home-clock-hand-relief.json) ·
[eigene Bilder/Hashes](screenshots/goal-20261018/home-clock-hand-relief-manifest.json).

## Begrenzte Bild- und Softwareprüfung

Der erste Zeigerpilot mit noch gefüllter Nabe bleibt als eigener Quellen- und
Binärstand erhalten. Er bestand seine Grenzen; die vergrößerte Originalansicht
zeigte anschließend die offene Mitte als weitere Abweichung. Weder dieser noch
der danach bestandene einzelne Nabenpilot wird zu den Abschlussfällen addiert.

166 Modelltests, vierzehn gezielte iPad-/iPhone-Ausführungen und fünf SDK-Builds
bestanden. Keine UI-Fehler, Skips oder XCTest-Runtime-Warnungen. 142 Quellen und
das vollständige 20-Dateien-App-/Runner-/Testpaket blieben während der nativen
Prüfung unverändert. Feature-/Integrationsbytes exakt geprüft, Modelltests
danach wiederholt. Nur zwei App-Dateien geändert; 140 andere Quelldateien und
alle bestehenden Tests bytegleich zum Vorgänger.

Tages- und Nachtbilder beider Geräte erfüllen die vorab gesetzten groben
Minuten-Endpunktgrenzen. Im iPad-Pilot lag die neue helle Spitze normalisiert
bei ungefähr x0,9460/y0,0936, der isolierte UI07-Referenzbefund bei
x0,9448/y0,0919. Keine Behauptung identischer Originalglyphen oder Handkonturen.

**Außerhalb der Uhr und der beiden vorab aus eigener öffentlicher Geometrie
definierten Zeigerbereiche sind in vier Vergleichen exakt null Pixel geändert.**
Die isolierten 12-/3-/9-Uhr-Markierungsausschnitte bleiben RGBA-exakt. Die
Nabenmitte ist als 3×3-Pixel-Probe nicht mehr hell gefüllt; mindestens sechs von
acht vorab definierten Ringpunkten bleiben hell sichtbar. Das belegt die eigene
offene Zeichnung, nicht die exakte Originaloptik oder einen allgemeinen Alpha-Test.

146 finale eigene PNGs dekodiert; 64 repräsentative native Ansichten auf sechs
Kontaktbögen tatsächlich gesichtet. Acht unveränderte Atlasziele je Gerät sind
RGBA-/PNG-exakt zum eingefrorenen unmittelbaren Vorgänger: Modular, Calendar,
Numerals, Fade, Wetter, Home Modular Clock, Home-Raster und Kalender-App. Das
belegt den erhaltenen Standard der anderen Uhren, nicht sämtliche Atlaszustände.

Je Gerät alle 32 Vollbilder über vier Kaltstarts RGBA-/PNG-bytegleich;
Bewegungs-Positivfall unterschiedlich, Reduce-Motion-Paar exakt, ganze Nachtbilder
ohne falsche Primärfarbpixel. Keine neue RGB-Toleranz. Thermostat-Symbol-/Rand-Taps,
68→69→68 und die 62-Punkte-Rahmen bestehen weiter. Ausgangs-/Wiederherstellungsbilder
RGBA-exakt; lokale Intercom-Zielseite auf beiden Geräten RGBA-/PNG-bytegleich,
keine echte Durchsage.

## Weiter offen

Originalkonturen und exakte Zeiger-/Nabenoptik, Licht/Brechung, Prismenlage,
Schriftformen/andere Werte und physische Hardware bleiben offen. Der frühere
[echte OS-Schalter-Nachweis](prisms-system-reduce-motion.md) gehört zu seinem
älteren App-Payload und wurde hier nicht neu gezählt. Keine Gesamt-Original-,
Hardware- oder aktuelle vollständige UI-Suitenabnahme. Nur synthetische Daten;
keine realen Geräte, Konten oder Kommunikation.
