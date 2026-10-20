# Spiegel-Controller: alte Antwort darf neueren Start nicht stoppen

20. Oktober 2026 · Teilfix für [#64 / SYS-01](https://github.com/Olli0103/homeview/issues/64) und [#80 / QA-05](https://github.com/Olli0103/homeview/issues/80) · [Quellen, Ereignisfolgen und Ergebnisse](verification/mirror-start-lifecycle.json)

## Reproduzierter Logikfehler

NativeMirrorController verwendet dieselbe CaptureBox für aufeinanderfolgende Starts. Nach Stop und erneutem Start kann die Antwort des ersten Versuchs verspätet eintreffen. Der bisherige Generation-Guard verwirft zwar dessen UI-Ergebnis, ruft aber dabei unqualifiziert `capture.stop()` auf. Die Probe zeichnet diese zusätzliche gemeinsame Stop-Anforderung **nach** der neueren Start-Anforderung auf – sowohl bei alter Erfolgs- als auch Fehlerantwort. Die zuerst angeforderte Capture-Antwort wird vor der zweiten geliefert; keine unmögliche Umkehr der seriellen Capture-Reihenfolge ist für das Gegenbeispiel erforderlich.

Weitere Gegenproben zeigen: Bei Ablehnung beziehungsweise Fehler eines aktuellen erneuten Versuchs kann der bisherige veröffentlichte Live-Zustand stehen bleiben. Cleanup des neuesten aufgegebenen Capture-Wunsches und das Verwerfen alter Ergebnisse sind deshalb getrennte Aufgaben.

## Korrektur nach neuestem Wunsch

Der MainActor-isolierte Controller hält jetzt ausdrücklich fest, ob der neueste Wunsch Capture verlangt. Ein altes Ergebnis darf die gemeinsame Box nur noch nachbereinigen, wenn der neueste Wunsch **keine** Capture-Sitzung mehr will. Ein neuerer wartender oder laufender Start wird nicht gestoppt. Aktuelle Ablehnung/aktueller Fehler setzen den Wunsch und Live-Zustand zurück und veranlassen ihre eigene Bereinigung; ausdrückliches Stop invalidiert den Wunsch weiterhin sofort im Controller.

Die Nachlauf-Bereinigung wird absichtlich nicht pauschal entfernt: CaptureBox arbeitet asynchron auf einer seriellen Queue. Eine bereits unterwegs befindliche Startoperation muss nach zuletzt gewünschtem Stop weiter bereinigt werden können. Der Fix ist keine Behauptung, dass jede bereits begonnene Hardwareaktivierung synchron unterbrochen werden könne.

Nur NativeMirrorController wurde geändert. CaptureBox samt realem Queue-/AVFoundation-Code, Berechtigungspfad, Capture-Auswahl, Preview/Views, Zoom/Ringlicht, Center Stage, Dateispeicherung, Home und Projektkonfiguration bleiben bytegleich.

## Was tatsächlich ausgeführt wurde

Die Controller-Klasse wird **literal und ohne Änderung ihres Bodys aus NativeMirror.swift extrahiert**, gehasht und in einem eigenen nativen macOS-Prozess kompiliert. Foundation und Observation sind real; die Symbole AVCaptureDevice, AVCaptureSession und CaptureBox werden im separaten Testmodul durch ausdrücklich lokale Fakes gebunden. Das Testmodul importiert AVFoundation nicht; die Metadaten seines eigenen Executables enthalten keinen AVFoundation-Link. Keine Session oder Permission-API des Betriebssystems wird aufgerufen. Dies ist Controllerlogik mit kontrollierten Abhängigkeiten, **kein ausgeführter realer Capture-Treiber und kein vollständiger App-/iPad-Lauf**.

| Eingefrorener Lauf | Szenarien PASS / FAIL | Assertions / fehlgeschlagen | Einordnung |
| --- | --- | --- | --- |
| Frühe Acht-Fall-Probe | 4 / 4 | 31 / 4 | Enthält eine zu strenge Erwartung: Auch nach zuletzt gewünschtem Stop sollte keine weitere Cleanup-Anforderung erfolgen. Dieser eine Befund wird nicht als zusätzlicher Produktfehler gewertet. |
| Qualifizierter Vorherlauf, Produkt unverändert | 5 / 7 | 45 / 9 | Notwendiges Late-Cleanup nach Stop bleibt erlaubt; neue Gegenproben für Ablehnung/Fehler und vorherigen Live-Zustand. |
| Derselbe qualifizierte Bestand nach Korrektur | 12 / 0 | 45 / 0 | Stubs, Gegenproben und Runner bytegleich zum qualifizierten Vorherlauf. |

Geprüft sind gewöhnlicher Erfolg/Stop, Ablehnung, Stop vor verspäteter Permission-Antwort, Stop vor verspäteter Capture-Antwort, neuere Starts mit alter Erfolgs-/Fehlerantwort, überlappender Start, aktueller Fehler, alte Antwort vor aktueller Ablehnung/aktuellem Fehler sowie Ablehnung/Fehler nach vorherigem Live-Zustand. Alle kontrollierten Antworten werden aufgelöst. Ereignisreihenfolge und Controllerzustand sind als JSON erhalten. Der überlappende Start ist ein direkt geprüfter Controllerfall, keine behauptete Reproduktion einer bestimmten echten Touch-/OS-Zeitfolge.

Fünf aktuelle SDK-App-Builds bestanden. 206 Quellen-/Test-/Ressourcen-/Projekt-/Scriptdateien eingefroren, nur NativeMirror.swift verändert; pro nativer Probe neun Ausführungs-/Compiler-/Harness-Eingaben gebunden. Drei Archive mit je 215 Einträgen vollständig zurückgelesen. Keine neuen Core-/UI-Tests, Bilder, realen Frames oder akustischen Ergebnisse werden beansprucht.

## Offene Grenzen

#64 und #80 bleiben OPEN; F089 partial/parity=false, F090 sowie sämtliche ursprünglichen Kriterien unverändert. Physische Frontkamera, echte Berechtigung/Unterbrechungen, tatsächliche Capture-Queue-/Treiberzeitfolgen, Orientierung/Spiegelung/Zoom/Ringlicht und Hardwarefreigabe sind nicht abgenommen. Kein allgemeiner Beweis für kamera-freie Zeitfenster nach jedem Stop und keine Abnahme aller View-/Task-Lifecycles. Auch [#43 / Center Stage](center-stage-boundaries.md) bleibt offen.

Keine Kamera/Mikrofon-/Frame-/Accountdaten, reale Berechtigungsanfrage, Systemeinstellungen, Nachrichten/Anrufe, Systemalarme oder neuen Live Activities. Der bestehende ausdrückliche Use-Camera-Pfad wurde nicht aktiviert. **Keine Home-Anbindung.**


## Spaeter noch nicht begonnener Starttask

[Die eigene Besitzer-Task-Luecke vor Eintritt in start()](mirror-task-owner.md) ist separat reproduziert und korrigiert. Die obigen Ergebnisse bleiben an ihren urspruenglichen Checkpoint gebunden.
