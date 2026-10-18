# Home Modular: Thermostat-Pfeile und explizite Trefferrechtecke

18. Oktober 2026 · [FACE-11 / #20](https://github.com/Olli0103/homeview/issues/20) bleibt offen.

Die eigenen Thermostat-Chevrons waren gegenüber UI07 etwa ein Drittel zu schmal
und lagen zu weit außen. Die weiterhin öffentlichen SF Symbols werden nur im
lokalen Home-Modular-Helfer 1,5-fach gezeichnet: links 15, rechts −13,5 und
vertikal −2,25 Entwurfspunkte versetzt. Das vorhandene 62×62-Punkte-Layout,
Aktionen, Beschriftungen, Identifikatoren und `GlassPressStyle` bleiben erhalten.
Der globale `RoundButton` und alle anderen App-/Core-/Shaderdateien bleiben
bytegleich; ein neuer gezielter UI-Fall ergänzt die unveränderten Bestandstests.
Keine kopierten Originalkonturen oder Referenzgrafiken.

[Eigene Vorher-/Nachher-Ansichten](screenshots/goal-20261018/home-thermostat-arrows-own-before-after.jpg) ·
[quellgebundene Messung](verification/home-thermostat-arrows.json) ·
[eigene Bilder/Hashes](screenshots/goal-20261018/home-thermostat-arrows-manifest.json).

## Trefferbereich: Fehler und Korrektur

Der erste Pilot bestand die bestehende Navigation, scheiterte aber an der neuen
strengen Rahmenprüfung: Der AX-Rahmen war etwa 42,785 statt 82,253 Bildschirmpunkte
breit. Derselbe unveränderte Testbinärstand mit der archivierten vorherigen App
meldete nur 28,523 Punkte. Beide fehlgeschlagenen Ausführungen bleiben erhalten;
sie werden nicht als erfolgreiche Abschlussfälle gezählt.

Die 62 Punkte waren vorher ein Layoutmaß, kein belegter vollflächiger Trefferbereich.
Der neue lokale Helfer ergänzt daher `contentShape(Rectangle())` nach dem weiterhin
62×62-Punkte-großen Rahmen. **Keine Rahmenprüfung gelockert.** Der erfolgreiche
neue Fall prüft den vollständigen Rahmen und betätigt tatsächlich sowohl die
sichtbaren Symbole als auch das linke innere Padding beider Tasten. Beide Paare
führen den lokalen Mock-Wert von 68 auf 69 und wieder auf 68. Andere globale
Rundtasten wurden damit nicht automatisch als vollflächig abgenommen.

## Begrenzter Abschluss

166 Modelltests, zwölf gezielte iPad-/iPhone-Ausführungen und fünf SDK-Builds
bestanden. Keine UI-Fehler, Skips oder XCTest-Runtime-Warnungen. Erfolgreicher
Zwei-Fälle-Pilot, erster fehlgeschlagener Pilot und kontrollierter negativer
Vorherstand-Test werden nicht zu den zwölf Abschlussausführungen addiert.
142 Quellen und vollständiges 20-Dateien-App-/Runner-/Testpaket während der
nativen Prüfung unverändert; Feature-/Integrationsbytes exakt geprüft und
Modelltests danach jeweils wiederholt.

Breite, Höhe und Mittelpunkt beider Pfeile erfüllen tags/nachts auf beiden
Geräten die vorher gesetzten Grenzen. Die gemessene normalisierte UI07-Breite
beträgt 0,05341, die eigene iPad-Zeichnung erreicht 0,05339. In allen vier
Vorher-/Nachher-Vergleichen sind **außerhalb beider Pfeilbereiche exakt null Pixel
geändert**: Temperatur, Texte, Kacheln und Glas bleiben dort unverändert.
Lokale Intercom-Zielseite auf beiden Geräten RGBA-/PNG-bytegleich; keine Durchsage.

98 eigene finale PNGs dekodiert, 40 repräsentative native Ansichten auf vier
Kontaktbögen tatsächlich gesichtet. 68-Ausgangs- und Wiederherstellungsbilder
RGBA-exakt. Je Gerät alle 32 Vollbilder über vier Kaltstarts RGBA-/PNG-exakt;
Bewegungs-Positivfall unterschiedlich, Reduce-Motion-Paar exakt. Ganze
Nachtansichten ohne falsche Primärfarbpixel. Keine neue RGB-Toleranz.

## Weiter offen

Exakte Original-Symbolkonturen, Schriftformen/andere Werte, Prismenlage,
Licht/Brechung, Zeigerdetails und physische Hardware sind nicht vollständig
abgenommen. Der frühere [echte OS-Schalter-Nachweis](prisms-system-reduce-motion.md)
gilt für seinen älteren App-Payload, nicht als neue Ausführung dieses Pakets.
Keine Gesamt-Original-, Hardware- oder aktuelle vollständige UI-Suitenabnahme.
Nur synthetische Daten, keine realen Geräte, Konten oder Kommunikation.
