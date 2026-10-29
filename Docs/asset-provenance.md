# Aktuelle Asset-Provenienz und qualifizierte öffentliche Historie

Stand: 20. Oktober 2026 · [Issue #3](https://github.com/Olli0103/homeview/issues/3)

**29. Oktober:** [Getrennter lokaler Bereinigungskandidat](asset-history-cleanup-candidate.md) entfernt gezielt den bekannten historischen Icon-Blob bei exakt identischem aktuellem Dateibaum. Keine öffentliche Umschreibung oder vollständige historische Rechteabnahme.

## Gefundener Fehler

Das ältere App-Icon `icon-1024.png` war kein vollständig eigenständiges Projektbild: `Scripts/make_icon.swift` rasterisierte `NSImage(systemSymbolName:"house.fill")` in den selbst gezeichneten Hintergrund. Die generische Angabe „project-generated“ im historischen Assetindex unterschied diesen Systemsymbol-Anteil nicht. Der API-Aufruf überträgt keine Urheber-/Lizenzrechte am Systemsymbol auf das Projekt.

Das ist ein konkreter Herkunftsbefund, keine juristische Behauptung über die Zulässigkeit jeder früheren Nutzung. Die historischen Bytes bleiben in Git; sie werden weder neu als eigene MIT-Grafik ausgegeben noch stillschweigend umgeschrieben.

## Aktueller Ersatz

`icon-independent-v2.png` verwendet ausschließlich eigene primitive Pfade: Dreieck, gerundetes Hausrechteck, Tür/Fenster, bestehendes eigenes Raster und selbst gezeichnete Uhr. Kein Systembild, Font-Rendering oder Referenzbild als Generatorinput. Der neue Dateiname und die aktualisierte Assetkatalog-Referenz verhindern eine unbemerkte Gleichbenennung mit dem historischen Bild.

Der Generator erzeugt die neue PNG bei unabhängiger Wiederholung bytegleich. SHA-256: `a6c20b8da16e82972473ef3e2c1153eee048ccc42e1a1110148f19c72dee69fa`. Das vollständige 1024-Pixel-Bild und die tatsächlich kompilierten 120-/152-Pixel-Versionen wurden dekodiert und angesehen. Die kompilierten Versionen sind vollständig deckend; ein Launcher-/SpringBoard-Maskierungsnachweis wird daraus nicht gemacht.

## Zwei getrennte Manifeste

[asset-manifest.json](asset-manifest.json) bleibt unverändert der historische Erstveröffentlichungsindex. Seine Digests werden nicht rückwirkend auf neue Dateien umgeschrieben.

[asset-current-manifest.json](asset-current-manifest.json) erfasst jetzt alle 57 aktuellen Ressourcendateien mit Digest, Größe, Autor/Generator, erklärter Lizenz, Notice und Herkunftsbelegen.16 zugehörige Quellen/Notices sind zusätzlich gehasht. Bei KI-Fotos wird kein menschlicher Fotograf erfunden; Eigengeometrie, dokumentierte KI-Erzeugung, eigenes Alpha-Replay, Konfiguration, synthetischer Ton und FeedKits mitgelieferter MIT-Notice werden unterschieden. Das ist ein überprüfbares Deklarationsinventar, keine pauschale rechtliche Freigabe.

`python3 Scripts/check_asset_manifest.py` prüft den vollständigen Pfadsatz, Digests, notwendige Herkunftsfelder, zugehörige Quellbytes und tatsächliche Assetkatalog-Dateireferenzen. Zusätzliche oder fehlende Ressourcen und geänderte Bytes müssen bewusst im aktuellen Index behandelt werden. Der aktuelle Icongenerator darf keine Systembild-/Font-API zum Einbacken solcher Bilder verwenden. Der Checker behauptet keine historische Rechteentscheidung.

Alle 17 geometrischen Ersatzbilder lassen sich aus `prepare_assets.swift` bytegleich reproduzieren. Die sieben dokumentierten KI-/eigenen Alpha-Bilder stimmen mit ihren bestehenden Provenienzdateien überein. Alle 25 aktuellen PNGs wurden vollständig dekodiert. Das neue Icon ist der einzige ausgetauschte Rasterinhalt; App-/Core-/Shared- und Testquellen bleiben bytegleich zum vorherigen Stand.

Eigene Flow-/Foto-Zifferngeometrie und das prozedurale Demo-Cover bleiben unter ihrer bisherigen Projektdeklaration. Runtime-Systemschrift und SF Symbols werden dadurch nicht unter MIT neu lizenziert. [NOTICE.md](../NOTICE.md) qualifiziert den früher übergangenen historischen Icon-Anteil ausdrücklich.

## Öffentlicher Git-Verlauf: was tatsächlich geprüft wurde

Der einzige öffentliche Remote-Ref war bei der Prüfung `main` auf `65a42108b18be5dc5201e427ef1afb9ecc9b093f`; keine öffentlichen Tags/weiteren Branches. Dieser Stand ist die abgegrenzte Basis, nicht eine Behauptung über unbekannte künftige Commits.

| Eingelesener Umfang | Beobachtung |
| --- | --- |
| 371 erreichbare Commits|Ab dem bereinigten Erstcommit `cc95825`|
| 5.779 erreichbare Gitobjekte|Commit-/Tree-/Blobinventar erfasst|
| 3.731 Dateiobjekte|Alle 1.013.454.267 Bytes tatsächlich gelesen und gehasht|
|Geprüfte Fontsignaturen und Font-/Binär-/Archiv-Endungen|Kein Treffer; kein allgemeiner Autorschaftsnachweis|
| 36 einzigartige historische Ressourcen-Blobs|Darunter 25 Rasterbilder: 17 reproduzierte Geometrien, sieben dokumentierte KI/Alpha-Bilder, ein ausdrücklich gemischtes altes Icon|
| 1.717 historische Nicht-Ressourcenbilder| 1.716 Digests in bestehenden JSON-Belegen referenziert; eine zusätzliche Kalenderübersicht visuell geprüft und jetzt gebunden|

Raw-Git-Änderungen einschließlich früherer Namen/Löschungen wurden zusätzlich berücksichtigt; der erste von `rev-list` gelieferte Dateiname wird nicht als einziger historischer Pfad eines Blobs ausgegeben. Weder private Checkouts noch unerreichbare Gitobjekte wurden gelesen.

Die zusätzlich gesichtete Kalenderübersicht enthält 14 eigene synthetische Kalender-/Agendapanels mit den dokumentierten Datums-/Zonenszenarien. Das ersetzt keine Einzelprüfung aller historischen Bilder. Ein Digestverweis oder eine fehlende Fontsignatur allein beweist weder Rechtefreiheit noch unabhängige Entstehung jeder historischen Kontur.

[Vollständige Blob-/Pfad-/Digestliste](verification/asset-public-history-blobs.json) · [Historienumfang und Herkunftszuordnung](verification/asset-public-history.json).

## Build und frische Aufnahmen

Fünf SDK-Builds bestehen auf identischen 207 Produkt-/Test-/Skripteingaben. Die tatsächlich installierten iPad-/iPhone-Appbytes stimmen mit dem aktuellen iOS-Build überein. Zwei neue Ganzdisplay-Aufnahmen zeigen die eigene Mock-Oberfläche nach dem Austausch: iPad nach normalem Idle-Wechsel im Modular-Face, iPhone in Settings. Sie sind Beobachtungsaufnahmen, keine neuen XCTest-/Core-/nativen Modelltests oder Launcher-Icon-Abnahme. Keine Originalpixel-/Geräteparität behauptet.

Der direkte Capture-Service-Dateischreibzugriff auf die externe SSD wurde abgewiesen. Das CLI schrieb `-` entgegen seiner Hilfe als wörtlichen Dateinamen statt auf stdout. Die vorhandene eigene Aufnahme wurde gesichert; anschließend unterstützte kurze lokale Zwischenablage mit hashgeprüftem Transfer auf die externe SSD. Kein TCC-/Berechtigungs-/Konfigurationswechsel. Interne Bildquellen und temporäre Ablage sind nach Transfer entfernt. Dieser Aufnahmeweg ist kein App-Fehler.

[Quellen, Wiederholungen, Builds, installierte Bytes, Aufnahmen und Archiv](verification/asset-provenance.json). Das externe Archiv enthält 280 vollständig zurückgelesene Einträge. Alte gemischte Bild-/Generatorbytes liegen dort nur als private Prüfbelege; sie werden nicht erneut als aktuelle Projektassets publiziert.

## Offen

**#3 bleibt OPEN.** Das aktuelle App-Icon und die aktuellen Herkunftsangaben sind korrigiert. Die alte Systemsymbol-Rasterisierung bleibt ausdrücklich qualifiziert in der öffentlichen Historie; keine History-Umschreibung oder pauschale historische Rechtefreigabe. Nicht alle historischen Bilder oder Glyphenherleitungen sind einzeln visuell/urheberrechtlich abgenommen. Originalgetreue Typografie und weitere Motiv-/Parityfragen bleiben in ihren eigenen Issues offen.

Keine Home-Anbindung, Konten, Kamera-/Mikrofonaufnahme, echten Nachrichten/Anrufe oder physischen Systeminteraktionen.
