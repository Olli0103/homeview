# Flow: fünf Minuten native Beobachtung und zehn Minuten Fluidrechnung

18. Oktober 2026 · begrenzter Zusatz zu [FLOW-02 / Issue 16](https://github.com/Olli0103/homeview/issues/16).
Basis `503ffe938fc441ee1eae14f961e5946201411d1d`; **App-Code unverändert**.

## Native Beobachtung

Zwei native Ausführungen, je eine auf verwaltetem iPad-/iPhone-Simulator, bestehen
ohne Fehler, Skips oder XCTest-Runtime-Warnungen. Der eigene Glyphen-Testmodus hält
nur die Ziffernformen fest; das Fluid läuft weiter. Nach mindestens **60, 180 und
300 echten monoton gemessenen Sekunden** werden je zwei Bilder mit 1,2 Sekunden
Abstand aufgenommen. Die genauen Zeiten stehen im [Nachweis](verification/flow-five-minute.json).

An jedem Messpunkt ändern sich Pixel innerhalb der eigenen erodierten Glyphenkörper.
In beiden Bildern liegen mehr als zwölf Prozent dieser Körperproben über RGB-Maximum
70 und einer RGB-Kanalspreizung von 35 – dieselbe Farbdefinition wie im vorhandenen
Materialtest. Das prüft sichtbare Farbe, nicht Originalfarbtreue oder vollständige
räumliche Farbverteilung. Die Maskierung entspricht dem bestehenden 30-Sekunden-Test:
weiß über245 an Zentrum und acht Nachbarn, Abstand zwei Prozent der Bildbreite,
Abtastschritt zwei Pixel. Mehr als1000 Körperbytes je Bild erforderlich.

Nach getrenntem Neustart mit dem vorhandenen CLI-Reduce-Motion-Testschalter bleiben
die Körperpixel exakt gleich. **Kein echter OS-Schalter-Nachweis für Flow.**
Alle18 eigenen PNGs wurden dekodiert und auf zwei Kontaktbögen tatsächlich gesichtet.
Beide Ausführungen liefen gleichzeitig auf einem Mac; daraus folgt keine Bildrate
oder Energie-/Lastmessung auf einem iPad/iPhone.

## Unveränderte Fluidrechnung über zehn Minuten Simulationszeit

Ein getrennter optimierter Swift-Lauf verwendet exakt die veröffentlichte
`FlowSimulation.swift`: tatsächliches40×40-Gitter,12020 kumulative Schritte mit
0,05 Sekunden, also601 Sekunden Simulationszeit je Szenario. Keine Zeitsprünge
zum Zielzustand und kein Austausch gegen kleinere Testgitter.

Drei Szenarien: ohne Impuls, begrenzte Eingabebursts und alternierende extreme
endliche Impulse (durch den vorhandenen Produktionscode begrenzt). Bei30/60/120/300/600/601
Simulationssekunden sind alle Werte endlich, RGB in[0,1], Geschwindigkeitsränder
exakt gemäß vorhandener Randbedingung und Rot-/Grün-Spannweite jeweils über0,25.
Dieselbe Spannweitengrenze existiert bereits im30-Sekunden-Modelltest. Auch von600
zu601 Sekunden ändert sich das Feld. Mittelwerte, Varianzen und5./95.Perzentile
sind dokumentiert, ohne daraus nachträglich zusätzliche Abnahmegrenzen zu erfinden.
Das ist CPU-Modellrechnung, kein601-Sekunden-Simulator-/Hardware-Dauerlauf.

## Reproduzierbarkeit und Grenze

Das ausgeführte App-Paket ist bytegenau das bereits geprüfte Palette-Paket;
alle zehn installierten App-Dateien auf beiden Simulatoren separat SHA-rückgelesen.
Alle20 nativen Eingabedateien sind vor/nach dem Lauf unverändert. Nur ein privater
zusätzlicher Prüfharness wurde gebaut. App und Standard-Testtarget bleiben unverändert;
kein neuer SDK-Durchlauf, kein Addieren zu früheren UI-Zählern.

[Optionaler nativer Prüfharness](verification/flow-five-minute-native-fixture.swift.txt),
[Standalone-Simulationsfixture](verification/flow-ten-minute-simulation.swift.txt),
[eigene Bilder und Hashes](screenshots/goal-20261018/flow-five-minute-manifest.json).
Die native Fixture wird mit einem LF an das Basis-UITestfile angehängt; die
Standalone-Fixture als`.swift`zusammen mit`Sources/Core/FlowSimulation.swift`mit
`swiftc -O`kompiliert und mit einem neuen Ausgabeordner als einzigem Argument gestartet.
Quell-/Fixture-Hashes sind im Nachweis gebunden. Keine privaten Originalbilder.

Nicht erledigt sind beliebig lange Laufzeiten, Hintergrund-/Resume-Sequenzen,
GPU-Port, Framezeiten/Energie, sämtliche Werte/Schriftvarianten, physische Geräte,
globale Accessibility und Originallicht/-bewegung. Issue16 bleibt offen.
Nur synthetische Daten, keine echten Konten, Bibliotheken oder Homes.
