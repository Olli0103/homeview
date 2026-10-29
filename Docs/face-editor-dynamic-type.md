# Face-Editor: UI-Schrift wächst, normale Ansicht bleibt gleich

29. Oktober 2026 · Teilabnahme zu [#73](https://github.com/Olli0103/homeview/issues/73), keine vollständige Accessibility- oder Original-Parity.

## Vorher und Korrektur

Auf der unveränderten Produktbasis `2b2c822` wurden Modular-Editor, Slotliste und nativer Picker bei normaler und größter Accessibility-Schrift auf iPhone und iPad aufgenommen. Vier zunächst gescheiterte Inventurmethoden bleiben erhalten: Der native Off-Button ist ein kombinierter AX-Knoten und hat keinen gemeldeten StaticText-Kindknoten. Erst nach dieser reinen Testkorrektur wurden vier vollständige Vorherfälle ausgeführt; alle bestehen, aber zehn gesonderte Schriftvergrößerungsbedingungen scheitern bei etwa 1,00. Die nativen Titel-/Off-Control-Gegenkontrollen wachsen dagegen etwa 2,53–2,54 bzw. 1,82-fach.

Nur `FaceEditor.swift` geändert: fünf lokale `ScaledMetric`-Rollen für Titel, Face-Auswahl, Abschnitt, Slotfamilie und Anleitung. Die Auswahlchips wachsen bei Bedarf über ihre bisherige Höhe hinaus. Normale Ausgangsgrößen bleiben 30/17/20/13/15; das 600-Punkte-Zifferblatt, Clock-/Komplikationsgrafik, Farbe, Slotwerte und native Picker-Gestaltung bleiben unverändert.

| Größte/Normal-Höhe | iPhone | iPad |
|---|---:|---:|
| Faces-Titeltext | 2,81 | 2,81 |
| Anleitungstext | 2,91 | 2,89 |
| Complications-Abschnitt | 2,60 | 2,60 |
| Panel-Familientext im ersten Slot | 3,15 | 3,13 |
| Face-Control einschließlich Padding/Mindestfläche | 1,24 | 1,81 |

**Die ursprüngliche 1,3-fach-Controlbedingung auf dem iPhone bleibt gescheitert.** Das AX-Control enthält die native 44-Punkte-Untergrenze und ist keine reine Fontmessung. Nicht weiter aufgepolstert, um eine Kennzahl grün zu färben. Stattdessen separat deklarierte Schwarz-Kern-Masken bei RGB-Grenzen 32 und 64: exakter sichtbarer Modular-Controlausschnitt, mindestens 100 dunkle Pixel, mindestens zwei freie Pixel Rand; beide Masken zeigen vorher 1,00 und nachher rund 2,67–2,78 auf dem iPhone bzw. 2,70–2,73 auf dem iPad. Das sind reproduzierbare Glyphen-Tintenrechtecke dieses Literals, keine Fontkonturen oder allgemeine Fontmetrik. Die ursprünglichen neun grünen/eine rote Control-/Textbedingungen bleiben getrennt erhalten.

## Präsentationen und Grenzen

Zwei tatsächliche Picker-Öffnungen mit unverändertem Slotlabel nach jedem Done; keine Auswahl in der Normal-/XXXL-Inventur. Der synthetische Home-Wert bleibt 68°. Die nativen Texte sind hell; derselbe zuvor beobachtete Profil-Editor-Fehler mit dunkler Schrift auf dunklem Sheet wurde nicht reproduziert. Der heterogene Glas-Hintergrund qualifiziert die vorab festgelegte uniforme Kontrastmessung nicht. Deshalb kein Farbfix und kein pauschaler Kontrast-PASS. Der Off-Innenausschnitt wird aus dem Quellenpadding des kombinierten Controls abgeleitet, nicht als gemeldetes AX-Textrechteck ausgegeben.

## Gebundener Nachweis

**Zehn aktuelle UI-Ausführungen**, vier eindeutige Methoden: vier Normal-/XXXL-Inventuren und sechs vorhandene normale Auswahl-/Inline-/App-Umschalterregressionen. Fünf SDK-Builds/73 Produktdateien und sechs Tooling-Tests bestanden. Alle aktuellen UI-Ausführungen und SDKs binden denselben 233-Dateien-Quellstand `2c7b738…`; identische aktuelle kompilierte UI-Eingaben und installierte Appbytes geprüft. Keine Fehler, Skips oder strukturierten Runtime-Warnungen.

14 UI-Inputarchive und das SDK-Produktarchiv vollständig zurückgelesen. 96 native PNGs dekodiert, 16 Übersichten/zwei volle Einzelbilder sowie eine zusätzliche Übersicht aus acht abgeleiteten Chipausschnitten gesichtet; acht eigene PNGs bytegeprüft veröffentlicht. Gesamte UI-Historie: 18 Ausführungen, 14 bestanden und vier frühere Selektorfehler; nicht 18 aktuelle Fälle. Die separat gescheiterte Controlhöhen-Bedingung ist kein zusätzlicher fehlgeschlagener UI-Lauf. Schriftpräferenzen wieder `large`.

Vier normale Viewport-Bildpaare exakt RGBA-pixelgleich; nicht vier unterschiedliche Ansichten: Auf dem iPad sind Top-/Listenpose schon vorher dasselbe nicht gescrollte Bild. Vorher/Nachher-Testquelle unverändert. Eine Produktdatei geändert, 164 weitere Produkt-/Ressourceninputs unverändert; 89 Core-/Package-Eingaben bytegleich zum bisherigen 405-Test-Stand, kein neuer Core-Lauf.

[Einzelne Läufe, Fehlbefunde, Glyphenmasken, Bilder und Archive](verification/face-editor-dynamic-type.json) · [eigene Bilder](screenshots/face-editor-dynamic-type).

**#73 bleibt OPEN, F103 partial/parity=false.** Nur Default/größte Accessibility-Kategorie, zwei Simulatoren und dieser Modular-Ablauf. Tatsächliche Auswahl-/Inline- und App-Umschalteraktionen in separaten normalen Regressionen, keine XXL-Auswahl- oder echte Hilfsmittelabnahme daraus. Andere Face-Editor-Optionsschriften und schmale Fenster nicht pauschal freigegeben; keine universelle Kontrastabnahme. Kein echtes Home, Konto, Aufnahme, Ton, Anruf/Nachricht, neuer Systemalarm oder Live Activity. Geräte-/Signing-Pause unverändert. Der Gesamtauftrag geht weiter.
