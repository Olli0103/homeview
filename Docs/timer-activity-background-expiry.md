# Eigene Timeraktivität: tatsächlicher Ablauf außerhalb der App

31. Oktober 2026 · begrenzte native Ergänzung für [#51](https://github.com/Olli0103/homeview/issues/51).

Eine neue vollständige XCTest-Methode besteht auf iPhone 18 Pro und iPad Air
11-inch (M4), iOS/iPadOS 27.0 Simulator: **zwei aktuelle Ausführungen, keine
Fehler, Skips oder Runtime-Warnungen im jeweiligen xcresult-Summary**.

## Ablauf und tatsächlich beobachtete Grenze

Ein eigener UUID-Speicher aktiviert ausdrücklich die eigene ActivityKit-Anzeige
und startet einen lokalen Ein-Minuten-Timer. Vor Home liest der Test die echte
ActivityKit-Content-Frist über ein nur im bisherigen synthetischen Systemtestpfad
zugängliches Accessibility-Value. Die Wartezeit folgt dieser Frist, nicht einer
angeforderten nominellen Dauer oder einer verschobenen Testuhr.

| Simulator | Tatsächlich außerhalb der App gewartet | Außenbeobachtung nach echter Frist |
|---|---:|---:|
| iPhone | 45,194 s | 2,002 s |
| iPad | 50,807 s | 2,001 s |

SpringBoard ist im Vordergrund, die App ausdrücklich nicht. **Auf dem iPhone
bleibt die kompakte Dynamic Island nach Ablauf bei 0:00 sichtbar.** Auf dem
iPad-Home-Screen ist keine Aktivitätsdarstellung sichtbar. Erst die Rückkehr wird
hier als Bereinigungsgrenze abgenommen: eigene aktive/stale Registry null,
Präferenz noch an, keine verbleibende ActivityKit-Frist. Das anschließende
explizite Ausschalten und ein Read-back des genau eigenen Speichers bestätigen
Präferenz aus, gespeicherten Ablauf-Receipt und identische echte Timerfrist.
Keine nativen Timer-/Wecker-IDs im eigenen iPad-Store; kein Systemalarm erzeugt.
`didAlert=true` ist ein lokaler Receipt, kein akustischer Zustellnachweis.

## Fehler und Wiederherstellung bleiben erhalten

Vorbereitung 1 scheitert an Swift-Actor-Isolation im synchronen XCTest-tearDown:
null UI-Ausführungen. Im ersten tatsächlich ausgeführten iPhone-Fall bestehen
Ablauf und Rückkehr, aber der Cleanup scrollt am Settings-Ziel vorbei. Die ganze
Methode ist deshalb **FAIL**, nicht nachträglich als bestanden umetikettiert.
Der vorhandene bidirektionale gemessene Gutter-Drag ersetzt nur diese
Testnavigation. Alle 20 Appdateien bleiben zwischen Fehlstand und Korrektur
bytegleich; die eigentlichen Ablauf-/Null-/Präferenzbedingungen bleiben erhalten.

Nach dem terminalen Fehler hängt Xcode in collectSimulatorDiagnostics. Nur der
verifizierte eigene simctl-diagnose-Unterprozess wird nach gesicherter Probe und
Logs per SIGINT beendet; Xcode und Simulator-Dienste werden nicht signalisiert.
Der vollständige ursprüngliche xcresult schließt mit Fehler ab. Die folgenden
beiden Läufe benutzen die öffentliche Option `-collect-test-diagnostics never`,
ohne Tests oder manuelle Attachments zu kürzen. Frühe Leseversuche vor finalem
Info.plist sind erhalten, nicht als beschädigte Testergebnisse ausgegeben.

Der nächste iPhone-Lauf bereinigt den exakt protokollierten alten UUID-Bestand
zuerst ausdrücklich und bestätigt Registry null sowie gespeichertes Opt-out.
Sein neuer Timer und der iPad-Timer enden ebenfalls ausdrücklich ausgeschaltet.
**Historie: drei Ausführungen, zwei PASS, ein FAIL; eine eindeutige Methode.**
Zwölf Original-PNGs und ein aus der ursprünglichen Fehleraufzeichnung dekodierter
Frame sind gesichtet. Abgewiesene optionale direkte Screenshot-Schreibversuche
sind keine gültigen Aufnahmen und werden nicht mitgezählt.

## Quellen, Produkte und Grenzen

[Gebundener Bericht, Fristen, eigene Speicher und Archive](verification/timer-activity-expiry-20261031.json).
265 aktuelle Quellen und 73 SDK-Produktdateien sind gegen die bestehende
Archivbasis vollständig rekonstruiert und zurückgelesen. 26 tatsächliche
kompilierte App-/Test-/Startdateien bleiben durch beide aktuellen Geräteläufe
exakt, je 20 installierte Appdateien passen vollständig zum Testbuild. Die
zusätzliche iPhone-Recovery-Startdatei ist separat gehasht; die ursprüngliche
Startdatei bleibt unverändert.

Im UI-Testpaket fehlt die bekannte inkrementelle SSU-/NLU-Metadatengruppe;
dieser ActivityKit-Test ruft keinen Shortcut auf und behauptet keinen Shortcut-
PASS. Der abschließende normale iOS-SDK-Build stellt mit der vorhandenen einmaligen
Metadaten-Clean-Recovery die vollständige Gruppe her. Alle fünf SDKs bestehen.
Die beiden Paketarten werden nicht als byteidentisch ausgegeben. Core und
Coretests sind gegenüber dem vorigen Musikpaket unverändert, kein neuer Corelauf.

Kein neuer Produkt-Lifecycle-Fix: hinzu kommt nur der ausdrücklich bewachte
eigene Testfrist-Reporter. Keine allgemeine Hintergrundalarm-/autonome Cleanup-
Garantie, kein langer Suspendierungs-/Crash-/Force-quit-, Lock-Screen-, Rechteentzug-,
Mehrfenster-, Spiegelungs-, erweiterter/minimaler oder physischer Nachweis.
Keine persönlichen Quellen, fremden Aktivitäten, Nachrichten/Anrufe oder Home-
Anbindung. Home-/Geräte-/Signing-Holds bleiben unverändert. **#51 bleibt OPEN**;
die ursprünglichen Aufgaben und Abnahmekriterien werden nicht umgeschrieben.
