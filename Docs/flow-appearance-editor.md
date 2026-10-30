# Flow: sichtbare Color-/Font-Seite

30. Oktober 2026 · [#7](https://github.com/Olli0103/homeview/issues/7), [#15](https://github.com/Olli0103/homeview/issues/15)

## Beleg versus eigene Ergänzung

Die bereits archivierte UI37 wurde erneut direkt gesichtet und bytegeprüft (SHA-256 `16553706af50e183de50e97b24faf18be662a406856f200ba0c3e0178c155524`). Das perspektivische Eventfoto zeigt einen dunklen Editor, **COLOR/FONT**, eine gerahmte Vorschau, seitliche Farbfelder, **Automatic**, X und Haken. Die sichtbare Vorschau enthält eine **einzeilige10:09**. Eine vollständige Fontseite, exakte Farbnamen/-werte, alle verborgenen Felder oder die Automatic-Regel sind aus diesem Standbild nicht ablesbar. Kein nativer Pixelscreen.

Die Replik bietet im bestehenden Flow-Editor **Color and font** an. Dort liegen die belegten UI-Elemente als eigene öffentliche SwiftUI-Oberfläche. Acht eigene beschreibende Farbvarianten nähern die sichtbaren Swatches an; Anzahl, Namen und Kanalwerte sind keine behauptete rekonstruierte Originalpalette. Automatic setzt ausschließlich unsere bisherige dynamische Standardfarbe zurück. Eine unbekannte Original-Automatik wird damit nicht als identifiziert ausgegeben.

Der fehlende einzeilige Zustand ist als zusätzliche eigene Variante **Inline / III** verfügbar. Dafür wird öffentliche gerundete Runtime-Typografie durch das vorhandene eigene Material gezeichnet. Keine Fontdatei oder persistierte Schriftkontur wird extrahiert. Die bisherigen eigenen Solid-/Stencil-Varianten bleiben erhalten; drei Replik-Einträge beweisen keine drei Originalfonts. UI47 belegt unabhängig aufgeblasene0/1/9. Diese nutzen nun dieselbe eigene Ellipsen-/Kapsel-/Punktkonstruktion wie UI09, ohne dadurch den weiterhin ungeklärten Originalnamen von UI09 zu behaupten. Eigene Strichüberschneidungen werden vor Material/Stencilschnitten vereinigt. Andere Originalziffern und Achsen bleiben nicht vollständig belegt.

Vorhandene öffentliche SwiftUI-, Speicher-, Timeline- und Materialpfade wurden wiederverwendet, keine zusätzliche Bibliothek, Cloudquelle oder Privat-API installiert.

## Stufen und Schreibgrenze

Farbe und Font werden zuerst nur im lokalen Ansichts-Entwurf geändert. X verwirft beides. Erst der Haken schreibt die beiden Werte über den normalen geschützten Writer. Alle übrigen Flow-Einstellungen, Slots, Nachbar-Faces und das globale Legacy-Theme bleiben erhalten. Bei Ablehnung bleiben Seite und Entwurf offen, statt Erfolg zu melden.

Alte Speicher ohne Palette behalten0/Automatic sowie vorhandenen Font/Hintergrund. Fehlerhafte Paletten fallen einzeln auf0zurück, ohne gesunde Geschwister zu verwerfen. Zulässige Werte0–7 und Font0–2 überstehen den normalen Snapshot-Roundtrip. Die neuen Farbfilter sind bei Automatic, Nacht und reinem Glyphentest ausgeschaltet; keine neue Simulation oder automatische Farb-/Audio-/Home-Aktion.

Die gemalten Farbpunkte bleiben klein, die tatsächlichen Touchflächen werden auf mindestens44native Punkte ausgelegt. Die seitliche Auswahl scrollt bei kleinen Fenstern; die ganze Seite bei großer Schrift. Die vorhandenen direkten Schrift-/Hintergrundregler bleiben erreichbar. Die Vorschau ist schreibgeschützt, ohne unsichtbare interaktive Home-Controls.

## Gemeinsamer Prüfplan

472Coretests vor Ergänzung des Inline-Zustands bestanden; anschließend elf betroffene Migrationsmethoden mit allen24eigenen Farb-/Fontkombinationen grün. Die übrigen unveränderten Coregruppen wurden dafür nicht erneut gestartet. Die erste native Auswahl mit acht bestandenen Ausführungen bleibt ein technischer Zwischenstand: ihre zweizeilige Vorschau deckte den sichtbaren einzeiligen Zustand aus UI37 noch nicht ab.

Aktuelle native Quellen-/Binärbindung, gemeinsame Editor-/Glyphenfälle, Bilder, endgültige SDKs und Grenzen werden im Paketbericht festgehalten. Es gibt keinen aus Klicktests abgeleiteten Original-Parity-PASS. Keine persönlichen Stores, Kamera/Mikrofon oder Home-Geräte; Geräte-/Signingabnahmen bleiben pausiert.

## Begrenzter aktueller Quellenabgleich

Eine gezielte Websuche nach HomeView-Editor/Color/Font/Automatic und der vollständige aktuelle Haupttext der ursprünglichen [Verge-Quelle S01](https://www.theverge.com/tech/1009877/apple-homeview-smart-home-display-hands-on) wurden am30.Oktober ergänzend gelesen. HTTP200, nicht abgeschnitten. Der Artikeltext liefert weiterhin keine vollständige Editorpalette, Fontseite oder Automatic-Regel. Eine spätere Suchtrefferdatierung ist keine neue Vorführung. Dies ist ein begrenzter Befund dieser Abfragen, kein Beweis, dass sämtliche anderen Frames/Quellen fehlen. Der ursprüngliche Katalog24/51wird dadurch nicht als neu vollständig geprüft ausgegeben.

## Tatsächlicher Glyphenbefund vor Veröffentlichung

Die erste gemeinsame Fünf-SDK-Prüfung war grün. Der anschließend tatsächlich gesichtete eigene Atlas zeigte dennoch: Bei hoher bisheriger Strichstärke0,32–0,44laufen die eigenen Ersatzziffern2/3und5/8zu ähnlich zusammen. Deshalb wurde dieser Stand nicht als fertige visuelle Abnahme veröffentlicht. Die eigene Fallback-Strichspanne beträgt nun0,20–0,24; die beobachteten0/1/9verwenden ihre getrennte Geometrie und die öffentliche Inline-Schrift bleibt unberührt. Drei betroffene Coremethoden für Achsengrenzen/Ziffernpaare/alle Tageszeiten erneut geprüft, keine unveränderten Coregruppen wiederholt. Die zeit-/glyphenbezogenen nativen Methoden werden am neuen Produkt geprüft; Editor-/Schreiblogik wurde dafür nicht geändert. Dies bleibt ein eigener lesbarer Fallback, keine rekonstruierte Originalfamilie.

## Uhrwert und erhaltene Messgrenzen

Der normale Flow-Root nennt nun seinen tatsächlichen Zeitwert ausdrücklich. Ein neuer Zeitfall hatte zunächst eine unqualifizierte innere Beschriftung abgefragt, die im nativen Snapshot nicht vorhanden war. Anschließend war die Uhrwert-Metadatenhülle zu weit gefasst und störte den getrennten Testzähler. Die Uhrbeschriftung liegt nun vor dessen Overlay. Der vorhandene Revisions-/8-Sekunden-/komplette-PNG-Gleichheits-/Nacht-keine-Arbeit-Vertrag blieb unverändert und besteht wieder; kein nachträgliches PASS für die Fehlstände. Eine interne SDK-Ursache wird daraus nicht erfunden.

Die erste Sammel-Erreichbarkeitsmethode stoppte bereits vor dem ersten Farbtap an unqualifiziertem `isHittable`. Die korrigierte Methode verwendet vollständig sichtbare native Kontroll-/Pane-Rechtecke, tatsächliche Fenstermittelpunkttaps und geänderte Auswahlwerte. Alle acht Farben und drei Fonts wurden so bedient;11Buttons je Gerät mit mindestens44nativen Punkten gemessen (nur0,01Punkt numerische Präzision). Dafür war keine Produktkorrektur nötig. Der bereits grüne iPhone-Speicher-/Nachtfall wurde bei20exakt identischen Appdateien nicht wiederholt; iPad-Fall und Sammelwahl fehlten noch und wurden ausgeführt.

## Verbleibender ursprünglicher Vertrag

Die sichtbare Editor-/Inline-Lücke ist umgesetzt; eigene nutzbare Varianten und Metriken sind keine Bestätigung aller Originalfonts, Paletten oder Auto-Regeln. Die vollständige Originalfamilie0–9/Achsen bleibt nach dem ausdrücklichen Eigentümerreview bei#15offen. Bei#7fehlen weiterhin vollständige Originaloptionen und die vollständige Fokus-/Hilfsmittelabnahme. Physische/signierte Abnahmen bleiben pausiert. Kein Issue wird nur aus einem eigenen Ersatzumfang geschlossen.

[Prüfbericht und Quellen-/Produktbindung](verification/flow-appearance-editor-20261030.json).

## Abschließender Paketstand

Fünf endgültige SDKs bestanden (iOS mit der dokumentierten einmaligen regulären Metadaten-Recovery),77SDK-Dateien und15Quellen-/Binärarchive vollständig zurückgelesen.175aktuelle Quellen-/Projektinputs exakt, beide zuletzt installierten Apps je20Dateien exakt zum finalen UI-Archiv.180aktuelle Pfade und1800tatsächliche Pfadpaare geometrisch geprüft;27beobachtete0/1/9-Pfadpaare vor/nach der Fallbackänderung **exakt gleich**. Das ist keine ganze Originalpixel- oder Geräteparität.

Native Historie33Ausführungen:30PASS und3erhalteneFAIL. Die fünf abschließenden betroffenen Methoden am letzten Pin bestanden; zwei frühere positive iPhone-Atlas-/Abstractmethoden liegen an unverändertem Renderingcode, nicht an identischem Gesamt-Appbinary. Die vier bestätigten Editor-/Speicher-/Nachtfälle am vorherigen semibold Produkt bleiben getrennt gebunden. Alle übrigen unveränderten UI-Suites wurden nicht erneut gestartet.

Tatsächlich gesichtet: zehn akzeptierte Editor-/Inline-/Nachtbilder, zwölf aktuelle farbige Flow-Zeitansichten, acht neue Atlasbilder und acht Abstract-Zeitansichten, außerdem acht frühere verworfene Atlasbilder. Zehn eigene Ansichten veröffentlicht; Quellen und Originalbilder bleiben privat. Sämtliche Ergebnisse sind nach Phase/Binary gebunden, keine Umdeutung fehlgeschlagener oder supersedierter Prüfstände in einen finalen PASS. #7/#15 bleiben für ihre genannten ursprünglichen Restkriterien offen.
