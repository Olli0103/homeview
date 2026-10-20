# WatchRoot: periodische Modellarbeit an die aktive Szene binden

20. Oktober 2026 · [#81](https://github.com/Olli0103/homeview/issues/81) · [Quellen-/Ergebnisbericht](verification/watch-pulse.json) · [eigene native Probe](verification/watch-pulse-native-probe.swift.txt)

**Begrenzter Software-Fix, keine Watch-Laufzeit- oder Energieabnahme.** Auf dem Host ist keine watchOS-Simulatorlaufzeit installiert. Die Quelle wurde deshalb vorab ausdrücklich in einem nativen macOS-NSHostingView untersucht: Nur die beiden äußeren `#if os(watchOS)`-/`#endif`-Zeilen einer externen WatchRoot-Kopie wurden entfernt. Der darin stehende View-Body ist unverändert übernommen, nicht durch ein nachgebautes Testmodell ersetzt. AppModel wird tatsächlich ausgeführt, verwendet im Host aber seine **macOS**-Bedingungszweige. Der anschließende echte watchOS-SDK-Build ist Typ-/Linkprüfung, kein Watch-Prozess.

## Vorherfehler

WatchRoot abonnierte unabhängig von ScenePhase einen Sekundentimer. Dieselbe native Probe führt vorher und nachher jeweils elf Bedingungen aus. Der Vorherlauf besteht acht und verletzt drei: Die Modellzeit ändert sich bei injizierter Inaktivität und im Hintergrund wiederholt, außerdem ist der lokale Vordergrundtimer schon dort als abgelaufen markiert.

Die Differenzen zwischen den abgelesenen Modellzeiten betragen vorher rund 3,05 bzw. 2,76 Sekunden. Das sind **keine gemessenen Wandzeitfenster oder Energie-/CPU-Werte**. Nach beobachteter Phasenübernahme wartet die Probe zunächst 250ms und dann nominell 2200ms; Task-Scheduling kann diese Wartezeiten verlängern. Die Phase ist im selben View-Baum bezeugt, nicht als echter OS-Hintergrundwechsel ausgegeben.

## Korrektur und Gegenprobe

Nur WatchRoot ändert sich: Bei aktiver ScenePhase bleibt der Combine-Puls abonniert; sonst erhält onReceive einen leeren Publisher. Damit wird die periodische Subscription getrennt, statt nur ihren Callback-Inhalt zu überspringen. Beim Wechsel zurück zu aktiv ruft die Watch-Oberfläche die vorhandene tick-Funktion für den Abgleich absoluter Fristen auf. Keine Änderung von Timer-/Alarmfristen, Speicherformat, AppModel, Haupt-RootView oder View-Layout.

Der **identische Prüfcode besteht danach alle elf Bedingungen**. Beide inaktiven Modellzeit-Differenzen sind exakt null. Aktiv und nach Rückkehr läuft die Modelluhr; der im Hintergrund abgelaufene eigene Timer bleibt dort unquittiert und wird nach Rückkehr verarbeitet. Sein tatsächlicher Receipt ist in der eigenen UUID-Testdatei gespeichert. Der vorhandene Reduce-Motion-Testschalter hält die semantische Uhr nicht an, und eine entfernte View tickt nicht weiter. Display-Wake bleibt aus, Systemalarm-IDs bleiben leer; das eigene Probe-Bundle enthält kein Audioasset. Prozess-Exit0 bezeichnet die vollständig ausgeführte Probe; die getrennten FAIL/PASS-Ergebnisse, nicht der Exitcode allein, bestimmen die Abnahme.

Fünf aktuelle SDK-Builds bestehen, einschließlich der unverändert bewachten echten watchOS-Quelle. 206 Quelldateien und je 100 native Eingaben sind gebunden; beide externen Archive mit je 319 Einträgen wurden vollständig zurückgelesen, einschließlich der ausgeführten Binärdateien. Nur WatchRoot unterscheidet sich in den 206 Eingaben. 72 Core-/Coretest-Dateien sind zum historischen 301-Test-Lauf bei `2b223b7` bytegleich; kein neuer Core-Lauf. Keine neuen UI-Ausführungen oder Bilder und keine behauptete visuelle Original-Parity.

## Grenzen

**#81 bleibt OPEN.** Die echte Watch-Szenensteuerung, Always-on-/Wrist-down-/Dimmverhalten, OS-Suspendierung, Hintergrund-Refresh, Komplikationen, mehrere Fenster/Geräte, physische Timer-/Ton-/Systemalarmausgabe und reale Reduce-Motion-Einstellungen sind nicht abgenommen. Aus den unterbundenen Modellupdates folgt kein quantifizierter CPU-/GPU-/Wakeup-/Speicher-/Framezeit-/Batteriegewinn. Die native macOS-Probe ist ausdrücklich keine Ausführung der watchOS-spezifischen AppModel-Zweige.

Keine Runtime installiert, keine persönlichen Daten/Accounts, Berechtigungen, Medien, Nachrichten/Anrufe, neuen Systemalarme oder Live Activities. Eigene frische UUID-Dateien, kein Zurücksetzen vorhandener Stores. Keine Home-Anbindung. Der frühere [RootView-Nachweis](foreground-clock-lifecycle.md) bleibt an seinen eigenen historischen Stand gebunden.
