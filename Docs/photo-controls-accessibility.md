# Foto-/Album-Einstellungen: Systemschrift und Kontrast

30. Oktober 2026 · #73 und #11 bleiben offen; kein Original-/Geräte-/Hilfsmittel-PASS.

## Abgegrenztes Ergebnis

**18 aktuelle UI-Ausführungen, fünf SDK-Builds und sechs Tooling-Tests bestanden.** Zwölf Normal-/XXXL-Ausführungen prüfen die drei neuen funktionalen Inventuren, sechs bestehende Regressionen prüfen manuelle Position/Neustart/Reset, aktualisierte/leere synthetische Alben und gespeichertes Abschalten der Rotation.

Zehn lokale skalierende Fontmetriken in zwei vorhandenen Foto-/Layout-/Shared-Album-Dateien. Positionsbuttons werden ausschließlich bei Accessibility-Schrift untereinander angeordnet; bei normaler Schrift bleibt die HStack-Anordnung gewählt. Sekundäre Hinweise verwenden eine lokale, auf die tatsächlich weiße Settings-Fläche abgestimmte dunklere Farbe. Dekorative Foto-Uhr, Bilddaten, Provider, Import-/Verknüpfungs-/Resetregeln und persönliche Autorität unverändert. Der native Fotopicker wird in diesen Fällen nicht geöffnet.

| Tatsächliche Messung | Unveränderter Produkt-Vorherstand | Aktueller Stand |
|---|---|---|
| 26 native Textausdehnungsbedingungen | 24 wachsen nicht; 2 Rotationsbeschriftungen bereits grün | 26 wachsen; Ausdehnungsfaktoren 2,02–7,22 einschließlich Umbruch |
| 20 Ganzliteral-Kontrastbedingungen | 20 rot, selbst dunkelste Kernpixel nur 3,26–4,00:1 | 18 qualifiziert bei 7,00:1; 2 lange XXXL-Albumabsätze als Ganztext unqualifiziert |
| Vier schwarze Textkontrollen | 21:1 | 21:1 |
| Funktionale Normal-/XXXL-Matrix | 12 akzeptierte Ausführungen über zwei Testpins | 12 bestanden, ein eingefrorener Testpin |

Die zwei langen Absätze sind tatsächlich nur ausschnittsweise sichtbar und dürfen gescrollt werden; daraus wird weder simultane Ganztextlesbarkeit noch ein Ganztext-Kontrast-PASS gemacht. Die 22 Control-Zustände ohne isoliertes natives Textkind bleiben **keine** Fontmetriken. Ein gepolsterter Control-Rahmen ist kein Ersatz. Die bereits vorher wachsenden Rotationslabels werden nicht als neuer Fix ausgegeben.

[Quellen, Messwerte und getrennte Laufhistorie](verification/photo-controls-accessibility.json) · [Bildherkunft/SHA-256](verification/photo-controls-accessibility-images.json).

## Native Bedingungen und Rückkehr

Zwei iOS-27-Simulatoren: iPhone 18 Pro und iPad Air 11-inch (M4). Normal `large` und `accessibility-extra-extra-extra-large` werden per Simulator-Override gesetzt, vor/nach den Stufen gelesen und in jeder der sechs Schriftmatrizen im finally auf den ursprünglichen Wert `large` zurückgestellt: 18 Set-Aufrufe einschließlich Rückstellungen. Der gezielte Headerfall und die sechs bestehenden Regressionen verändern die Präferenz nicht. Existierende skalierende Settings-Überschrift als positive Textkontrolle. Kein realer OS-Settings-/Zoom-/VoiceOver-/physischer Schriftwechsel behauptet.

Drei neue Methoden in [HomeViewUITests.swift](../Tests/UITests/HomeViewUITests.swift):

- `testPhotoSettingsSystemTextSizeInventoryWithoutLibrary`: Galerie aus eigenen Demos, nativer Rotationsschalter, Entfernen; Bibliotheksbutton nur beobachten.
- `testPhotoLayoutSystemTextSizeInventoryKeepsAdjustAndReset`: Top/Bottom, nativer Framing-Schalter, beide Slider und Reset mit Rückkehr zur vollen automatischen Rahmung.
- `testSharedAlbumSystemTextSizeInventoryKeepsExplicitLinkAndDisconnect`: bewusste Gerätefreigabe im synthetischen Anbieter, richtige Album-IDs, ausdrückliches Verknüpfen, Update und Trennen ohne verbleibende Kopien.

