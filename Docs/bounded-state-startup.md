# Begrenztes Lesen eigener Zustandsdateien beim Start

20. Oktober 2026 · Teilkorrektur von [#80](https://github.com/Olli0103/homeview/issues/80). Keine vollständige Persistenz-/Plattformabnahme.

## Tatsächlicher Vorherbefund

Der App-Start las `mock-state.json` mit `Data(contentsOf:)`, während der spätere Demo-Plan-Read-back bereits einen begrenzten Descriptor-Reader verwendete. Die Größenprüfung des Decoders erfolgte erst nach dem Einlesen. Außerdem folgte der Start einem Blatt-Symlink; ein hängender Symlink wurde durch die vorgeschaltete Existenzprüfung als fehlender, frischer beschreibbarer Speicher behandelt.

Eine native Probe mit der tatsächlichen AppModel-Initialisierung reproduziert beide Linkfehler ausschließlich in eigenen UUID-Speichern und mit synthetischen Canary-Daten. Fünf Fälle wurden abgeschlossen: normale Datei, fehlende Datei, Symlink, hängender Symlink und FIFO. Dabei scheitern fünf von 28 Bedingungen in den zwei Linkfällen. **FIFO wurde schon vorher korrekt als read-only abgelehnt; ein behaupteter FIFO-Hänger wurde nicht bestätigt und wird nicht als Fix gezählt.**

Die erste Harness-Fassung kompilierte wegen vier fehlender Leerzeichen nicht, null ausgeführte Assertions. Im zweiten Lauf kehrte die Verzeichnis-Initialisierung zurück, anschließend scheiterte nur der Probe-Vergleich von URLs mit unterschiedlichem Directory-Hint. Dafür gibt es keine abgeschlossenen Assertions; die Oversize-Probe wurde in diesem abgebrochenen Lauf nicht begonnen. Diese Grenzen bleiben erhalten und werden nicht zu Produktfehlern umgedeutet.

## Gemeinsamer Reader

`LocalStateFileReader` übernimmt den bereits vorhandenen POSIX-/Foundation-Ansatz:

- nur Datei-URLs; Öffnen mit `O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC`;
- nur `ENOENT` bedeutet fehlende Datei und liefert `nil`;
- `fstat` muss eine reguläre Datei bestätigen;
- vor dem Lesen höchstens **32.000.000 Bytes** Dateigröße;
- Lesen vom selben offenen Descriptor, maximal Limit + 1; ein übergroßes Ergebnis wird abgelehnt;
- Schließen des Descriptors auch bei Fehlern.

App-Start, bestehender kanonischer Plan-Read-back und die Byte-Verifikation eigener Recovery-Kopien verwenden den Reader. Der Decoder teilt denselben Grenzwert. Vor dem Startlesen steht keine symlink-folgende Existenzprüfung mehr: Ein hängender Link ist kein frischer Speicher. Bei unsicherem Zustand bleibt die vorhandene read-only-Politik bestehen, statt Daten über den Link zu übernehmen oder zu überschreiben. Reguläre, fehlende und heilbar beschädigte normale Dateien behalten ihre bisherige Semantik.

## Prüfungen

| Lane | Beobachteter Umfang |
| --- | --- |
| Native AppModel-Gegenprüfung | sieben abgeschlossene Prozesse, 40 Bedingungen bestanden: regulär, fehlend, Link, hängender Link, FIFO, Verzeichnis und 128.000.001-Byte-Sparse-Datei; originale Knoten/Canaries unverändert, unsichere Zustände read-only und Schreiben abgewiesen |
| Core | vollständige 297 Tests, vier neue Reader-Fälle, null Fehler oder Skips; bytegenaues Lesen/Leerdatei/Abwesenheit, Verzeichnis/Links/Datei-URL-Regel, exakt 32 MB und +1 Byte, große Sparse-Datei |
| Unabhängige Descriptor-Probe | tatsächlicher Produktionsreader: nach dem realen `fstat` wird der Pfad ersetzt oder die offene Datei vergrößert. Original-Descriptor liefert Originalbytes statt der Ersatz-Canary; Wachstum über das Limit wird abgelehnt. Sieben finale Bedingungen bestanden |
| UI | vier bestehende Ausführungen auf iPad/iPhone: beschädigtes Rezeptfeld erhält gesunden Mockzustand und spätere Writes über Neustart; künftige Speicherversion bleibt read-only und ein abgewiesener Write verändert den Mockwert nicht |
| SDKs | fünf abschließende Builds bestanden; der erste Watch-Build deckte die fehlende Reader-Datei in seiner separaten Quellliste auf und bleibt dokumentiert |

Die unabhängige Descriptor-Probe hat eigene Vorbereitungshistorie: Ein früher Interposer-Child endete mit Signal 11 vor einem JSON-Ergebnis, Ursache nicht festgestellt. Die nächste Fassung führte beide Mutationen aus, scheiterte aber an zwei falschen Marker-Erwartungen „16 Bytes“ statt der tatsächlich 17 Byte langen Seed-Daten. Erst die korrigierte, weiterhin exakte Seed-Längenprüfung besteht. Weder der Crash noch diese Markerfehler werden als Produktionsreaderfehler oder als bestandene Vorläufe gezählt.

## Quellenbindung

Core, native AppModel-/Descriptor- und UI-Prüfung liefen am Swift-Code `6c69a68`. Danach änderte `0cfb078` **nur** Projektgenerator und generierte Projektdatei, um den Reader auch dem reduzierten Watch-Target zuzuordnen. Sämtliche Swift-, Test-, Ressourcen- und Package-Eingaben bleiben bytegleich; die Sources-Buildphase der Main-App ist zusätzlich identisch. Die fünf abschließenden SDK-Builds sind an den korrigierten Stand gebunden. Frühere Core-/UI-Ergebnisse werden nicht als neue Ausführungen ausgegeben.

200 Eingaben je neuem Checkpoint, native Ausführungseingaben, 28 kompilierte App-/Widget-/Test-/Metadaten-/Launch-Eingaben und installierte Appbytes sind dokumentiert. Acht PNGs dekodiert, zwei Übersichten gesichtet; sechs eigene Bilder im [Prüfbericht](verification/bounded-state-startup.json). Archivierte Eingaben einschließlich fehlgeschlagener Vorbereitungen wurden vollständig zurückgelesen. Keine Rohlogs oder SDK-Header veröffentlicht.

## Grenzen

Das ist kein universeller Schutz gegen umgebogene Vorfahrenverzeichnisse, beliebige bösartige parallele In-place-Schreiber oder atomare Dateisystem-Snapshots. Der Byte-Grenzwert ist weder eine Gesamtprozess-Speichergrenze noch eine garantierte Laufzeit für beliebige reguläre Dateien oder Netzwerk-I/O. Die lokalen App-Writes behalten ihre bestehende atomare Schreibweise. Keine Rollback- oder Exactly-once-Zusage für externe Effekte.

#80 bleibt für die übrige Migrations-/Offline-/Provider-/Alarmoperationsmatrix offen. Keine echten persönlichen Daten, Konten, Kamera-/Mikrofonaufnahme, Systemalarme oder neuen System-Live-Activities verwendet. Die Thermostat-Bilder und Änderungen sind **MockHome**. **Keine Home-Anbindung.**
