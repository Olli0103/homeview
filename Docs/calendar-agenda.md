# Kalender: vollständige Tagesabfragen und Freigabegrenzen

17. Oktober 2026 · [DAY-01, #47](https://github.com/Olli0103/homeview/issues/47), ergänzende Grenzen aus [SYS-04, #67](https://github.com/Olli0103/homeview/issues/67).

Die EventKit-Anbindung bleibt ausdrücklich opt-in. Verbinden fragt die OS-Freigabe an, liest im gesperrten Zustand aber keine Datensätze. Das bestehende Geräte-Entsperren und die Generationen gegen späte Antworten bleiben erhalten. Es wird kein echter Kalender im automatischen Test geöffnet oder verändert.

## Korrigiert

- Tagesbeginn und exklusives Tagesende werden in der **angezeigten Zeitzone** berechnet. DST-Tage dürfen 23 oder 25 Stunden haben.
- Aktualisieren und Wiederherstellen bereits gewählter Verbindungen prüfen bestehende OS-Rechte; sie stellen nicht erneut eine Freigabeanfrage.
- Entzogene Rechte leeren die Agenda und zeigen einen Verbindungsfehler. Die gewählte Datenquelle bleibt getrennt vom Erfolgszustand: Kein stiller Ersatz durch die Demo-Agenda. Erst ein ausdrückliches Trennen beendet diese Quellenwahl.
- EventKit löst Wiederholungen für das Abfrageintervall auf. Ein Vorkommen erhält eine stabile Identität aus Kalenderobjekt und Startzeit; verschiedene Vorkommen teilen nicht dieselbe SwiftUI-ID.
- Ganztägige und über Mitternacht laufende Termine, abgesagte Termine und Quellen-/Ortslabels bleiben unterscheidbar. Sortierung erfolgt vor jeder Begrenzung.
- Bei mehr als 200 passenden Tagesterminen schlägt die Agenda explizit fehl. Es gibt keine unbemerkte unvollständige 200er-Liste.
- Manuelles Aktualisieren und `EKEventStoreChanged` aktualisieren die ausgewählte Tagesansicht, sofern die Sitzung entsperrt und die Quelle noch verbunden ist. Späte Ergebnisse werden weiterhin generationengeprüft.

## Offen

Ein bewusst eingerichteter Testkalender auf physischer Hardware, reale Accountwechsel/-wiederholungen, tatsächliche EventKit-Änderungsbenachrichtigungen und OS-Freigabewiderruf sind nicht durch die synthetischen Prüfungen belegt. #47 bleibt deshalb offen. Die App liest freigegebene Kalender; sie erstellt oder ändert keine Termine.

## Teststand

66 Modelltests, je drei gezielte UI-Fälle auf iPad/iPhone und fünf SDK-Builds bestanden. [Quellenbindung und Ergebnisse](verification/calendar-accessible.json). Der vorausgehende Fünferlauf bestand vier Fälle je Gerät; nur der Refresh-Knopf scheiterte an einer vererbten Accessibility-Kennung. Nach Korrektur wurden Agenda, Zugriffsverweigerung und verbundene Kalenderansicht erneut geprüft. Die vorherigen Hintergrund-/Reminder-Fälle werden nicht als neue aktuelle Ausführungen gezählt.