Nur eigene Demo-Assets und Fixture-Alben/UUID-Speicher; keine echten Fotos, Konten, Homes, Mikrofone oder Nachrichten. Die erlaubte Ausschnittsprüfung langer scrollbarer Absätze ist getrennt von vollständigen kurzen Beschriftungen und unveränderten Callback-/Reset-/Disconnect-Erwartungen.

## Beibehaltene Instrumentfehler und Vorherbindung

Der veröffentlichte Produktstand `d5e12f204a85bbd71277ac14c3206592f0572a91` bleibt über alle 166 Produkt-/Resource-Inputs vor jeder Produktkorrektur identisch.

Erste zwölf UI-Ausführungen: 2 PASS / 10 FAIL. Vier Koordinaten-Mittelpunkttipps auf native Switch-AX-Zeilen lösen nicht den beabsichtigten Wertwechsel aus; tatsächliche Bilder zeigen den Knopf rechts und leere Mitte. Sechs frühe XXXL-Fälle erreichen den Fotoabschnitt nicht innerhalb des kurzen Scrollbudgets. Das sind fehlgeschlagene Eingaben/Beobachtungen, keine erfundenen Produktfehler.

Eine lokale, auf 72 Gutter-Drags begrenzte Scrollhilfe mit tatsächlichen Ziel-/Clipspuren und 40-Punkte-Abstand zu Rundungsecken sowie der native Switch-Tap qualifizieren denselben Produktstand. Exakte 0/1-, Auswahl-/Reset-/Import-/Disconnect-Anforderungen bleiben erhalten. Der neue Abstand wurde zunächst auch auf die nicht scrollende positive Settings-Überschrift angewandt: ein zusätzlicher Normal-iPhone-Instrumentfehler. Nur dieser Fall wird anschließend am unveränderten Produkt gezielt ergänzt; unbetroffene Fälle werden nicht erneut ausgeführt.

Akzeptierter Vorherumfang: elf gültige Ausführungen aus Testpin `48b0e9dd…` plus die gezielte Headerergänzung aus `931af59d…`. Der fehlgeschlagene zwölfte Fall im ersten Pin bleibt erhalten. Die finale UITestdatei ist bytegleich zur Headerergänzung; nur zwei Produktdateien ändern sich danach. Gesamte Vorherhistorie **25 Ausführungen / 14 PASS / 11 FAIL**, nicht eine grüne Vollsuite. Aktuell **18 PASS / 0 FAIL / 0 Skips**, zusammen 43 Ausführungen / 32 PASS / 11 historische FAIL – keine 43er-Erfolgssuite.

## Kontrast, Geometrie und normale Pixel

Kontrast nur aus tatsächlich geprüften Literal-ROIs auf beobachtetem Weiß, mindestens 100 tatsächliche Kernpixel, Grenze 4,5:1. Vier erste iPad-ROIs enthielten schwarze äußere Rundungsecken; ihre scheinbaren 20,262:1 bleiben unqualifiziert erhalten. Randfreie neue Aufnahmen belegen anschließend denselben echten grauen Textfehler auf beiden Geräten. Kein Maskieren der schwarzen Ecken oder Senken der Pixelzahl. Aktuelle normale ROIs und die gesonderte XXXL-Auswertung sind separate, unverändert erhaltene Messdateien.

Die notwendige Farbkorrektur wird nicht als normale Bildgleichheit ausgegeben. 50 normale Bildpaare werden in vollständigem dekodiertem RGBA ohne Toleranz, Registrierung oder Neuskalierung verglichen:

- Zwei unveränderte positive Settings-Kontrollansichten sind vollständig exakt gleich.
- Ein weiteres iPad-Pickerhinweis-Paar ist außerhalb seiner zuvor vermessenen exakten Literal-ROI vollständig gleich. Das ersetzt nicht den roten ursprünglichen Ganzbildvergleich; andere sichtbare geänderte Hinweise werden nicht still mitmaskiert.
- 29 Paare melden unterschiedliche Ziel-/Clipgeometrie und bleiben für Positionserhalt unqualifiziert. Ursache nicht allein aus dieser Differenz geklärt; keine nachträgliche Ausrichtung.
- 49 von 50 normalen Zielbreiten/-höhen exakt gleich. Die verbleibende Switchhöhe beträgt vorher 17,639984130859375, aktuell 17,6400146484375 (rund 0,00003 Punkte); nicht als exakt umetikettiert und kein Produkt-Padding-Fix aus dieser Präzisionsdifferenz erfunden.

Die Ausdehnungsfaktoren sind native Textmaße einschließlich Umbruch, nicht isolierte Fontfaktoren oder universelle Lesbarkeitszertifikate. Nicht alle Hinweise/Plattformzustände oder die separate Depth-Warnung sind damit einzeln als Textmetrik abgenommen.

