# Lokale Wecker: größere Trefferflächen und auslesbarer Zustand

20. Oktober 2026 · Teilfix von [#73](https://github.com/Olli0103/homeview/issues/73), Produkt-/Teststand `974c460`. [Prüfbericht](verification/alarm-hit-regions.json). Die umfassende Accessibility-/Geräteabnahme bleibt offen.

## Tatsächliche Vorherbefunde

Drei vollständige öffentliche `.hitRegion`-Audits prüfen einen ausgeschalteten Standardwecker, zwei synthetische Einträge und die leere Liste. Alle Befunde werden ungefiltert gespeichert. Auf dem iPhone beanstandet die erste Liste das Löschen-Symbol mit **10,29 × 11,76 Punkten**, die Zwei-Zeilen-Liste beide gleich kleinen Löschen-Controls. Die leere Liste und alle drei iPad-Audits bestehen bereits vorher. Ein leerer öffentlicher Audit ist nicht gleichbedeutend mit einer strikten 44-Punkte-Abnahme.

Der separate Randfall stoppt auf dem iPhone vor dem ersten Ein/Aus-Tap bei nur **23,94 Punkten Höhe**. Auf dem iPad werden Ein/Aus oben, Ein/Aus unten und Hinzufügen oben bereits erfolgreich geliefert; anschließend stoppt die Größenassertion **vor** dem Löschen-Tap bei **24,54 Punkten Höhe**. Keine falsche Behauptung, diese nicht gelieferten Ereignisse hätten die App verfehlt. Vorher acht Ausführungen: vier erfolgreich, vier fehlgeschlagen.

## Korrektur nur in AlarmsView

Die tatsächlichen Toggle-/Delete-Labels erhalten eine aus `ceil(44 / nativeCanvasScale)` berechnete Mindestbreite und -höhe sowie rechteckige Trefferflächen. Die Symbolgrößen bleiben erhalten. Der lokale Add-Button behält die bisherige Pill-Darstellung, bekommt aber die Mindesthöhe im Label. Die Weckeransicht nutzt das bereits vorhandene optionale Close-Sizing; Kreis und Symbol dürfen am Telefon wachsen. Keine Änderung an globalem Pill, RoundButton, ButtonStyle oder AppHeader.

Hinzufügen und Schließen waren keine öffentlichen Vorher-Auditbefunde; ihre Mindestflächen gehören zum zusätzlichen strikten Randvertrag. Die Stunden-/Minuten-Picker bleiben unverändert. Ebenso AppModel, Speichern, Systemalarmplanung und Zeitberechnung.

Zusätzlich aus der Quellenprüfung: Toggle und Delete nennen nun die Uhrzeit; Toggle hat den expliziten Accessibility-Wert **On/Off**. Der Abschluss prüft den tatsächlichen AX-Wert Off → On → Off. Das ist eine ergänzte auslesbare Semantik, keine behauptete frühere VoiceOver-Reproduktion oder echte Hilfsmittelabnahme. Mehrere identische Uhrzeiten können weiterhin gleiche Beschriftungen haben; eine vollständige Fokus-/Reihenfolge- oder eindeutige Voice-Control-Zielabnahme wird nicht behauptet.

## Begrenzte Abschlussprüfung

Die drei Audits je Gerät sowie der Randfall werden auf iPad und iPhone ausgeführt. Die sechs Abschluss-Auditlisten sind leer. Der Randfall verlangt sichtbare, im Viewport enthaltene, mindestens 44 × 44 Punkte große Controls und liefert echte Koordinaten zwei Punkte innerhalb der Ränder: Ein/Aus oben und unten, Add oben, neues konkretes Delete unten, ursprüngliches Delete oben, Add unten und Close oben. Tatsächliche Werte, konkrete Identitäten, Eintragszahlen und Rückkehr zur persönlichen Appansicht werden geprüft; kein Mittelpunkt-Fallback und kein Modellshortcut.

**Ausschließlich lokale Vordergrundwecker:** Jeder Start enthält `--uitesting`, nie `--system-alarms`. Der bestehende AppModel-Guard deaktiviert dadurch native Planung. Die UI verlangt Foreground alarm statt System alert enabled. Keine AlarmKit-Freigabe, Benachrichtigung, Audio- oder Hintergrundzustellung geprüft. Der ausgeschaltete Standard ist 07:00, die Zeit wird nicht bis zum Ablauf vorgespult.

## Eingaben und Prüfstand

Acht finale UI-Ausführungen bestanden, vier Methoden auf beiden Geräten. Historie: 16 Ausführungen, zwölf erfolgreich, vier dokumentierte Vorherfehler; keine Skips oder Runtime-Warnungen. Fünf aktuelle SDK-Builds. 206 Quellen und je 28 kompilierte Eingaben samt installierter Appbytes gebunden; beide Archive mit je 234 Einträgen vollständig zurückgelesen. 42 PNGs dekodiert, vier Übersichten und vier zusätzliche Vollbilder gesichtet, 16 eigene Bilder im Bericht.

72 Core-/Coretest-Dateien bleiben bytegleich zum historischen 301er-Lauf bei `2b223b7`; AppModel unverändert. Kein neuer Core-/nativer Modelllauf oder zusätzlicher AlarmKit-Prozess behauptet. Die bisherige native Assistentenprobe ist keine Weckerabnahme und wird hierfür nicht als Ersatz verwendet.

## Grenzen

Nur diese sichtbaren Listen-/Aktionszustände; nicht 24 Einträge, alle offscreen Zeilen, geöffnete Zeit-Picker, andere Plattformansichten oder reale Systemalarme. Keine tatsächliche VoiceOver-/Voice-Control-/Switch-Control-/AssistiveTouch-, Fokus-, Ansagen-, Dynamic-Type-, volle Kontrast-, Hardware- oder Originalabnahme. Keine Pixelgleichheit: Trefferflächen und Close-Darstellung können wachsen. F103 bleibt partial, parity=false. Eigene synthetische Daten; keine echten Konten, Aufnahmen, Berechtigungsänderungen oder neuen Live-Aktivitäten. **Keine Home-Anbindung.**
