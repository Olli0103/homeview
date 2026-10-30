# Mock-Schloss: aktuelle Beobachtung vor jeder Bestätigung

30. Oktober 2026 · [#25](https://github.com/Olli0103/homeview/issues/25).

## Reproduktion

Nach der Geräte-/Szenenkorrektur wurde der separate `MockLockDevice` geprüft.
Sein `readNow()` las noch `model.data.home` statt den aktuellen gespeicherten
Mock-Stand. Dadurch konnten Lesen, Bestätigungsvorprüfung und Read-back gemeinsam
denselben alten Cache für richtig halten.

Die tatsächliche native AppModel-/LockActionSession-Probe verletzt vorher
**12 von 20 Bedingungen**: fremde Nachbarwerte/Audit gehen verloren, eine nach der
Vorschau fremd geänderte Schlossbeobachtung verwirft die alte Bestätigung nicht,
offline/beschädigte Speicherstände werden ersetzt, und eine neue Vorschau bietet
die falsche Richtung an. Der Vorherfehler bleibt mit Quelle und Binärdigest erhalten.

## Korrektur

Nur `MockLockDevice.swift` ist geändert. Lesen verwendet den vorhandenen begrenzten
Saved-State-Reader. Senden liest einen aktuellen Mock-Home-Snapshot, prüft genau
dessen Schlossbeobachtung gegen die erwartete und verändert denselben Snapshot.
Unbeteiligte aktuelle Werte und der bisherige Auditverlauf bleiben erhalten.

Geräteauthentifizierung, separate Einmalbestätigung, 30-Sekunden-Lebensdauer,
Widerruf, Kontext-/Epochenschutz und Commit-Phasengate bleiben unverändert.
Kein Cache-Fallback bei einem nicht lesbaren Stand; keine automatische Wiederholung.

## Gezielte Abnahme

[Unveränderte native Probe](../Tests/NativeProbes/MockLockPersistentObservation.swift) ·
[Quellen, Digests und Resultate](verification/mock-lock-current-observation-20261030.json).

Die **gleichen 20 nativen Bedingungen bestehen nachher vollständig**. Tatsächlicher
AppModel/LockActionSession/Adapter in einer macOS-Konsolen-App; nur privater
Store-Getter an externer bytegleicher AppModel-Kopie, keine ersetzte Produktmethode.
Eigenes neues synthetisches UUID-Verzeichnis je Lauf. Fixture-Authentifizierung,
keine biometrische/physische Authentifizierung oder echte Schlossbedienung.

Fünf SDKs auf denselben 244 Quelleingaben bestanden. Alle 73 App-/Widget-Ausgaben
bytegenau zurückgelesen; nur fünf geänderte Dateien als 26.411.925-Byte-Delta
gesichert, unveränderte Dateien gegen das bereits versiegelte SDK-Archiv geprüft.
Ein gemeinsames DerivedData-Verzeichnis, keine neuen Cache-Verzeichnisse pro Fall.
Der erste erfolgreiche iOS-Compilerlauf hatte unvollständige Shortcut-SSU-Dateien;
eine standardmäßige Clean-/Build-Erholung stellte sie wieder her. Beide Versuche
bleiben getrennt, keine neue Shortcut-OS-Aufrufabnahme.

## Aktuelle mobile Gegenprüfung

Sechs erfolgreiche UI-Ausführungen, drei unveränderte Methoden auf iPhone/iPad:
Bestätigung/Read-back und Neustart ohne gespeicherten Grant, echter Simulator-
Hintergrundwechsel ohne gültige Bestätigung sowie Unknown/Jammed/Batteriefehler.
Null Fehler/Skips/strukturierte Runtimewarnungen. Installierte App-/Runner-/Testbytes
und unveränderte Source-/Launchinputs je Gerät geprüft; eine gemeinsame eingefrorene
UI-Eingabesicherung für beide Geräte statt duplizierter Archive. Auch die tatsächliche
UI-App enthält vollständige Shortcut-Metadaten; kein neuer OS-Shortcut-Aufruf.

[Zwölf eigene aktuelle Viewports](screenshots/mock-lock-current-20261030/) wurden
dekodiert und tatsächlich gesichtet. Die iPhone-Batteriezeile ist in diesen initialen
Scrollposen teilweise abgeschnitten; kein Ganztext-Lese-/Accessibility-PASS daraus.
Scrollbare Detailansicht und Layout sind unverändert, weitere Leseabnahme bleibt #73.

## Unveränderte Grenzen

Kein HomeKit, Haushalt-/Partnergeräte-Binding, echtes Schloss oder allgemeines
atomares Mehrprozess-Storeprotokoll. Keine neuen Coretests und keine Umdeutung
früherer Prüfungen zur neuen Gesamtsuite. Die 275 Geräte-/Szenenbedingungen sind
der getrennte [vorige Prüfstand](mock-home-neighbour-preservation.md), nicht 275
neue Schlossbedingungen. Geräte-/Signing-Pause und Home-Sperre bleiben bestehen.
Diese Regression ist keine zusätzliche Issue-Schließung oder Original-Parity.
