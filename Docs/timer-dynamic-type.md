# Timer: skalierende Textrollen und erreichbare Accessibility-Anordnung

29. Oktober 2026 · [#73](https://github.com/Olli0103/homeview/issues/73). **Begrenzte mobile Dynamic-Type-/Bedienprüfung, keine vollständige F103-/Hilfsmittelabnahme.**

## Befund und Korrektur

Timer-Titel, Status und Auswahl-Control blieben auf iPhone/iPad bei größter Accessibility-Systemschrift genau so hoch wie bei Normalschrift: sechs Verhältnisse **1,00**. Der unveränderte semantische Kontrolltitel im Vorleseeinstellungsblatt wuchs gleichzeitig etwa fünfmal in der Höhe, einschließlich Umbruch. Die Systempräferenz war wirksam. Die Mindestvergrößerung von 1,25 und der exakte Normal-Pixelvergleich standen vor der Produktänderung fest.

Nur `TimerView` in `Everyday.swift` geändert: öffentliche `ScaledMetric`-Werte für Titel, Status und Auswahl. Bei Accessibility-Größen ersetzt eine vertikal scrollbar angeordnete Ansicht das zusammengedrückte Zifferblatt; Texte und Aktionen werden einzeln erreicht, nicht zwingend gleichzeitig gezeigt. Explizite Controls bleiben dort auch unabhängig vom Ruhezustand der normalen Ansicht vorhanden. Die Auswahlzeile erhält eine zur Schrift passende Höhe. Die großen Countdown-Ziffern selbst werden nicht als neu skalierend ausgegeben. Werte, Auswahl, Pause/Löschen und die normale Vier-Sekunden-Regel bleiben unverändert.

| Native Rechteckhöhe: größte/Normalkategorie | iPhone | iPad |
|---|---:|---:|
| Titeltext | 2,81 | 2,81 |
| Statustext | 3,14 | 3,15 |
| Auswahl-Control, einschließlich Padding | 1,94 | 1,94 |

Das sind AX-Text-/Controlrechtecke, **keine isolierten Glyphen- oder Schriftgrößenfaktoren**. Die aufgenommenen Texte und vollständig erreichten Auswahlzeilen wurden zusätzlich tatsächlich gesichtet. Pausierter Einzelwert bleibt `10:56`; der echte Tap wählt Tea mit `03:00`, nach dessen Löschen bleibt Bread mit `10:00` erhalten. Keine Ersatzaktion oder nur anhand eines Identifiers angenommene Bedienung.

Die vier normalen Timer-Viewports sind vor/nach **exakt RGBA-pixelgleich, null geänderte Kanäle**. Zwei frühere normale Vorherstände sind ebenfalls exakt gleich. Keine Masken oder Toleranzschwellen. Die große Accessibility-Anordnung darf sich bewusst unterscheiden; daraus folgt keine neue Original-Parity.

## Testeingaben qualifiziert, Fehler erhalten

- Die erste strikte Double-`CGRect.contains`-Prüfung wies bereits vorhandene Auswahlgrenzen wegen subpixeliger AX-Rundung zurück. Die bestehenden Float-normalisierten Bounds akzeptieren sie; Abweichungen liegen um 0,00004 Punkt. Vier ursprüngliche Fehler bleiben erhalten. Kein Sichtbarkeitsclip oder Vergrößerungsziel gelockert.
- Vor dem Produktfix wurde die Prüfung um einzelne erreichbare Rollen bei optionalem Scrollbereich erweitert. Derselbe Timer-/Kontrolltextfall wurde danach unverändert gemessen; sechs Vorher-Vergrößerungsfehler bleiben belegt.
- Der erste neue Scrollhelfer verlangte auch von nicht interaktiven Texten AX-Hittability und nutzte Gutter-Gesten. Vier Fehler erhalten. Die native semantische Scrollaktion erreichte denselben 16-Punkte-Innenclip. Die sichtbare, aktivierte Auswahl meldete weiterhin AX-Hittability=false; zwei `element.tap()`-Versuche wurden von XCTest vor tatsächlicher Pointer-Eingabe verweigert.
- Nach Sicht-/Bounds-/Enabled-Prüfung liefert ein echter Koordinaten-Tap mit exaktem Auswahl-/Lösch-/Peer-Read-back den positiven Bedienbeleg. Das ist eine **Funktionsprüfung am Mittelpunkt**, keine zusätzliche Randpunkt-/Trefferflächenabnahme. Während dieser Testeingabequalifikation blieb der Produktcode unverändert.

## Idle-Test: zwei Quellpins, gleiche App

Sieben von acht vorhandenen normalen Regressionen bestanden zunächst. Beim iPhone-Idle-Fall lagen Eingabesynthese und anschließende Abfrage laut Log etwa **3,88–4,19 Sekunden** auseinander: AX-Polling plus weitere 2,8 Sekunden garantierten kein Vor-Vier-Sekunden-Fenster. Der genaue physische Ereigniszeitpunkt ist daraus unbekannt; keine behauptete exakte 4,17-Sekunden-Messung oder dadurch bewiesene Produktregression. Der gleiche iPad-Fall bestand bereits.

Nur diese bestehende Testmethode wurde danach korrigiert: zweite Eingabe absolut an monotone Zeit gebunden, Controller-Budgets ausdrücklich geprüft, sichtbare Rücksetzprüfung mehr als fünf Sekunden nach Rückkehr der ersten Eingabe und weniger als 3,8 Sekunden nach Beginn der zweiten. Die tatsächlichen neuen Abstände betragen **5,201/2,710 Sekunden auf iPhone** und **5,210/2,736 auf iPad**. Beide vollständigen Idle-/Rücksetz-/erneuten Ausblend-/Löschfälle bestehen. Produkt-Vier-Sekunden-Grenze und Acht-Sekunden-Ausblendewartezeit nicht geändert.

**20 akzeptierte aktuelle UI-Ausführungen über zwei Testquellpins**, sieben eindeutige Methoden: zwölf Normal-/XXXL-Matrixfälle, sechs andere normale Timerregressionen und zwei korrigierte Idle-Fälle. Der frühere bereits grüne iPad-Idle-Lauf wird nicht doppelt zu diesen 20 addiert; der fehlgeschlagene iPhone-Lauf bleibt historische Evidenz. Alle **19 kompilierten App-Bundledateien** über die reine Testkorrektur bytegleich, installierte Apps jeweils geprüft. Keine erfundene gemeinsame 233-Dateien-Bindung über diese Testkorrektur.

## Gebundener Prüfstand

- Fünf SDK-Builds mit 73 Produktdateien und sechs Tooling-Tests bestanden am unveränderten Produktcode; danach ausschließlich die genannte UITest-Zeitsteuerung geändert. SDK-/erster UI-Pin `f031eaf…`, abschließender Testquellpin `a13fce2…` ausdrücklich getrennt.
- 233 finale Quellen; **164 andere Produktinputs unverändert**. 89 Core-/Package-/Coretest-Eingaben bytegleich zum bisherigen 405-Test-Stand; kein neuer Core-Lauf.
- 28 tatsächliche UI-Inputarchive vollständig zurückgelesen; Quellen, kompilierte Eingaben und installierte Appbytes gebunden. Gesamte UI-Historie **76 Ausführungen: 65 erfolgreich, elf frühere Fehler**; keine 76er-Erfolgssuite.
- 210 PNGs dekodiert, 32 Übersichten und sieben volle Einzelbilder gesichtet. 14 eigene Vorher-/Nachher-Bilder bytegeprüft veröffentlicht. Schriftpräferenzen nach allen Matrizen wieder `large`.

Die zusätzliche aktuelle Asset-Inventur meldete zunächst einen bereits im veröffentlichten `478f536` veralteten Whole-Source-Hash von `HomeScreens.swift`. Gegen `eb81e22` geprüft: ausschließlich der inzwischen gelieferte `PersonalHomeEditor`-Block geändert, `DemoAlbumCover` und übrige Dateiabschnitte bytegleich. Die aktuelle Quellenbindung wurde mit dieser Qualifikation erneuert; Ressourcen-/Rechteangaben und historische Deklaration unverändert. Danach Inventar- und Backlogprüfung bestanden. Kein neuer Rechts- oder Artwork-PASS aus einer bloßen Hash-Aktualisierung.

[Einzelne Testpins, Zeitbelege, Quell-/Archivbindung und Bilder](verification/timer-dynamic-type.json) · [eigene synthetische Bilder](screenshots/timer-dynamic-type) · [bestehender Idle-Umfang](timer-idle.md).

**#73 bleibt OPEN, F103 partial/parity=false.** Nur Default und größte Accessibility-Kategorie auf diesen zwei Simulatoren geprüft. Timer-Einrichtung/Header, andere Screens, alle Zwischenkategorien/Sprachen/langen Titel, Zoom und echte VoiceOver-/Voice-Control-/Switch-Control-/AssistiveTouch-Sitzungen bleiben separat. Kein neuer Alarm, Live Activity, Ton, Mikrofon/Kamera, persönliches Konto oder Home. Geräte-/Signing-Pause unverändert; Gesamtbacklog wird fortgesetzt.
