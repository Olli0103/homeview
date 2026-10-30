# Mock-Geräte und Szenen: fremde Nachbarzustände erhalten

30. Oktober 2026 · [#24](https://github.com/Olli0103/homeview/issues/24),
[#26](https://github.com/Olli0103/homeview/issues/26).

## Tatsächlich reproduzierter Fehler

Ein frischer Read-back des Zielwerts genügte nicht: `MockHomeDevice` prüfte den
gespeicherten Zielwert, baute die Änderung anschließend aber aus
`model.data.home`. Änderungen an anderen Mock-Geräten, Schlosszustand und
Auditverlauf wurden dadurch still durch den alten Cache ersetzt. Die anschließende
Prüfung bestätigte diesen bereits falschen neuen Gesamtstand.

Normale Mock-Szenen benutzten ebenfalls den Cache. Sie konnten damit nicht nur
fremde Nachbarwerte überschreiben, sondern auch einen inzwischen offline
gesetzten oder beschädigten gespeicherten Stand ersetzen und Erfolg melden.

## Korrektur

- Einzelbefehle lesen **einen aktuellen Mock-Home-Snapshot**, prüfen dessen
  Zielwert und aktuelle Metadaten gegen die erwartete Beobachtung und ändern nur
  die verlangte Eigenschaft auf dieser Grundlage. Der bisherige Read-back bleibt.
- Szenen lesen vor der lokalen Transaktion ebenfalls den aktuellen Stand.
  Schreibrechte werden nur für tatsächlich von der Szene geänderte Eigenschaften
  geprüft. Unbeteiligte Werte und vorhandene Auditdaten bleiben erhalten.
- Offline oder nicht lesbar bedeutet keinen Szenen-Schreibversuch. Es gibt keinen
  Cache-Fallback, keine automatische Wiederholung und keinen HomeKit-Aufruf.

## Gleiche native Gegenprüfung

[Probequelle](../Tests/NativeProbes/MockHomeNeighbourPreservation.swift) ·
[Quellen, Digests und Resultate](verification/mock-home-neighbour-preservation-20261030.json).

Der tatsächliche `AppModel`, `HomeDeviceSession` und `MockHomeDevice` laufen in
einem nativen macOS-Prozess. Nur ein privater Store-URL-Getter wird an eine externe
bytegleiche AppModel-Kopie angehängt; keine Produktmethode wird ersetzt. Neuer
eigener synthetischer UUID-Store je Lauf, keine normalen Benutzerdaten.

| Gleiche 275 Bedingungen | Vorher | Korrektur |
|---|---:|---:|
| Erfüllt | 79 | 275 |
| Verletzt | 196 | 0 |

56 Ziel-/Nachbarpaare über acht Eigenschaften, acht weiterhin abgewiesene fremde
Änderungen am Ziel selbst, vier normale Szenen mit aktuellen/fremd-offline/
beschädigten Zuständen sowie frisches AppModel-Lesen ohne Wiederholung. Die
Probequelle ist vorher/nachher exakt gleich. Nur zwei Produktdateien unterscheiden
sich; beide ausgeführten Binärdateien bleiben mit ihren Digests erhalten.

Fünf aktuelle SDK-Builds auf denselben 243 Quelleingaben bestanden; alle 73
App-/Widget-Ausgaben in einem einzigen Archiv bytegenau zurückgelesen. Ein
gemeinsames DerivedData-Verzeichnis mit 16-GiB-Platzprüfung, keine neuen
Compiler-Caches pro Bericht/Gerät.

Das ist ein gezielter nativer Modell-/Persistenznachweis, kein XCTest-/UI-/
VoiceOver- oder Geräte-PASS. Keine neue Core-Ausführung; Corequellen unverändert.
Es ist kein allgemeines atomisches Mehrprozess-Storeprotokoll und kein neuer
Schlossadapter-Nachweis. HomeKit, reale Szenen, heterogene echte Gerätezeiten,
Teilfehlertransport und die belegte Original-Routinenoberfläche bleiben bei #26
offen. Geräte-/Signing-Hold und Home-Sperre bleiben bestehen; kein Issue wird allein
wegen dieser zusätzlichen Regression geschlossen.
