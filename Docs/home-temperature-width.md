# Home Modular: Breite und Abstand der Temperaturzeichnung

18. Oktober 2026 · [FACE-11 / #20](https://github.com/Olli0103/homeview/issues/20) bleibt offen.

Nach der getrennten Positionskorrektur war die eigene „68“ noch zu breit.
Die vorhandene öffentliche Systemschrift erhält `kerning(-2.125)` und eine
horizontale Zeichnungsskalierung von `0.967`. Der optische x-Versatz sinkt
von zwei auf einen Entwurfspunkt; y bleibt 13,5. Schriftfamilie, Größe,
Gewicht, Höhe, Kachel, Beschriftungen, Pfeile, Touchrahmen und Handler bleiben
erhalten. Keine extrahierten Originalkonturen oder Referenzgrafiken.

[Eigene Vorher-/Nachher-Bilder](screenshots/goal-20261018/home-temperature-width-own-before-after.jpg) ·
[quellgebundene Messung und vorher festgelegte Grenzen](verification/home-temperature-width.json) ·
[eigene Bilder und Hashes](screenshots/goal-20261018/home-temperature-width-manifest.json).

## Begrenzte Prüfung

166 Modelltests, zehn gezielte iPad-/iPhone-Ausführungen und fünf SDK-Builds
bestanden. Keine UI-Fehler, Skips oder XCTest-Runtime-Warnungen. 142 Quelldateien
und das vollständige 20-Dateien-App-/Runner-/Testpaket blieben während der
nativen Prüfung unverändert. Feature- und Integrationscommit stimmen exakt
mit den geprüften Sourcebytes überein; Modelltests danach jeweils wiederholt.
Zwei Pilot-Ausführungen sind nicht zu den zehn Abschlussausführungen addiert.

Die normalisierte UI07-Gesamtbreite beträgt gemessen 0,29834. Die eigene
Zeichnung erreicht jetzt 0,29837 (iPad) und 0,29894 (iPhone), vorher rund
0,3122 beziehungsweise 0,3131. Beide Einzelbreiten und der Zeichenabstand
erfüllen die vor dem Eingriff festgelegten Grenzen. Ober-/Unterkante, Mitte
und Höhe bleiben erhalten. Tages- und Nachtvergleiche auf beiden Geräten:
**außerhalb des Temperaturbereichs exakt null geänderte Pixel**.

86 finale eigene PNGs dekodiert; 34 repräsentative native Ansichten auf vier
Kontaktbögen tatsächlich gesichtet. Je Gerät bleiben alle 32 Bilder aus vier
Kaltstarts als ganze Viewports RGBA- und PNG-bytegleich. Bewegungs-Positivfall
unterschiedlich, Reduce-Motion-Paar exakt; keine neue RGB-Toleranz. Ganze
Nachtansichten ohne falsche Primärfarbpixel. Lokale Intercom-Zielseite auf
beiden Geräten PNG-/RGBA-exakt zum Vorherstand. Thermostat-/Szenen-Touches und
Navigation bestanden; keine echte Durchsage oder Gerätebedienung.

## Keine Gesamt-Originalabnahme

Das kalibriert nur Breite und Abstand des belegten Werts „68“ mit eigener
Systemschrift. Originalglyphenform, andere Werte, Pfeile, Prismenlage, Licht,
Brechung, Zeigerdetails und physische Hardware bleiben offen. Der frühere
[echte OS-Schalter-Nachweis](prisms-system-reduce-motion.md) gehört zu seinem
älteren App-Payload und wurde hier nicht als neue Prüfung gezählt. Keine
aktuelle vollständige UI-Suiten-, Original- oder Hardwareabnahme.
