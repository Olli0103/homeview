# Face-Editor: zwei sekundäre Textrollen kontrastiert

29. Oktober 2026 · Teilumfang von [#73](https://github.com/Olli0103/homeview/issues/73), keine universelle Kontrast-/Hilfsmittelabnahme.

## Befund und lokale Korrektur

Die vier bereits veröffentlichten Normal-/XXXL-Inventuren aus `5cc9aaf` werden mit ihren exakten Quellen-, Binär-, Archiv- und Bildbelegen wiederverwendet. **Das sind keine vier neuen UI-Ausführungen.** Auf der weißen Root-Ansicht erreichen Anleitung und Slotfamilie selbst mit der dunkelsten tatsächlich gemessenen Glyphenfarbe höchstens 4,004:1 bzw. 3,917:1. Alle acht eigenen 4,5:1-Bedingungen scheitern; vier schwarze Abschnittstexte bestehen als positive Gegenkontrollen bei 21:1. Die größte Kategorie wird mit derselben konservativen Grenze geprüft, nicht pauschal als WCAG-Kleinschrift eingestuft.

Nur zwei lokale `foregroundStyle`-Werte in `FaceEditor.swift` ändern sich von `secondary` zu Schwarz mit 0,65 Deckkraft. Schriftgrößen, Layoutwerte, Zifferblatt-/Komplikationsgrafik, Auswahlwerte und native Picker-Gestaltung bleiben unverändert.

| Eigene Kernpixel-Kontrastmessung | Vorher | Nachher |
|---|---:|---:|
| Anleitung, beide Geräte/Größen | 4,00 | 7,00 |
| Panel-Familie, normales iPhone | 3,86 | 6,69 |
| Panel-Familie, normales iPad | 3,71 | 6,19 |
| Panel-Familie, XXXL beider Geräte | 3,92 | 6,79 |
| Positive schwarze Abschnittstexte | 21,00 | 21,00 |

Messung in sRGB mit relativer Luminanz: Textrechteck um zwei native Punkte erweitert, Zwei-Punkte-Hintergrundring; benachbarte bekannte Textrechtecke mit einem Punkt Abstand aus ROI/Ring ausgeschlossen. Alle Hintergründe hier tatsächlich 100% uniform. Die erste exakte RGB-Häufigkeitsmethode hatte bei der kleinen transformierten Familie nur 88/59 gleichfarbige Kernpixel und war dafür unqualifiziert; sie bleibt erhalten. **Vor der Produktänderung** wurde zusätzlich die untere Kontrastgrenze der mindestens 100 dunkelsten tatsächlichen Vordergrundpixel deklariert. Kein Absenken der Pixelzahl. Alle acht Nachherbedingungen qualifizieren und bestehen. Das misst diesen gerenderten Glyphenkern, nicht jeden Antialias-Rand oder ein physisches Display.

## Pixel und unterschiedliche Scrollpose

Sieben positionsgleiche Root-Bildpaare haben **null geänderte Pixel außerhalb der Anleitung-/Familienrechtecke**, einschließlich aller normalen Paare. Die Masken belegen nur etwa 1,3–9,9% der Bildfläche; gemessene andere Texte, Container und sichtbare Face-Grafik bleiben dort erhalten.

Das achte Paar – XXXL-iPad-Listenpose – ist **nicht pixelqualifiziert**: Alle 15 Scroll-Textknoten sind gleichmäßig 4,6433 native Punkte versetzt, Header/Footer stehen fest; Breiten, Höhen und relative Geometrie bleiben gleich. Der ursprüngliche direkte Vergleich scheiterte. Seine 152.593 geänderten Pixel außerhalb der Textmasken bleiben ausgewiesen; kein registrierter/ausgerichteter Pixel-PASS und kein Produktumbau wegen unterschiedlicher Capture-Scrollposition. Die Kontrast-ROI dieses tatsächlich sichtbaren Textes ist unabhängig davon qualifiziert.

## Aktueller Nachweis

**Sechs frische UI-Ausführungen**, zwei eindeutige Methoden: vier Normal-/XXXL-Inventuren und zwei vorhandene echte OS-App-Umschalterprüfungen. Zweimaliges Öffnen/Done erhält den Slot; Demo-Home bleibt 68°. Native Weltuhr-, Picker- und Artwork-Sheets sind im Umschalter geschützt und kehren zurück; kein Ton gestartet.

Fünf SDK-Builds/73 Produktdateien und sechs Tooling-Tests bestanden. Sämtliche aktuellen UI-/SDK-Ausführungen binden denselben 233-Dateien-Quellstand `943a6a7…`, identische aktuelle kompilierte UI-Eingaben und installierte Appbytes. Keine Fehler, Skips oder strukturierten Runtime-Warnungen. UITestquelle unverändert; eine Produktdatei geändert, 164 weitere Produktinputs und 89 Core-/Package-Eingaben bytegleich, kein neuer Core-Lauf (bisheriger Stand 405).

Zehn UI-Archive zurückgelesen: **sechs neue plus vier wiederverwendete**; SDK-Produktarchiv ebenfalls geprüft. 48 neue native PNGs und 24 wiederverwendete Bilder dekodiert; sechs neue native Übersichten, zwei abgeleitete Farbübersichten und zwei volle normale Root-Bilder gesichtet. Vier frühere native Übersichtsprüfungen sind als wiederverwendet gekennzeichnet. Acht eigene Vorher-/Nachher-PNGs bytegeprüft veröffentlicht. Schriftpräferenzen wieder `large`.

[Messungen, Quellen, einzelne Läufe und Archive](verification/face-editor-root-contrast.json) · [eigene Bilder](screenshots/face-editor-root-contrast).

## Issue-Verlauf und verbleibende Grenzen

Die lange Issue-Beschreibung näherte sich dem GitHub-Limit. Der vollständige alte Text mit **62.468 Zeichen** ist [unverändert archiviert](verification/issue73-body-before-root-contrast-20261029.md), [mit SHA-256 belegt](verification/issue73-body-archive-20261029.json). Die ursprünglichen 2.541 Zeichen mit Ziel, Stand, Referenzumfang, konkreter Arbeit, Abnahme und Testgrenze bleiben im aktuellen Issue **verbatim** erhalten. Nur die ausführlichen Fortschrittsabschnitte werden durch verlinkte Nachweise ersetzt; kein Kriterium entfernt oder als erfüllt umgedeutet.

**#73 bleibt OPEN, F103 partial/parity=false.** Zwei benannte Rollen, zwei Simulatoren, Default/größte Kategorie. Keine Abnahme heterogenen nativen Glases, anderer Varianten/Optionsschriften, Sprachen oder echter Hilfsmittel. Keine echten Konten, Home, Aufnahme, Ton, Anrufe/Nachrichten, neuen Systemalarme oder Live Activities; Geräte-/Signing-Pause unverändert. Der Gesamtauftrag wird fortgesetzt.
