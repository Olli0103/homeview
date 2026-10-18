# Home Modular: Temperaturposition nach UI07

18. Oktober 2026 · [FACE-11 / #20](https://github.com/Olli0103/homeview/issues/20) bleibt offen.

Die helle Temperaturzeichnung lag in der eigenen Ansicht rund 13,38 Punkte
auf dem 600-Punkte-Entwurf zu hoch. Der eigene Text erhält ausschließlich
`offset(x: 2, y: 13.5)` vor seinem bisherigen Maximalrahmen. Schriftgröße,
Gewicht, Design, Breite, Kachel, Beschriftungen, Pfeile und Touchfläche bleiben
unverändert. Keine extrahierten Schriftkonturen oder Referenzgrafik übernommen.

[Eigene Vorher-/Nachher-Bilder](screenshots/goal-20261018/home-temperature-own-before-after.jpg) ·
[Nachweise und vorher festgelegte Grenzen](verification/home-temperature-position.json) ·
[eigene Bilder und Hashes](screenshots/goal-20261018/home-temperature-manifest.json).

## Bild- und Softwareprüfung

**166 Modelltests, zehn gezielte iPad-/iPhone-Ausführungen und fünf SDK-Builds
bestanden.** Keine UI-Fehler, Skips oder XCTest-Runtime-Warnungen. 142 Quellen
und vollständiges 20-Dateien-App-/Runner-/Testpaket während der nativen Prüfung
unverändert; Sourcebytes gegen Feature- und Integrationscommit geprüft,
Modelltests danach jeweils erneut. Zwei vorherige Pilot-Ausführungen werden
nicht zu den zehn Abschlussausführungen addiert.

Die Referenzmessung lieferte normalisierte Oberkante 0,1875 und Unterkante
0,3860. Beide eigenen Geräte erreichen nach dem Versatz ungefähr
0,1878 / 0,3863; die Mitte liegt um 0,3389. Tages- und Nachtbilder erfüllen die
vor dem Eingriff gesetzten Positionsgrenzen. In allen vier Vergleichen sind
**außerhalb des Temperaturbereichs exakt null Pixel verändert**. Schriftbreite
und -höhe bleiben in der dokumentierten Rastermessunsicherheit erhalten;
das ist keine Behauptung identischer Originalglyphen.

86 finale eigene PNGs dekodiert,34 repräsentative native Ansichten auf vier
Kontaktbögen tatsächlich gesichtet. Die lokale Intercom-Zielseite ist auf
beiden Geräten pixel- und PNG-bytegleich zum Vorherstand; keine Durchsage.
Tatsächliche Thermostat-/Szenen-Touches bestehen. Je Gerät bleiben alle32 Bilder
über vier Kaltstarts auch als ganze Viewports RGBA-/PNG-bytegleich; Bewegung
im Positivfall sichtbar, bisherige exakte Bewegungs-/Nachtprüfungen unverändert.
Alle ganzen Nachtbilder halten die bestehende Primärfarbgrenze ein.

## Weiter offen

Die eigene Ziffernbreite/-form wurde absichtlich nicht korrigiert oder original
abgenommen. Prismenlage, Licht, Brechung, Zeigerdetails und physische Hardware
bleiben ebenfalls offen. Der vorherige [echte Systemschalter-Nachweis](prisms-system-reduce-motion.md)
gilt für seinen dort exakt gebundenen App-Stand; er wurde für diesen reinen
Zeichnungsversatz nicht erneut als neue Ausführung gezählt. Keine Gesamt-Original-,
Accessibility- oder aktuelle vollständige UI-Suitenabnahme. Nur synthetische Daten.
