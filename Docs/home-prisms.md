# Home-Modular: Prismen und Glaskacheln

17. Oktober 2026 · weiterer Prüfschritt im fortlaufenden Gesamtauftrag ·
[#20](https://github.com/Olli0103/homeview/issues/20) bleibt offen.

`39464d4` ersetzt flache Dreiecksflächen durch ein eigenes analytisches Relief
mit abgeschrägten Kanten, geneigten Flächen und Reflexionsbändern. Die Kacheln und
beiden Analoguhren erhalten die öffentliche native Clear-Glass-Darstellung hinter
ihren Inhalten. Die gekrümmten Randbereiche brechen nun den tatsächlichen
Hintergrund statt nur einen weißen Rahmen darüberzulegen. Die alternative
Home-Modular-Ansicht verwendet eine zurückhaltende neutrale Prismenpalette.

Die Referenzen sind UI07 (Produktgrafik) und UI45 (perspektivische Aufnahme).
Das ist eine Korrektur in deren Richtung, keine neue eigene Stilvorgabe und kein
Originalrenderer-PASS. Es werden weder Referenzbilder noch extrahierte Texturen,
Schriftkonturen, private Frameworks oder Originalshader eingebettet.

[Eigener Vorher-/Nachher-Vergleich](screenshots/goal-20261017/home-prisms-own-before-after.png) ·
[Bildherkunft und historische Vorquelle](verification/home-prisms-comparison.json) ·
[Prüfstand](verification/home-prisms.json) ·
[eigene Bilder und Digests](screenshots/goal-20261017/home-prisms-manifest.json).

## Geprüft

99 Modelltests, vier gezielte UI-Fälle je iPad/iPhone (acht Ausführungen) und fünf
SDK-Builds bestanden; nach dem Codecommit erneut 99 Modelltests. Alle 114
erfassten Quellen blieben während der Prüfungen unverändert und wurden gegen den
Codecommit geprüft. Keine UI-Fehler, Skips oder von XCTest gemeldeten
Runtime-Warnungen. Kein neuer vollständiger UI-Suite-PASS.

Die Touchprüfung sendet einen tatsächlichen Simulator-Koordinaten-Touch an die
sichtbare Temperatur. Anschließend müssen der Thermostat-Bildschirm und die
resultierenden Temperatur-/Szenenwerte stimmen. Eine anfängliche `isHittable`-
Assertion scheiterte auch mit dem alten Material: Diese AX-Auskunft allein war
kein Beleg für eine durch Glas beschädigte Bedienung. Die Ursache der AX-Auskunft
wird nicht als bewiesen ausgegeben. Frühere Diagnoseversuche bleiben getrennt.

Die Bewegung vergleicht dekodierte RGBA-Werte in den vorab festgelegten inneren
80 Prozent des Displays. Der bewegte Positivfall ändert sich; Reduce Motion bleibt
pixelgleich. Die Nachtprüfung untersucht dort alle helleren Pixel und findet
keinen grünen oder blauen Farbanteil oberhalb der festgelegten Rotgrenze. Beide
Home-Varianten, die Materialränder und die Nachtbilder wurden gesichtet.

## Noch offen

Genaue Prismenkonturen, Licht-/Bewegungsphasen, Zeiger- und Schattendetails sowie
physische Energie-/Bildratenmessungen sind nicht original abgenommen. `glassEffect`
ist auf visionOS nicht verfügbar; dort und auf macOS vor Version 26 bleibt ein
ausdrücklicher öffentlicher Materialfallback, keine behauptete identische Optik.
Die übrigen Plattformen sind kompiliert, nicht pauschal zur Laufzeit abgenommen.
Automatische Bedienung verwendet nur MockHome und synthetische Daten.

Dieser Commit ist ein Prüfpunkt, kein Abschluss des HomeView-Goals. Die weitere
belegte Layout- und Funktionsarbeit läuft weiter.
