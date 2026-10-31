# Eigene Timeraktivität nach Prozessende und dauerhaftem Ausschalten

31. Oktober 2026 · begrenzte native Lifecycle-Ergänzung für [#51](https://github.com/Olli0103/homeview/issues/51).

Ein neuer vollständiger XCTest-Fall besteht auf iPhone 18 Pro und iPad Air
11-inch (M4), jeweils iOS/iPadOS 27.0 Simulator. Er verwendet einen eigenen
UUID-Speicher und den ausdrücklich zugelassenen eigenen ActivityKit-Testpfad.
Keine Fixture-Aktivität: Die App liest ihre tatsächliche ActivityKit-Registry.

## Beobachtet

1. Bewusstes Aktivieren und Erstellen eines lokalen 15-Minuten-Timers führt zu
   genau einer eigenen Aktivität. Dreimaliges zusätzliches „Show timer activity“
   erzeugt keine Duplikate.
2. Home und tatsächlicher SpringBoard-Vordergrund verlassen die App. Das äußere
   iPhone-Bild zeigt die kompakte Dynamic Island mit Timer und Countdown; der
   iPad-Home-Screen zeigt keine Aktivitätsdarstellung.
3. XCTest beendet den App-Prozess und prüft `notRunning`. Nach erneutem Start
   desselben eigenen Speichers ist die Präferenz weiter an. **Auf beiden
   beobachteten Simulatoren ist bereits vor einer neuen Show-Aktion weiterhin
   genau eine eigene laufende Aktivität registriert.** Der Test protokolliert
   diesen OS-Befund getrennt, statt allgemeine Retention zu verlangen.
4. Ausdrückliches Anzeigen gleicht auf genau eine laufende Aktivität ab.
5. Bewusstes Ausschalten leert die eigenen aktiven/stale Registryeinträge.
   Ein zweites Prozessende mit erneutem Start behält die ausgeschaltete
   Präferenz, sperrt Show und bleibt bei **null eigenen Aktivitäten**.

Zwei Ausführungen, eine eindeutige neue Methode: keine Fehler, Skips oder
Runtime-Warnungen im jeweiligen xcresult-Summary. Vorbereitungslogs enthalten
separat die vorhandenen SDK-/Debuggerhinweise. Acht native PNGs vollständig
gesichtet. Keine neue Pixelgleichheits- oder Originalvergleichsbehauptung.

## Quellen und Produkte

[Quellen-/Installationsbindung und Ergebnisse](verification/timer-activity-process-20261031.json).

Produktcode und Ressourcenquellen entsprechen vollständig dem bereits mit fünf
SDKs geprüften Commit `c8b9165`. Nur der neue UI-Test ist hinzugekommen. Deshalb
keine Wiederholung unveränderter Coretests oder weiterer vier SDKs. Ein gemeinsames
iOS-build-for-testing erzeugt die tatsächlich auf beiden Geräten verwendeten
App-/Test-/Startdateien; alle 29 kompilierten Eingaben bleiben durch beide Läufe
unverändert, alle 23 installierten Appdateien entsprechen jeweils dem Testbuild.
Der Assetkatalog unterscheidet sich vom normalen SDK-Build und ist separat
archiviert; 22 der 23 Appdateien stimmen auch mit diesem SDK-Paket überein.
Die Testpakete werden nicht nachträglich als identisches normales SDK-Paket
ausgegeben. Bestehende Archivbasis und neue Deltas sind vollständig rekonstruiert
und zurückgelesen.

Ein erster paralleler xcresult-Summary-/Attachment-Export desselben iPad-Bundles
scheiterte beim Anlegen seiner internen SQLite-Datei. Der anschließende serielle
Attachment-Export gelang, ohne einen UI-Lauf zu wiederholen. Ein lokaler
Kontaktbogenversuch fehlte wegen nicht installiertem Pillow; stattdessen wurden
alle acht Original-PNGs direkt gesichtet. Das sind Auswertungsfehler, keine
fehlgeschlagenen App-Tests oder fehlenden Originalbilder.

## Offen

XCTest-Prozessterminierung ist weder nachgewiesener Crash noch ausdrücklich
beobachtetes Wegwischen der App-Karte. Der Ablauf eines Timers während längerer
Suspendierung, OS-Rechteentzug, Lock Screen, erweiterte/minimale Darstellung,
Mehrfensterbetrieb, Spiegelung und physische Geräte bleiben gesondert offen.
Kein Systemalarm, fremde Aktivität, persönliche Quelle, Ton, Nachricht, Anruf
oder Home-Zugriff. Home-/Geräte-/Signing-Holds unverändert; **#51 bleibt OPEN**.
