# Echter System-Reduce-Motion-Nachweis für Home Modular

18. Oktober 2026 · separater Zusatznachweis nach dem [Prismen-Schritt](prisms-planar-grouped.md).

Auf iPhone- und iPad-Simulator wurden je zwei Kaltzyklen geprüft. Beide Phasen
starten die App mit exakt denselben Argumenten, einschließlich `--animation-test`:
**kein `--reduce-motion`-CLI-Schalter**. Stattdessen wird der echte Schalter über
Einstellungen → Bedienungshilfen → Bewegung → Bewegung reduzieren bedient.

**Zwei native Ausführungen bestanden**, null Fehler, Skips oder XCTest-Runtime-Warnungen.
Je Gerät vier bewegte Kontrollbilder bei ausgeschaltetem Systemschalter und
16 Standbilder bei eingeschaltetem Schalter. Die bewegten Paare unterscheiden
sich; alle 16 Standbilder sind über beide Kaltstarts als ganze RGBA-Viewports
und PNG-Dateien exakt gleich. Keine RGB-Toleranz und kein Wiederholen bis Grün.

Die insgesamt 16 zeitgestempelten Einstellungs-Read-backs belegen beide
Ein-/Aus-Zyklen je Gerät und den wiederhergestellten Ausgangswert **aus**.
Mögliche exakte Bildabweichungen werden gesammelt und erst nach bestätigter
Rückstellung als Testfehler gemeldet. Die 40 eigenen nativen PNGs und vier
Kontaktbögen wurden dekodiert und tatsächlich gesichtet.

## Was unverändert blieb

Alle zehn Produktions-App-Dateien sind SHA-256-bytegleich zur zuvor mit
166 Modelltests,16 regulären UI-Ausführungen und fünf SDKs geprüften App aus
`6fd88d9`. Das zusätzliche Testbundle änderte ausschließlich den Prüfharness;
App, Runner und Testbundle waren dann auf beiden Geräten identisch. Keine
neue App-Implementierung, kein neuer SDK-Durchlauf und keine Addition dieser
zwei Läufe zu den früheren 16. Der Standard-Testtarget bleibt unverändert.

Der [exakte optionale Simulator-Prüfharness](verification/prisms-system-reduce-motion-fixture.swift.txt)
gehört nicht zum Standard-Testtarget. Er lässt sich bytegenau aus dem verknüpften
Basis-Testfile und diesem Zusatz rekonstruieren; Quelle und Hashes sind im
[Nachweis](verification/prisms-system-reduce-motion.json) gebunden. Die gezielten
Läufe verwenden ausschließlich die verwalteten Testsimulatoren.

[Eigene Bilder und Hashes](screenshots/goal-20261018/prism-system-manifest.json).
Keine privaten Originalbilder und keine echten Konten, Bibliotheken, HomeKit-Geräte,
Systemalarme oder Durchsagen. Keine Host-Einstellung wurde verändert.

## Grenze

Belegt wird nur dieser Home-Modular-Zustand in iOS27-Simulatoren. Vollständige
Accessibility aller Flows, physische Hardware/Energie, Originalbrechung und
Originalbewegung bleiben offen. [Issue20](https://github.com/Olli0103/homeview/issues/20)
bleibt offen. Der frühere negative Systemschalter-Pilot auf altem Code wird nicht
umetikettiert; der neue Nachweis gilt ausdrücklich für die getrennte Glasschicht.
