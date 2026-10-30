# Typisierte lokale Gerätesteuerung

30. Oktober 2026 · [#24 / HOME-02](https://github.com/Olli0103/homeview/issues/24) · Produktcode `0619708`. **Ursprünglicher synthetischer Gerätevertrag erfüllt; keine reale Home-/Original-/Hardwareabnahme.**

[Gebundener Bericht](verification/mock-device-contract.json) · [242 Quelleingaben](verification/mock-device-contract-sources.json) · [17 eigene Aufnahmen mit Capture-Pins](verification/mock-device-contract-images.json).

## Ursprünglicher Umfang

Die originale Abnahme fordert synthetische Geräte mit Erfolg, Timeout, Ablehnung und asynchroner Fremdänderung. Die spätere reale Testheim-Abnahme ist ausdrücklich separat. Die vier Aufgaben verlangen Charakteristik-/Einheiten-/Grenz-/Schritt-/Rechtevertrag, Pending/Fehler/Fremdänderungen, Erfolg erst nach passendem Rücklesen und einzelne Abnahme von Thermostatmodus, Lichthelligkeit, Lüfter und Beschattung.

Kein HomeKit-Manager, kein echtes Haus oder Gerät, keine Berechtigungsanfrage. Der Konstruktor von NativeHomeKitService wirft weiterhin für alle Argumente realHomeDisabled. Der neue Provider ist ausschließlich der bereits vorhandene lokale MockHome; reale Einrichtung bleibt #23 und physische/signierte Freigabe bleibt pausiert. Die Konstruktion einer .homeKit-Quellenmarkierung im Core ist keine Erlaubnis: diese Revision nimmt ausschließlich .mock an.

## Vertrag

| Eigener Mock-Wert | Typ und Einheit | Bewusst zugewiesene Mock-Fähigkeit |
|---|---|---|
| Solltemperatur | endliche Zahl, Fahrenheit | 50–90, Schritt 1 |
| Thermostatmodus | geschlossener Moduswert | Off / Heat / Cool / Auto |
| Entryway / Bedroom / Fan power | Bool | einzelne les-/schreibbare Charakteristiken |
| Helligkeit / Lüftergeschwindigkeit / Zielposition | endliche Zahl, Prozent | 0–100; kein erfundener Hardware-Schritt |

Feste Accessory-/Characteristic-UUIDs identifizieren fünf eigene Mock-Geräte und acht unabhängige Charakteristiken. Deren Fähigkeiten sind keine Entdeckung realer Geräte. Fehlende Metadaten, unbekannter Modus, falscher Typ/Einheit, NaN/Unendlich, ungültige Grenzen oder Schritte werden nicht in einen plausibel wirkenden Befehl umgedeutet. Celsius/Fahrenheit-Konversion ist explizit getestet, aber kein neuer Celsius-Geräteanschluss behauptet. Bool-Ziele sind explizit; der Adapter prüft den erwarteten Zustand unmittelbar vor dem lokalen Commit nochmals.

Ältere gespeicherte MockHome-Werte ohne thermostatMode behalten den bisherigen Cool-Standard. Ein unbekannter vorhandener Modus wird nicht stillschweigend Cool. Neue Modi persistieren unabhängig vom Sollwert.

## Ablauf

Observed → Checking → Writing → Verifying → Confirmed. Ein erfolgreicher Write-Callback allein bestätigt keine Wirkung. Frische Werte und Deskriptoren müssen zur aktuellen Charakteristik passen; das ausdrückliche Rücklesen muss den gewünschten Wert und unveränderten Vertrag liefern. Fremdbeobachtungen sind sichtbar, bestätigen aber nicht den eigenen Schreibauftrag. Versions-/Owner-Tickets verhindern Rückrollen durch verspätete Reads und Callback-Replays.

Zehn Sekunden monotones Operationsbudget: Vor Dispatch abgelaufen bedeutet null gesendete Befehle. Nach Dispatch kann der Ausgang ungewiss sein; kein falsches „nichts gesendet“, keine automatische Wiederholung und kein zweiter Auftrag auf derselben Charakteristik, solange der alte Schreib-Callback unaufgelöst ist. Andere Geräte bleiben unabhängig. Hintergrund/Ende widerruft laufende Sitzungen; alte Callbacks können keine neue Sitzung bestätigen.

Normaler lokaler Mock schließt Callback-Lesen/Schreiben synchron ab. Damit bleiben die existierenden lokalen Assistant-/Watch-Bedienungen nutzbar, ohne nachträglich eine asynchrone Bestätigung zu erfinden. Explizite UUID-gebundene Fixtures halten Antworten zurück oder erzeugen Fremdbeobachtungen. Sie benötigen --uitesting plus eine gültige eigene Persistence-Test-UUID; normale Starts können sie nicht aktivieren.

Der persistierte lokale Zustand wird beim Rücklesen tatsächlich gelesen. Nach nicht verifizierbarem Commit wird der Store schreibgeschützt statt automatisch wiederholt. Zurückgewiesene Zukunftsdateien bleiben unverändert; die bestehenden Recovery-Dialogwege bleiben benutzbar.

## Bedienung

Tatsächliches System-Menü für vier Thermostatmodi statt der früheren Mock-Banner-Taste. Metadaten steuern Schritte, Wertebereiche und Schreibbarkeit. Native Minimum-Hit-Slider der Settings bleiben erhalten. Pending-/Bestätigungs-/Fehler-/Read-only-Zustände sind sichtbar. Face-/Homegrid-/Watch-Werte verwenden beobachtete Werte; normale lokale Assistant- und explizite Demo-Plan-Schritte laufen über denselben Vertrag. Szenen behalten die vorhandene lokale atomare Ausführung, validieren betroffene Gerätefähigkeiten und geben erst nach gespeichertem Rücklesen Erfolg aus. Keine neue Routine/Zeitschaltung und kein pauschaler Szenen-/Original-PASS für #26.

## Vorher / Historie

Der neue native Heat-Menüfall scheitert auf unveränderten b314b4f-Produktinputs an der fehlenden tatsächlichen Auswahl. Gespeicherte Aufnahme zeigt den bisherigen Cool-Mock-Banner, keinen Picker. Der erste integrierte native Gegenlauf besteht und zeigt das echte Menü / Heating to bei unverändertem 68°-Sollwert.

Die erste Matrix deckt zusätzlich zwei UI-Fehler auf: Auf beiden Geräten bleibt der Thermostatpfeil trotz Read-only-Metadaten aktiviert. Die Core-Schreibsperre besteht, die Bedienanzeige wird separat korrigiert. Eine externe unveränderte Probe belegt zusätzlich einen Schreibversuch aus einem veralteten Preflight-Descriptor trotz inzwischen geänderter aktueller Read-only-Metadaten; der Rückmeldevertrag wird vor Versand daran gebunden. Keine dieser Fehlrunden wird nachträglich PASS.

## Abschluss und genaue Prüfstände

- **449 Coretests bestanden**, darunter20 Gerätevertragsmethoden.94 Core-/Paket-/Core-Testinputs seit diesem Lauf und dem separaten Prüftreiber bis zum gelieferten Code exakt gleich; kein unnötiger neuer Vollsuite-PASS behauptet.
- **480 separate Vektoren /2.520 Bedingungen bestanden**: Owner/Zeit/Fremdbeobachtung und passende, abweichende oder fehlgeschlagene Rückleseantworten. Parent-geführter unabhängiger Fixturetreiber, kein zusätzlicher menschlicher/Agentenreview. Die unveränderte Stale-Metadata-Gegenprobe scheitert vorher mit einem Schreibversuch und besteht nachher mit null.
- **Vier Hauptregler × vier Ergebnisarten auf beiden mobilen Geräten** einschließlich neuem Prozess und ausbleibender Wiederholung bestanden beim eingefrorenen `57164ff`-Stand. Acht Slottypen sind separat in den aktuellen Coretests abgedeckt; alle vier Modi bleiben unabhängig vom Sollwert gespeichert.
- Danach `fd3a9b8`:20 native Ausführungen,19PASS/ein iPhone-FAIL am unerreichbaren Plan-Folgeschritt. Beide Read-only-/Fünfer-Schritt-Matrizen, Live-Assistant-Status, erfolgreiche Pläne, Migration/Read-only-Speicher, Schloss-Rücklesen/Neustart und Watch-Bedienung grün. Der iPad-Plan war funktional grün, seine Aufnahme zeigt aber denselben zusätzlichen Fehlerdialog; kein fehlerfreier visueller Plan-PASS dafür.
- **Letzter Produktstand `0619708`: neun gezielte native Ausführungen bestanden**: auf iPhone/iPad jeweils derselbe Offline-Plan nun ausdrücklich ohne globale Dialogblockade, tatsächlich sichtbarer asynchroner Assistant-Status und Fehler-ACK mit nachfolgender ausdrücklicher75%-Lüfteraktion; dazu native TV-Fokus-/Bereich-/Fünfer-Schritt-Bedienung und beide Watch-Methoden. Der Plan behält bestätigten ersten Timer, fehlgeschlagenen zweiten und nicht gestarteten dritten Schritt. Keine Rücknahme eines bereits bestätigten Schritts erfunden. Direkte Gerätefehler bleiben quittierbar; Snapshot-Alert-Schutz nicht verändert.
- Gesamte native Historie **45 Ausführungen:41PASS/vier erhaltene FAIL**. Vorher-FAIL, frühe Read-only-Fehler und späterer Planfehler sind keine nachträglich grünen Läufe. Kein einzelner finaler45er-Gesamtlauf und keine vollständige UI-/Plattform-/Hilfsmittelabnahme behauptet.
- **Fünf letzte SDK-Builds und sechs Tooling-Tests bestanden**,73 Produktdateien vollständig archiviert/zurückgelesen. Bei erfolgreichem, aber unvollständigem iOS-AppIntents-Output einmal normale Clean-/Build-Reparatur; beide Versuche erhalten. Kein Siri-/OS-Shortcut-Aufruf aus Metadaten abgeleitet. Die einzige Snapshotdifferenz zum letzten iOS-Testpin ist das zusätzliche Tastatur-Schließen/Scroll-Reveal im unkompilierten iOS-UITest-Input; sämtliche SDK-Produktinputs sind exakt. Vorherige SDK-Produkte und Logs vor Cache-Wiederverwendung separat erhalten.

**242 Quelleingaben**, kompilierte UI-Produkte, ausdrücklich installierte App-/Runnerbytes und alle elf UI-Inputarchive gebunden. Archive bei Erstellung vollständig gelesen, Containerdigests bei Lieferung erneut geprüft.212 PNGs dekodiert,23 Kontaktbögen und die volle iPhone-Planfehleraufnahme tatsächlich gesichtet.17 eigene Aufnahmen bytegeprüft übernommen. Keine Rohlogs, SDK-Header oder fremden Originalbilder veröffentlicht.

Die frühere Phone-Assistant-Aufnahme zeigt den Status außerhalb des tastaturreduzierten Clips. Der letzte native Test behält dieselben Zustandsassertionen bei, schließt zusätzlich die Tastatur und scrollt den tatsächlichen Status vor der Aufnahme vollständig in den Clip. Ein historisches Phone-Fan-Fremdänderungsbild hält nach ACK-Versuch noch den Dialog; es wird nicht als frei sichtbarer Abschluss gewertet. Der separate letzte ACK-Fall wartet auf echtes Verschwinden und verlangt danach eine neue bewusste erfolgreiche Aktion. Manche Settings-Aufnahmen schneiden unbeteiligte Nachbarzeilen ab; keine vollständige Seiten-/Randziel-/Assistive-Abnahme daraus.

## Abnahmegrenze bleibt bestehen

#24 ist im **unveränderten ursprünglichen synthetischen Abnahmeumfang** erfüllt. Der spätere echte Testheim-Anschluss bleibt ausdrücklich separat bei [#23](https://github.com/Olli0103/homeview/issues/23); keine echte Charakteristik, Entdeckung oder Geräteaktion. Der komplette unveränderte NativeServices-Text wirft weiterhin für jeden HomeKit-Konstruktoraufruf, bevor ein Manager existiert. Schlossadapter und Einmalbestätigungs-Core ebenfalls bytegleich zum zuvor gelieferten Sicherheitsstand.

F024–F027/F031 bleiben **partial / parity_accepted=false** für Originalgeometrie und reale Dienste. Nicht unterstützte reale Merkmale wurden nicht durch Mock-Fähigkeiten ersetzt und als Live-Ergebnis ausgegeben. Kein tatsächlicher VoiceOver-/Switch-Control-/Hardware-/Energie-/Signing-PASS. Keine OS-/Gateway-/TCC-/Berechtigungs-, Konto-, Aufnahme-, Medien- oder Telefonieänderung. Snoopy bleibt ausgeschlossen, kein History-Rewrite oder Force-Push. Der gesamte Backlogauftrag wird nach dieser Lieferung fortgesetzt.
