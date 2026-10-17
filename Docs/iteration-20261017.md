# Erstes Issue-Paket nach Veröffentlichung

17. Oktober 2026. Alle Änderungen sind in kleinen Commits gespeichert. Der komplette Originalumfang ist nicht fertig.

## Umgesetzt

- [#1](https://github.com/Olli0103/homeview/issues/1): Parity-Vertrag, Belegstärke und getrennte Abnahmen für alle 105 Referenzfunktionen.
- [#12](https://github.com/Olli0103/homeview/issues/12): motivgeschützte Uhr-/Ausschnittwahl, vollständiges Bild bei Randmotiven, manuelle Korrektur je Bild, Speicherung, Reset und robuste Migration.
- [#67](https://github.com/Olli0103/homeview/issues/67), teilweise: Sitzungsgenerationen, Cachelöschung, Schutz bei Hintergrund und keine Kalender-/Reminder-Leseaufrufe vor Geräteentsperrung. Echte Präsenzquelle und Hardwareprüfung fehlen.
- [#18](https://github.com/Olli0103/homeview/issues/18), teilweise: eigener zyklischer Fade-Verlauf mit definierten Farbstops und Reduce Motion. Originalzeitkurve und vollständige visuelle Abnahme fehlen.

## Prüfung und Quellenbindung

| Stand | Modelltests | UI | SDK-Builds | Bindung |
|---|---:|---|---|---|
| Foto und Datenschutz, `5325d01` | 50 bestanden | Je 50 vollständige Fälle auf iPad und iPhone bestanden | Fünf bestanden | [90 Quellen](verification/photo-privacy-source.json) |
| Fade-Folgestand, `68df0fa` | 53 bestanden | Zwei gezielte Pixeltests auf frischem iPad-Simulator bestanden | Fünf bestanden | [92 Quellen](verification/fade-conic-source.json) |

Die erste Zeile sind 150 erfolgreiche Testausführungen auf exakt diesem Quellstand. Keine Fehler, übersprungenen Fälle oder Runtime-Warnungen. Die zweite Zeile ist ein gesondert geprüfter Folgestand. Es gab keinen erneuten vollständigen 52er-UI-Lauf auf beiden Geräten. Deshalb bleiben eine endgültige Gesamtregression und Originalabnahme als Release-Gate offen. Die Zahlen werden nicht zu einem vermeintlichen finalen Komplett-PASS zusammengezogen.

Die eng begrenzte Fade-Änderung betrifft den Face-Verlauf, sein Core-Modell und zugehörige Tests/Projektverweise. Die vorher geprüfte Foto-/Datenschutzlogik bleibt bytegleich. Strukturierte Ergebnisse: [iteration-20261017.json](verification/iteration-20261017.json).

## Bilder

Sieben eigene finale Simulatorbilder wurden dekodiert gesichtet und unverändert kopiert. Keine Originalreferenzbilder sind enthalten. [Dateien und Digests](screenshots/iteration-20261017/manifest.json).

- [Uhr unter oberem Motiv](screenshots/iteration-20261017/iPad-photo-layout-top-subject-clock-bottom.png)
- [Beide Randmotive erhalten](screenshots/iteration-20261017/iPhone-photo-layout-two-edge-subjects-full-image.png)
- [Bewusst manueller Ausschnitt](screenshots/iteration-20261017/iPad-photo-layout-manual-crop.png)
- [Neue Entsperrung nach Hintergrund](screenshots/iteration-20261017/iPhone-privacy-calendar-locked-after-background.png)
- [Fade zur Referenzzeit](screenshots/iteration-20261017/iPad-fade-conic-reference-time.png)
- [Andere Verlaufsphase](screenshots/iteration-20261017/iPad-fade-conic-phase-quarter.png)
- [Reduce Motion](screenshots/iteration-20261017/iPad-fade-conic-reduced-zero.png)

## Grenzen

Alle persönlichen Testdaten, Fotos, Provider und Hausgeräte sind synthetisch. Ausdrückliche AlarmKit-Fälle verwenden ausschließlich eigene Simulatoralarme. Keine echten Kalender/Listen, Musikabos, persönlichen Bilder, Mikrofone oder Hausgeräte wurden automatisch geöffnet. Keine Anrufe oder Nachrichten versandt. Apple Home bleibt im Initializer gesperrt. Es gibt keine physische Hardware- oder vollständige Originalpixel-/Animationsabnahme.

Die getesteten OS-Bausteine und Grenzen stehen in der [Build-Übernahmekarte](build-transfer-map.md). Rohanalysen und proprietäre Assets bleiben außerhalb des öffentlichen Repositories.
