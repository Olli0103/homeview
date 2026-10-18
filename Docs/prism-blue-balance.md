# Home Modular: Rot-/Grünbalance der blauen Prismenpalette

18. Oktober 2026 · [FACE-11 / #20](https://github.com/Olli0103/homeview/issues/20) bleibt offen.

Ein einzelner Wert im eigenen Metal-Shader wird korrigiert: Die blaue
Standardpalette verwendet Grün 0,40 statt 0,37, bei weiterhin Rot 0,40 und
Blau 0,95. Sämtliche Prismenformen, Bewegung, Reflexions-/Lichtgleichungen,
Alpha und andere Farbthemen bleiben im Quelltext unverändert. Alle 141 anderen
Quelldateien und sämtliche bestehenden Tests sind bytegleich zum Vorgänger.
Der separat untersuchte Markierungsschatten ist nicht enthalten und bleibt
zurückgehalten: Seine eigenen Pixelgrenzen bestanden nach Korrektur, ein klarer
Originalvorteil war im Bildvergleich aber nicht hinreichend belegt.

[Eigene Vorher-/Nachher-Ansichten](screenshots/goal-20261018/prism-blue-balance-own-before-after.jpg) ·
[quellgebundene Prüfung und vorher gesetzte Farbgrenzen](verification/prism-blue-balance.json) ·
[eigene Bilder/Hashes](screenshots/goal-20261018/prism-blue-balance-manifest.json).

## Begrenztes Farbziel

In den blau dominierten UI07-Referenzpixeln sind Rot und Grün gleich. In der
vorherigen eigenen iPad-Ansicht lag Rot im Median sechs Kanalwerte über Grün.
Die vorab festgelegte Auswahl lautet: B>R+35, B>G+35, B>100, R<220 und G<220.
Damit werden weiße Ziffern und Symbole weitgehend vom Hintergrundmaß getrennt.

Im Pilot sinkt die mediane Rot-/Gründifferenz von 6 auf 0 und der mittlere
absolute R/G-Fehler gegen dieses begrenzte Referenzziel von 6,73 auf 0,20.
Das entspricht rund 97 % Reduktion dieses mittleren Metrikfehlers, nicht
97 % Gesamt-Originaltreue. Beide Geräte erfüllen im Abschluss die vorher
festgelegten absoluten Fehlergrenzen und mindestens 75 % Fehlerreduktion.
Die Kennzahl beschreibt nominale Rasterkanäle; Helligkeit, komplette
Farbverwaltung, HDR, Glaslicht und Prismenlage werden dadurch nicht abgenommen.

## Software- und Bildnachweis

166 Modelltests, vierzehn gezielte iPad-/iPhone-Ausführungen und fünf SDK-Builds
bestanden. Keine UI-Fehler, Skips oder XCTest-Runtime-Warnungen. Der einzelne
vorherige Pilot wird nicht zu den vierzehn Abschlussausführungen addiert.
142 Quellen und das vollständige 20-Dateien-App-/Runner-/Testpaket während der
nativen Prüfung unverändert. Feature-/Integrationsbytes exakt geprüft;
Modelltests danach wiederholt.

Die um einen nativen Pixel nach innen verkleinerte Auswahl zuvor reinweißer
Zeichnungspixel bleibt tags/nachts auf beiden Geräten RGBA-exakt. Im Pilot sind
das 92.037 Tages- und 92.246 Nachtpixel. Das ist eine definierte Rasterprobe,
kein aus RGB-Werten abgeleiteter allgemeiner Transparenznachweis. Antialias-
Randpixel und Hintergrundfarben dürfen durch die Palette erwartungsgemäß
abweichen; eine vollständige Vorher-/Nachher-Pixelgleichheit wird nicht behauptet.

146 eigene finale PNGs dekodiert; 64 repräsentative native Ansichten auf sechs
Kontaktbögen tatsächlich gesichtet. Acht unveränderte Atlasziele je Gerät
RGBA-/PNG-exakt zum unmittelbaren Vorgänger, darunter die graue große Home-Uhr,
Modular, Fade, Wetter und Home-Raster. Keine Behauptung, dass jeder Farbthemen-
oder Atlaszustand separat pixelabgenommen wurde; die übrigen Palettengleichungen
blieben unverändert.

Je Gerät alle 32 Vollbilder über vier Kaltstarts RGBA-/PNG-bytegleich;
Bewegungs-Positivfall unterschiedlich, Reduce-Motion-Paar exakt, ganze Nachtbilder
ohne falsche Primärfarbpixel. **Keine Toleranz für diese Stabilitätsvergleiche.**
Die begrenzten Farbkennzahlen sind davon getrennte, vorher festgelegte Ziele.
Thermostat-Symbol-/Rand-Taps, 68→69→68 und 62-Punkte-Rahmen bestehen weiter;
Ausgangs-/Wiederherstellungsbilder RGBA-exakt. Lokale Intercom-Zielseite auf
beiden Geräten RGBA-/PNG-bytegleich, keine echte Durchsage.

## Weiter offen

Originalhelligkeit, Prismenlage, Brechung/Licht, exakte Ziffern-/Zeigerkonturen,
weitere Werte und physische Hardware bleiben offen. Der frühere
[echte OS-Schalter-Nachweis](prisms-system-reduce-motion.md) gehört zu seinem
älteren App-Payload und wurde hier nicht neu gezählt. Keine Gesamt-Original-,
Hardware- oder aktuelle vollständige UI-Suitenabnahme. Nur synthetische Daten;
keine realen Geräte, Konten oder Kommunikation.
