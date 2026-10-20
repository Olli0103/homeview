# Weltuhr: tatsächliche Trefferflächen

20. Oktober 2026 · Teilfix von [#73](https://github.com/Olli0103/homeview/issues/73), Produkt-/Teststand `5504a02`. Die vollständige Accessibility-Abnahme bleibt offen. [Prüfbericht](verification/world-clock-hit-regions.json).

## Vorher: gemessen, nicht aus dem Schriftbild geraten

Drei vollständige öffentliche XCTest-Audits `.hitRegion` prüfen die sichtbare Städteübersicht, unfiltrierte Auswahl und Suche nach Kathmandu mit wieder geschlossener Tastatur. Alle Befunde werden ungefiltert gespeichert. Die iPad-Listen sind bereits vorher leer; das ist kein Beleg für eine strikte 44-Punkte-Mindestfläche.

Auf dem iPhone meldet die Übersicht **Add City mit 43,26 × 13,65 Punkten** und alle vier Entfernen-Symbole mit je **13,86 × 13,86 Punkten**. Auswahl und gefilterte Suche melden jeweils **Done mit 26,88 × 13,65 Punkten**. Zwei zusätzliche strikte Randtests stoppen schon vor dem ersten Add-Tap: Höhe **28,52 Punkte auf iPad**, **13,65 auf iPhone** statt mindestens 44. Diese fehlgeschlagenen Prüfungen haben den vorgesehenen Rand-Tap noch nicht geliefert; ein fehlgeschlagener gelieferter Tap wird nicht behauptet.

Vorher insgesamt acht UI-Ausführungen: drei erfolgreich, fünf fehlgeschlagen. Schließen, Suchfeld und Auswahlzeilen wurden vom öffentlichen Audit nicht beanstandet. Der kombinierte Randtest erreichte sie wegen der ersten Größenassertion noch nicht.

## Begrenzte Korrektur

Die bisherige Weltuhr verwendet eine skalierte 600-Punkte-Referenzfläche. Deshalb wird die benötigte Labelgröße aus `ceil(44 / nativeCanvasScale)` bestimmt. Add/Done erhalten die Mindestbreite und -höhe im tatsächlichen Textlabel, Entfernen im tatsächlichen Bildlabel, jeweils mit rechteckiger Trefferfläche. Die Auswahlzeilen bekommen ebenfalls die Mindesthöhe, damit der abschließende strikte Randvertrag auch auf dem Telefon gilt. Schrift und Entfernen-Symbole behalten ihre Größe; Zeilen und obere Bedienleiste dürfen wachsen.

`AppHeader` erhält eine optionale Close-Größe mit unverändertem Standardwert 48. Nur die Weltuhr übergibt eine ausreichend große Größe. Damit wachsen Close-Kreis und -Symbol auf dem Telefon zusammen mit der Trefferfläche; andere Aufrufer behalten die bisherige Größe. Keine globale RoundButton-, Pill- oder ButtonStyle-Änderung. Suchfeld, Filterung, Städte-/Zeitzonenmodell, Add-/Remove-Persistenz und Uhrberechnung bleiben unverändert. Keine Pixelgleichheit behauptet.

## Abschluss

Zwölf abgenommene UI-Ausführungen auf iPad/iPhone, über zwei eingefrorene Prüfstände: die drei Audits, tatsächliche Randaktionen, bestehende Kathmandu-Hinzufügung/Entfernung mit Prozessneustarts sowie die bestehende „2 days ahead, nicht Next day“-Regression. Alle sechs vollständigen Abschluss-Auditlisten sind leer.

Der Randfall verlangt vor jedem Ereignis sichtbare, im Viewport enthaltene, mindestens 44 × 44 Punkte große Controls. Er liefert echte Koordinaten zwei Punkte innerhalb des jeweiligen Randes: Add oben, Done unten, Add oben, London-Auswahl oben, London-Entfernen unten und Schließen oben. Nach jedem Ereignis wird die resultierende Ansicht bzw. konkrete Stadtmitgliedschaft geprüft. Geometrien bleiben als JSON erhalten; kein gelockerter Audit, Mittelpunkt-Fallback oder Modellshortcut.

Die erste Produktrunde hat zehn PASS und zwei FAIL: Die Scrollhilfe verlangte acht zusätzliche Punkte oberhalb der bündigen ersten London-Zeile. Diese Marge war durch Scrollen am Listenanfang nicht erreichbar. Nach Archivierung wurden ausschließlich die zwei betroffenen Randfälle erneut geprüft: volle gemessene Listen-/Viewport-Enthaltenheit ohne diese künstliche Marge, weiterhin mindestens 44 Punkte und derselbe reale Zwei-Punkte-Rand-Tap. Beide bestehen; die JSON-Rechtecke bestätigen den bündigen Beginn. Der Produktcode blieb unverändert, die zehn bereits erfolgreichen Prüfungen werden nicht als neue Ausführungen gezählt. Es wird kein einzelner vollständig grüner Zwölferlauf behauptet.

Gesamte Historie: 22 UI-Ausführungen, 15 erfolgreich, sieben frühere Fehler, keine Skips oder Runtime-Warnungen. 206 Quellen und je 28 kompilierte Eingaben samt installierter Appbytes gebunden; drei Archive vollständig zurückgelesen. 52 PNGs dekodiert, sechs Übersichten und sechs zusätzliche Vollbilder gesichtet, 20 eigene Bilder im Bericht.

Fünf aktuelle SDK-Builds. Die früheren 301 Modelltests und 50 AppModel-Assertions bei `2b223b7` sind historische Ergebnisse: 72 Core-/Coretest-Dateien, AppModel und dessen bestehender Probe bleiben bytegleich. Für diese UI-Änderung wird kein neuer Modell-/nativer Prozesslauf behauptet.

## Grenzen

Der öffentliche Audit gilt nur für die drei aufgenommenen sichtbaren Zustände, nicht alle offscreen Städte, Einstellungen oder Plattformansichten. Die automatischen Prüfungen sind keine tatsächliche VoiceOver-/Voice-Control-/Switch-Control-/AssistiveTouch-, Fokus-, Ansagen-, Dynamic-Type-, volle Kontrast-, Hardware- oder Originalabnahme. Keine Systemzeit oder Gerätezeitzone geändert; synthetische Referenzzeit und eigene lokale Teststores. F103 bleibt partial, parity=false. Keine echten Daten, Freigaben, Aufnahmen oder neuen Systemaktivitäten. **Keine Home-Anbindung.**

## Nachtrag: opt-in Close-Sizing

Die spätere [lokale Wecker-Korrektur](alarm-hit-regions.md) verwendet ebenfalls den optionalen Close-Parameter. Die oben dokumentierten Weltuhr-Messungen bleiben an ihren historischen Produkt-/Prüfstand gebunden.
