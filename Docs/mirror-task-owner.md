# Spiegel: Start-Task endet mit seinem Ansichtsbesitzer

20. Oktober 2026 · Teilfix für [#64](https://github.com/Olli0103/homeview/issues/64) und [#80](https://github.com/Olli0103/homeview/issues/80) · [Quellen und native Gegenproben](verification/mirror-task-owner.json)

## Zweiter, eigenständiger Randfall

Der [vorherige Fix](mirror-start-lifecycle.md) schützt einen neueren Capture-Wunsch vor bereits gestarteten alten Antworten. Er löst aber nicht die Lücke **vor dem Beginn** des asynchronen Startaufrufs: Der Use-Camera-Callback erzeugt bisher einen ungebundenen Task. Verlassen beziehungsweise Hintergrund kann Stop ausführen, bevor dieser Task überhaupt beginnt. Dessen späteres `start()` erzeugt dann eine neue Generation und fragt erneut Permission/Capture an.

Die native Probe führt die aus der Produktquelle übernommenen Callback-Körper auf demselben MainActor aus: Use Camera → Kind-Task angelegt, noch kein Actor-Yield → Verlassen oder Hintergrund → erst danach Kind-Task. Die Setup-Assertions bestätigen null Fake-Anforderungen vor dem Besitzerende. Vor der Korrektur folgen anschließend trotzdem Fake-Permission-/Capture-Anforderungen und ein erneut veröffentlichter Live-Zustand. Zwei Fälle und vier Assertions scheitern; die zwölf früheren Controller-Gegenproben bestehen weiterhin.

## Begrenzte Korrektur

Die Ansicht hält den Start-Task in State und cancelt/entfernt ihn vor Ersatz, Stop, Hintergrund und Verlassen. Der Controller prüft Cancellation direkt am Einstieg, bevor er Generation, Capture-Wunsch oder Permission-Pfad beginnt. Ein bereits in Permission/Capture wartender Versuch bleibt zusätzlich durch den bestehenden Generation-/Wunschschutz abgesichert.

Der bloß inaktive Zustand wird weiterhin nicht wie Hintergrund behandelt; das bestehende Verhalten beim Öffnen von Systemkontrollen wird nicht pauschal entfernt. Rückkehr in den Vordergrund erzeugt keinen automatischen neuen Start. CaptureBox/Treiber, Preview-/Zeichnungs-/Layoutcode, Zoom/Ringlicht, Berechtigungspfad und Center Stage werden nicht erweitert. Keine neue Pixelgleichheit geprüft.

## Was der Testhost ist – und was nicht

Die Controller-Klasse und drei Callback-Körper werden direkt aus NativeMirror.swift extrahiert und gehasht. Für die Callback-Körper wird ausschließlich die äußere bekannte iOS/macOS-/AVFoundation-Compilerbedingung ausgewählt. Ein eigener MainActor-Host stellt normale Felder anstelle von SwiftUI-State bereit. Task-Erzeugung und Cancellation sind echte Swift-Concurrency-Operationen, Permission und Capture bleiben lokale symbolische Fakes.

Das ist keine tatsächliche SwiftUI-Render-/Lifecycle-Zustellung, kein vollständiger App-Lauf und kein realer AVFoundation-Treiber. Die eigene Probe importiert/linkt AVFoundation nicht und konstruiert keine echte Kamera, Session oder Berechtigungsanfrage. Der erzwungene Actor-Ablauf ist ein kontrollierter Callback-Gegenfall, keine behauptete gemessene physische Touch-/OS-Zeitfolge.

| Eingefrorener Stand | Szenarien PASS / FAIL | Assertions / fehlgeschlagen |
| --- | --- | --- |
| Vorher, Produkt unverändert | 15 / 2 | 68 / 4 |
| Nachher, gleiche Stubs/Gegenproben/Runner | 17 / 0 | 68 / 0 |

Die fünf Besitzerfälle prüfen Verlassen/Hintergrund vor Task-Beginn, unverändertes Inactive-Verhalten, den Stop-Button nach Live sowie Verlassen bei bereits wartender Permission. Die zwölf vorherigen Szenariokörper sind bytegleich erhalten und erneut ausgeführt. Alle kontrollierten Antworten werden aufgelöst. Nach Besitzerende vor Task-Beginn bleiben Fake-Permission- und Capture-Zähler null; bereits wartende Permission darf weiterhin keine Capture nachstarten.

Fünf aktuelle SDK-App-Builds bestanden. 206 Quellinputs, nur NativeMirror.swift geändert; je elf native Compiler-/Harness-/Callback-/Ausführungseingaben gebunden. Zwei Archive mit je 217 Einträgen vollständig zurückgelesen. Keine neuen Core-/UI-Tests, Bilder oder realen Frames beansprucht.

## Offen

#64/#80 bleiben OPEN; F089 partial/parity=false, F090 und sämtliche ursprünglichen Kriterien unverändert. Echte iPad-/Kamera-/Permission-/Treiberzeitfolgen, tatsächliche SwiftUI-Lifecycle-Zustellung und physische Unterbrechungs-/Spiegel-/Zoom-/Ringlichtabnahme bleiben offen. Kein allgemeiner Beweis für kamera-freie Intervalle nach jedem Stop. Auch Center Stage bleibt separat offen.

Keine Kamera/Mikrofon-/Frame-/Accountdaten, echte Permission-Anfrage, Systemeinstellung, Nachricht/Anruf, Systemalarme oder neue Live Activities. **Keine Home-Anbindung.**