## Quellen, Binaries und Archivabschluss

235 eingefrorene Quellen, Digest `9f1cddd5f1f7005beaa55cac897d4c69c6da403c4efe2642fc46982c59a3581c`; zwei Produktdateien geändert, 164 weitere Produkt-/Resource-Inputs unverändert. Alle 15 ausgeführten UI-Eingabearchive mit jeder enthaltenen Datei erneut bytegeprüft. Sechs aktuelle UI-Gruppen haben dieselben 19 Appdateien und fünf Runner-/Testdateien; tatsächliche installierte Apps vor/nach Lauf und Runner/Testbundles geprüft. 73 SDK-Produktdateien archiviert und zurückgelesen. 89 Core-/Package-/Core-Testinputs exakt zum historischen 405-Test-Stand `0c42086b41842877b1720f5776c44d1568ba1931`; **kein neuer Core-Lauf**.

**Paketgrenze:** Das aktuelle UI-Testpaket enthält 19 Appdateien; der frische vollständige Standard-iOS-SDK-Build 22. Im UI-Paket fehlen drei SSU/NLU-Metadateien (`root.ssu.yaml`, `nlu/nlu.lzfse`, `nlu/*.version`). Die Standard-SDK-Metadatengate besteht; diese Foto-/Schrift-UI-Läufe sind keine neue vollständige Shortcut-Paket-/Discovery-/Runtime-Abnahme. Kein Metadatenschritt deaktiviert und kein UI-/SDK-Binary gleichgesetzt.

506 native PNGs dekodiert. Tatsächlich gesichtet: 30 historische native Kontaktbögen, zwölf aktuelle eigene Viewport-Bögen, zwei aktuelle Regressionsbögen und fünf separate Kontrastbögen. Die 100 ganzen Bildschirmduplikate der vier aktuellen Schriftgruppen werden nicht zusätzlich als einzeln visuell geprüft ausgegeben; deren 100 eigene Viewports wurden geprüft. 14 unmodifizierte eigene native Viewport-PNGs veröffentlicht und bytegeprüft, darunter die zwei ausdrücklich nur ausschnittsweise sichtbaren XXXL-Albumhinweise. Rohlogs/Binaries bleiben privat; bekannte OS-/Debugger-/Remote-AX-Konsolendiagnostik ist erhalten, keine allgemeine Warnungsfreiheit behauptet.

## Eigene Belegbilder

| Gerät | Normaler Pickerhinweis vorher / aktuell | XXXL-Positionsauswahl vorher / aktuell | XXXL-Langabsatz ausdrücklich nur Ausschnitt |
|---|---|---|---|
| iPhone | [Vorher](verification/images/photo-controls-type-20261030/phone-normal-picker-policy-before.png) / [Aktuell](verification/images/photo-controls-type-20261030/phone-normal-picker-policy-current.png) | [Vorher](verification/images/photo-controls-type-20261030/phone-large-top-control-before.png) / [Aktuell](verification/images/photo-controls-type-20261030/phone-large-top-control-current.png) | [Kein Ganztextbeleg](verification/images/photo-controls-type-20261030/phone-large-long-notice-PARTIAL-VIEW.png) |
| iPad | [Vorher](verification/images/photo-controls-type-20261030/ipad-normal-picker-policy-before.png) / [Aktuell](verification/images/photo-controls-type-20261030/ipad-normal-picker-policy-current.png) | [Vorher](verification/images/photo-controls-type-20261030/ipad-large-top-control-before.png) / [Aktuell](verification/images/photo-controls-type-20261030/ipad-large-top-control-current.png) | [Kein Ganztextbeleg](verification/images/photo-controls-type-20261030/ipad-large-long-notice-PARTIAL-VIEW.png) |

Die Ansichten zeigen eigene Zustände, keinen Originalvergleich oder pauschal positionsgleiche Vorher-/Nachherbilder.

## Verbleibend

Keine vollständige Galerie-/Wechselregel-/PhotoKit-/Accessibility-/System-Parity. Die Native-PhotosPicker-iPhone-Tastaturebene aus [#67](https://github.com/Olli0103/homeview/issues/67) bleibt ausdrücklich offen. Home-Sperre, Geräte-/Signing-Pause und Snoopy-Rechteausschluss unverändert. Live-GitHub-Abgleich: 41 ursprüngliche Issues offen, 40 abgeschlossen, eines ausdrücklich ausgeschlossen; spätere Community-Issues nicht in diesen Nenner gezählt. Der Gesamtbacklog wird weiter bearbeitet.
