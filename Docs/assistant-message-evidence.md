# Schreibgeschützter Nachrichtenbeleg als Antwortbeispiel

29. Oktober 2026 · Teilumsetzung [#36](https://github.com/Olli0103/homeview/issues/36), F046 weiter `partial` / `parity_accepted=false`.

Die [vollständig nachgeprüfte S07-Folge](remaining-original-gifs-20261029.md) zeigt einen zusätzlichen sichtbaren Typ: Textantwort mit kleinem Nachrichtenbeleg. Die vorhandenen lokalen Karten deckten Wissen/Bild, Agenda und Rezept ab, diesen Typ aber noch nicht. Das neue **Answer examples → Sample message** ergänzt ihn innerhalb des bestehenden SwiftUI-/geschlossenen Beispielmodells, ohne neue Abhängigkeit oder Dienst.

Die Karte enthält ausschließlich erfundene feste Angaben: Avery Morgan, Central Station, eine Zugankunft und einen Beispielzeitstempel. Sie ist sichtbar als *Fictional message · Read-only excerpt* gekennzeichnet. Zusammengefasste Accessibility-Beschriftung nennt Absender, Zeit und vollständigen Auszug; das Symbol ist dekorativ. Es werden weder Originalnachricht/-avatar/-namen noch persönliche Daten kopiert.

## Keine Nachrichtenaktion

`MessageExcerpt` ist nur ein Darstellungstyp mit drei Textfeldern, ohne Empfänger, URL oder Aktion. Alle Texte werden wörtlich dargestellt. Kein User-/Providertext wird zum Kartenformat oder Befehl. Die Karte ist kein Button; Tap behält Ansicht und ungesendeten Entwurf. Der Quellenchip öffnet nur die lokale Erklärung, ohne externen Link oder Accounts. Folgebuttons wählen ausdrücklich ein anderes gespeichertes Beispiel. Die einzige bestehende Karten-Navigation bleibt das separat bewusste Öffnen des gebündelten Rezeptbeispiels.

Beispiele bleiben im Arbeitsspeicher. Neue Antwort, ausdrückliches Send, Navigation und Hintergrund-/Sperrpfade verwerfen die Karte nach der vorhandenen Politik. Im On-device-Modus entstehen keine persönlichen oder dynamischen Karten. Der Vorlesepfad erhält weiterhin den Antworttext, nicht automatisch alle Kartenzeilen; eine tatsächliche VoiceOver-Abnahme wird aus der AX-Beschriftung nicht abgeleitet.

## Geprüfter Stand

- **398 Coretests**, einschließlich des neuen schreibgeschützten/fiktiven Quellenfalls, bestanden. Zwei vorhandene ungenutzte Bool-Ergebnisse in anderen Tests bleiben Compilerwarnungen.
- **Zehn aktuelle native UI-Ausführungen**, fünf Methoden auf beiden Simulatoren: zwei neue Nachrichtenfälle sowie vorhandene Wissen-/Quellen-/Agenda-, Rezeptaktions- und fertige Sprachentwurfsregressionen. Null Fehler/Skips/strukturierte Runtime-Warnungen; keine Vollsuite oder neuer separater AppModel-Probelauf behauptet.
- Tatsächliche Karte/Tap, lokales Quellenblatt ohne Link, Folgekarte, unveränderter ungesendeter `temperature 91`-Entwurf und weiterhin68°-Mock-Thermostat geprüft. Hintergrund/Rückkehr und neuer ausdrücklich gesendeter synthetischer Text entfernen die Nachrichtendarstellung.
- **Fünf aktuelle SDK-Builds** bestanden.231 Quellinputs vor/nach unverändert; beide UI-Archive vollständig zurückgelesen, identische kompilierte Eingaben und installierte Appbytes geprüft.73SDK-Produktdateien archiviert/zurückgelesen. Quelldigest `987f80fca38959b4d68cd9eb62152389703d7e63d09cf63ab579014a9b861dcc`.
-56PNG dekodiert, sechs Kontaktbögen und vier zusätzliche volle Karten-/Quellenbilder tatsächlich gesichtet; acht eigene Bilder veröffentlicht. Auf dem schmalen Telefon liegt der obere Header bei der gemessenen Scrollposition teilweise außerhalb des Inhaltsausschnitts, die Nachrichtenkarte selbst ist vollständig sichtbar. Keine formale Mindestschrift-/Kontrast-/Originalpixelabnahme daraus.

[Hash-, Quellen-, Installations-, Ergebnis- und Bildbindung](verification/assistant-message-evidence.json). Rohbelege extern unter `research/homeview-assistant-message-card-20261029`. Flüchtige UITesting-Fixtures, keine normalen persönlichen Stores beschrieben, keine echte Nachrichtensuche, ausgehende Nachricht, Kamera/Mikrofon, Home oder Systemalarmfreigabe.

## Offen

Produktive/dynamische Nachrichten-/Kalender-/Siri-Karten, vollständige Originalgeometrie und Bewegung sowie tatsächliche VoiceOver-/Switch-Control-/Dynamic-Type-/Kontrast-/Geräteabnahme bleiben separat offen. **#36 bleibt offen**; Geräte-/Signing-Hold unverändert, andere umsetzbare Issues werden weiterbearbeitet.
