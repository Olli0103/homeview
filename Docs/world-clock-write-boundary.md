# Weltuhr: Picker erst nach erfolgreichem Speichern schließen

20. Oktober 2026 · Teilfix von [#53 / DAY-07](https://github.com/Olli0103/homeview/issues/53) · [Ergebnisse und Quellenbindung](verification/world-clock-write-boundary.json)

## Reproduzierter Fehler

Ein eigener UUID-Teststore enthält absichtlich einen nicht unterstützten zukünftigen Snapshot `{"version":99}`. Die Anwendung erkennt ihn als schreibgeschützt. Der Test öffnet die Weltuhr, sucht Kathmandu, tippt die tatsächliche Auswahlzeile und schließt den erwarteten Speicherfehlerdialog.

Das Modell verweigert die Änderung und erhält die gespeicherten Daten bereits korrekt. Die Ansicht schließt jedoch unabhängig vom Ergebnis ihren Städte-Picker und leert die Suche. Derselbe neue UI-Fall scheitert vor der Korrektur auf iPad und iPhone exakt an „Rejected city save must retain its picker“. Bilder zeigen die zurückgekehrte Vier-Städte-Übersicht. Dies ist eine **Schreibschutz-Ablehnung**, kein neu injizierter Dateisystemfehler.

## Korrektur

`addWorldCity` gibt den bestehenden Speichererfolg von `updateLocalControls` zurück. Ungültige, doppelte oder überzählige Zonen liefern false. Die Auswahlansicht schließt und leert ihre Suche nur bei Erfolg. Bei Ablehnung bleiben Picker, Suchtext und auswählbare Stadt erhalten; der vorhandene Fehlerdialog bleibt der Fehlerweg. Bewusstes „Done“ schließt die Auswahl weiterhin ohne Hinzufügen.

Geändert sind nur diese beiden Produktstellen in AppModel.swift und Everyday.swift. Speicher-/Rollback-Algorithmus, Dateiformat, Migration, Zonen-/DST-/Datums-/Sonnenberechnung, Trefferflächen, Schrift und Layout bleiben unverändert. Der neue Test ist vor/nach der Produktkorrektur bytegleich. Keine neue allgemeine UI-Pixelgleichheit behauptet.

## Abschlussprüfung

- Neuer Fehlerfall je iPad/iPhone: Nach Ablehnung bleibt `Kathmandu` im Suchfeld und die Auswahlzeile vorhanden. Explizites Done schließt, die Übersicht enthält weiterhin vier Städte. Prozessneustart ohne Fixture-Flag liest denselben geschützten Store; Kathmandu bleibt hinzufügbar und wurde nicht gespeichert.
- Bestehender Erfolgsfall je Gerät: Kathmandu hinzufügen, korrekte Viertelstunden-Zonenzeit anzeigen, Prozess neu starten, Stadt entfernen und nach einem weiteren Neustart deren Entfernung bestätigen. Kein neues Genauigkeitsresultat der Sonnenberechnung.
- Vier finale UI-Ausführungen bestanden, keine Skips oder strukturierten XCTest-Runtime-Warnungen. Die zwei fehlgeschlagenen Vorherausführungen bleiben dokumentiert: insgesamt sechs Ausführungen, vier PASS und zwei frühere FAIL. Keine neuen Core- oder separaten nativen Modellläufe beansprucht.
- Fünf aktuelle SDK-Builds bestanden. Je Prüfstand 206 Quellen-/Test-/Ressourcen-/Projekt-/Scriptdateien und 28 kompilierte App-/Widget-/Test-/Metadaten-/Launch-Eingaben eingefroren; installierte Appbytes zurückgelesen. Zwei Archive mit je 234 Einträgen vollständig zurückgelesen.
- Die vier eigenen schreibgeschützten Dateien aus Vorher-/Nachherläufen sind exakt `{"version":99}`, SHA-256 `9a2f382f9e837c60ef6c2dcc8efeb1b0e2e37ce828e692deb08fb9b0d798d2d7`. Keine Änderung als Erfolg umgedeutet.
- 20 PNGs dekodiert, vier Übersichten und beide finalen Suchfeld-Viewports in voller Größe gesichtet. Zehn eigene Belegbilder veröffentlicht.

## Grenzen

#53 und F068 bleiben offen/partial, parity=false. Originalgeometrie, originaler Sonnenzeitverlauf, reale Hilfsmittel und physische Geräteabnahme sind hier nicht erledigt. Die erfolgreichen bisherigen Zeit-/Zonenfälle sind kein zusätzlicher pauschaler Parity-PASS.

Nur lokale synthetische Daten und eigene Simulator-Teststores. Keine persönlichen Accounts, Ortung, Mikrofon/Kamera, Audiowiedergabe, Systemalarme, neuen Live Activities, Änderungen von Systemzeit/-zone oder Systemberechtigungen. **Keine Home-Anbindung.**
