# Timer-Einrichtung: Systemschrift ohne geänderte Normalansicht

29. Oktober 2026 · [#73](https://github.com/Olli0103/homeview/issues/73). Ergänzt die [skalierende laufende/pausierte Timer-Ansicht](timer-dynamic-type.md). **Begrenzte Simulatorprüfung, keine vollständige F103-/Hilfsmittel- oder Original-Parity.**

## Vorherstand und Gegenkontrolle

Titel, Dauer und Start-Control der leeren Timer-Einrichtung blieben auf iPhone/iPad trotz größter Accessibility-Systemschrift praktisch **1,00-fach** hoch. Sechs vorab definierte Vergrößerungsbedingungen von mindestens 1,25 wurden nicht erfüllt, obwohl der semantische Kontrolltitel des Vorleseeinstellungsblatts etwa fünfmal in der Höhe wuchs. Die 16 Vorher-UI-Ausführungen selbst bestanden; Messvergleichsfehler sind keine erfundenen zusätzlichen fehlgeschlagenen UI-Methoden.

Die acht nativen Start-Randaktionen waren **bereits vorher grün**: zwei gegenüberliegende Punkte, jeweils zwei Punkte innerhalb eines um das Control zentrierten nativen 44×44-Punkte-Quadrats, je Gerät und Schriftkategorie. Auch beim iPhone mit gemeldeter AX-Höhe von nur **37,38 Punkten** funktionierten die außerhalb dieser gemeldeten Höhe liegenden Taps: 15-Minuten-Timer startet, wird pausiert, Wert bleibt im erwarteten Bereich und Löschen führt zurück zur Einrichtung. Die kleinere AX-Höhe wurde deshalb nicht allein zum Anlass einer Trefferflächen-/Layoutänderung genommen. Sie bleibt eine getrennte AX-Geometriebeobachtung; zwei Randpunkte beweisen weder eine lückenlose Flächenkarte noch Voice-Control-Zielbarkeit.

## Korrektur

`AppHeader` und `Pill` erhalten nur **optionale Schriftgrößen mit unveränderten Defaults** von 23/22 beziehungsweise 21 Punkten. Die Timer-Einrichtung übergibt lokal skalierende Größen für Titel/Zeit, Dauer und Start. Andere Aufrufer behalten ihre Defaults.

Bei Accessibility-Größen nutzt die Einrichtung eine vertikal scrollbar angeordnete Darstellung: eigener Header, Dauer, explizite Minus-/Plus-Controls, Start und zweispaltige Presets. Kein künstlicher Font-Cap oder Ersatz kleiner Texte. Texte/Controls werden innerhalb desselben 16-Punkte-Innenclips einzeln erreicht; nicht alle Inhalte müssen gleichzeitig sichtbar sein. Die normale Anordnung bleibt unverändert.

| Größte/Normal-Rechteckhöhe | iPhone | iPad |
|---|---:|---:|
| Titeltext | 2,80 | 2,84 |
| Dauertext | 1,71 | 1,71 |
| Start-Control einschließlich Padding | 1,77 | 1,76 |

Das sind native Text-/Controlrechtecke, keine isolierten Glyphen- oder reinen Fontfaktoren. Der mitskalierende Header-Zeittext ist keine zusätzliche eigene Vergrößerungszelle dieser Tabelle. Minus/Plus ändern 15→14→15 Minuten; der tatsächliche 5-Minuten-Preset setzt den Wert, ohne schon einen Timer zu starten. Die unveränderten acht Start-Randfälle bestehen auch danach mit echtem Start-/Pause-/Lösch-Read-back.

## Aktueller Nachweis

**20 aktuelle UI-Ausführungen**, sechs eindeutige Methoden: 16 Normal-/XXXL-Matrixfälle und vier vorhandene normale Rezept-/Timerregressionen. Keine Fehler, Skips oder strukturierten Runtime-Warnungen. Die UITestquelle bleibt während Vorher/Nachher unverändert; alle aktuellen UI-Ausführungen und fünf SDKs binden denselben 233-Dateien-Quellstand `3f0db1c…` und identische aktuelle kompilierte UI-Eingaben. Installierte Appbytes jeweils geprüft.

- **Sechs normale Aufnahmen exakt RGBA-pixelgleich**, null geänderte Kanäle: dieselbe leere Einrichtung aus drei unabhängigen Fällen auf zwei Geräten, nicht sechs unterschiedliche Produktansichten. Die drei Vorheraufnahmen je Gerät sind untereinander ebenfalls exakt gleich.
- Zwei zusätzliche normale Countdown-Aufnahmen aus der Regression stimmen exakt mit dem bereits veröffentlichten `8601338` überein. Die Rezeptprüfung durchläuft unveränderte gemeinsame Header-/Pill-Defaults, Zutaten, Kochen und lokalen Timer; keine pauschale Pixelabnahme aller anderen Apps.
- Zwei Produktdateien geändert, **163 weitere Produkt-/Ressourceninputs unverändert**. 89 Core-/Package-/Coretest-Eingaben bytegleich zum bisherigen 405-Test-Stand; kein neuer Core-Lauf.
- Fünf SDK-Builds mit 73 Produktdateien und sechs Tooling-Tests bestanden. Zehn UI-Inputarchive sowie das SDK-Produktarchiv vollständig zurückgelesen. Sämtliche Schriftpräferenzen wieder `large`.
- 100 PNGs dekodiert, zwölf Übersichten und zwei volle Einzelbilder gesichtet; sechs eigene Vorher-/Nachher-PNGs bytegeprüft veröffentlicht. Gesamte UI-Historie dieses Pakets: **36 erfolgreiche Ausführungen**, davon 16 Vorherfälle und 20 aktuelle; nicht 36 aktuelle Fälle.

[Quellen, einzelne Läufe, Größen-/Pixelvergleiche, Archive und Bilder](verification/timer-setup-dynamic-type.json) · [eigene synthetische Bilder](screenshots/timer-setup-dynamic-type).

**#73 bleibt OPEN, F103 partial/parity=false.** Nur Default und größte Accessibility-Kategorie, diese zwei Geräte und der benannte Ablauf geprüft. Keine vollständige Preset-/Dauergrenzen-/Sprach-/Zwischenkategorien-Abnahme, keine echte VoiceOver-/Zoom-/Voice-Control-/Switch-Control-/AssistiveTouch-Sitzung und keine universelle gemeinsame Komponenten-Parity. Keine echten Konten, Home, Aufnahme, Tonwiedergabe, neuen Systemalarme oder Live Activities. Physische/Signing-Pause unverändert; weitere zentrale Flows werden fortgesetzt.
