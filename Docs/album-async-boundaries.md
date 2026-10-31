# Fotoalben: verspätete Antworten und Widerruf

31. Oktober 2026 · Softwarepaket für [#11](https://github.com/Olli0103/homeview/issues/11).

## Korrigierte Grenzen

Ein wartender Einmalimport konnte die weiterhin gültige persönliche Sitzung
verwenden, obwohl inzwischen bewusst getrennt, ein anderes Foto gewählt oder
ein neuerer Import abgeschlossen worden war. Auch sein verspäteter Fehler
konnte noch eine überholte Meldung setzen. Die bisherige Sitzungsgeneration
schützte Authentifizierung und Sperren, nicht diese Auswahlwechsel.

Eine eigene Importgeneration bindet Erfolg und Fehler jetzt an die aktuelle
Auswahlabsicht. Erfolgreiche Einzel-/Galeriewahl, Albumverknüpfung und bewusstes
Trennen invalidieren ältere Importe. Ein fehlgeschlagener lokaler Auswahlwechsel
wird nicht als erfolgreicher neuer Zustand behandelt. Einmalimporte prüfen die
Fotos-Berechtigung außerdem vor dem Lesen und erneut vor der Übernahme.

Katalog und laufender Albumexport prüfen die aktuelle Berechtigung nach ihren
asynchronen Antworten ebenfalls selbst. Bei Widerruf werden keine zurückgekehrten
Albumnamen oder Fotos veröffentlicht. Laufende verknüpfte Kopien werden getrennt,
auch wenn statt eines Berechtigungsfehlers ein gewöhnlicher Abruffehler zurückkommt.
Ein fehlgeschlagener Speicher-Cleanup bleibt ausdrücklich sichtbar. Die bestehende
AppModel-Grenze blendet getrennte Kopien auch dann aus, wenn ihre dauerhafte
Löschung nicht gespeichert werden kann.

Der tatsächliche PhotoKit-Anbieter hatte bereits eigene Berechtigungsprüfungen.
Die neuen Sitzungsprüfungen sind eine zusätzliche Übernahmegrenze, **kein neuer
Nachweis eines echten PhotoKit-Lecks**. Die reproduzierten Auswahl-/Fehlerprobleme
betreffen das tatsächliche AppModel mit einem kontrolliert spät antwortenden
Ersatzanbieter.

## Nachweis

[Quellen, Ergebnisse und Grenzen](verification/album-async-boundaries-20261031.json).

- Dieselben sieben AppModel-Szenarien: vorher zwei PASS und fünf FAIL, nachher
  sieben PASS. Erfolgreicher normaler Import, Trennen, später Fehler nach Trennen,
  neue Einzelwahl, neuerer Import und Widerruf mit Erfolg/Fehler sind getrennt.
- 25 gezielte Coretests bestanden: 20 Album-Sitzungstests und fünf gespeicherte
  Album-/Fotometadatenfälle. Vorher scheiterten vier der 20 Sitzungstests mit
  insgesamt 25 Assertions; die vorhandenen Kontrollen blieben grün.
- Der native Prüftreiber kompiliert die tatsächlichen macOS-Appquellen. Nur die
  Albumanbieter-Fabrik und zwei ausschließlich externe Lesezugriffe auf den
  eigenen UUID-Teststore/dessen Galerie werden ersetzt/ergänzt. Keine Änderung
  von Plattformbedingungen. Eigene kleine synthetische Raster, keine echte
  Bibliothek, kein Foto-Picker und keine physische Authentifizierung.
- Eingefrorene Quellen, kompilierte Inputs und ausführbare Probe werden vor/nach
  den nativen Ausführungen verglichen. Gespeicherte Metadaten entsprechen in jedem
  Szenario dem tatsächlichen AppModel-Zustand.

Alle fünf SDK-Ziele bestanden; iOS erforderte den vorhandenen einzelnen
Standard-Clean-Recovery für vollständige Shortcut-Metadaten. Die übrigen SDKs
wurden danach gebaut. Alle 73 finalen Produktdateien und das Quellenarchiv
sind vollständig zurückgelesen.

UI, Ressourcen, Sonnen-/Galerie-Wechselregeln und Darstellung sind unverändert.
Es gibt keine neue Pixel-/Fokus-Mikroprobe oder vollständige UI-/Core-Regression.
Der anfängliche nicht kompilierte Probezugriff auf die private Galerie und die
früheren Fehlstände bleiben als solche erhalten.

**#11 bleibt OPEN.** Konkrete Original-Galerieauswahl/-Wechselregeln,
reale iCloud-/PhotoKit-Zustellung und physische Authentifizierung sind nicht
damit abgenommen. Geräte-/Signing-Pause und Home-Sperre bleiben bestehen.
