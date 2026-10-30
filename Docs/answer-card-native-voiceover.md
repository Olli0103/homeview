# Native Kartenleseprüfung und Read-only-Kennzeichnung

30. Oktober 2026 · [#36](https://github.com/Olli0103/homeview/issues/36) bleibt **offen**, F046 partial/parity=false. [Gebundene Ergebnisse](verification/answer-card-native-voiceover-20261030.json).

## Ein tatsächlicher Produktfehler, eng korrigiert

Die fiktive Nachrichtenkarte zeigte „Read-only excerpt“, ignorierte aber ihre Kinder für Accessibility und ließ genau diese Einschränkung in ihrer zusammengefassten Beschriftung weg. Die unveränderte neue Regression scheiterte zunächst gegen den alten Produktcode: vollständiges AX-Label und tatsächliches natives Fokus-Ergebnis enthielten die Einschränkung nicht. **Eine fehlgeschlagene Ausführung mit zwei verletzten Bedingungen**, nicht zwei Tests.

Der Produktfix ergänzt ausschließlich `Read-only excerpt.` am Anfang dieses Labels. Absender, Zeit und vollständiger Nachrichtentext bleiben unverändert enthalten. Keine Layout-, Grafik-, Aktions-, Freigabe- oder Quellenänderung. Die Karte bleibt nicht ausführbar; der ungesendete `temperature 91`-Entwurf und der Mock-Thermostat mit68° bleiben erhalten.

Die identische Regression erreicht auf iPhone und iPad die Karte über das tatsächliche `XCUIVoiceOverService`, meldet die kurze Einschränkung, prüft Rückwärts-/Vorwärtsfokus und stellt den ursprünglichen ausgeschalteten VoiceOver-Zustand wieder her. **Zwei aktuelle native Qualifier-PASS plus zwölf bestehende UI-PASS**, null Fehler/Skips/strukturierte Runtime-Warnungen. Das vollständige AX-Label umfasst136Zeichen; der native Reporter liefert hier64Zeichen. Vollständige AX-Daten und vollständig gesprochene Daten sind getrennte Nachweise.

## Vollständiges Lesen langer Inhalte ist nicht bewiesen

Vor dem Fix wurden zwei native iPhone-Piloten für vollständige Wissens-/Nachrichtenlektüre ausgeführt. **Beide bleiben FAIL.** Lange erwartete Antwort-/Karten-/Hinweistexte wurden nur als64-Zeichen-Präfix gemeldet; kürzere Angaben, Bildbeschreibung und benannte Quelle/Folgeaktion wurden erreicht. Die neun geplanten Fälle waren kein neunteiliger Testlauf: sieben davon wurden nicht ausgeführt. Der erste Nachrichtenpilot hatte zudem die Read-only-Einschränkung nicht in seiner Sollgruppe; diese Lücke wurde durch die separat rot/grün ausgeführte Regression geschlossen.

Ein unabhängiger Standard-UIKit-Button trägt ein154Zeichen langes, vollständig vorhandenes AX-Label. Beide normalen Button-Callbacks funktionieren, die native App meldet tatsächlich laufendes VoiceOver. Die kurze Kontrollausgabe mit41Zeichen ist vollständig; der lange Button liefert bei gleichem Fokus nach0,2und8Sekunden jeweils dasselbe64Zeichen-Präfix. Auch dieser Versuch stellt VoiceOver wieder aus. **Ein bestandener Beobachtungstest, kein vollständiger Lese-/Audio-PASS.** Die genaue interne Ursache bleibt unbekannt; der Befund gilt für den beobachteten SDK-/Simulatorlauf, nicht als universelle zukünftige Grenze oder ausschließlich als HomeView-Defekt.

Insgesamt18tatsächliche UI-Ausführungen:14aktuelle Regressionen bestanden, eine separate UIKit-Beobachtung bestanden und drei erhaltene Fehlläufe. Alle sechs nativen VoiceOver-Ausführungen stellten den ursprünglichen Zustand wieder her. Die [experimentellen Quellen](verification/answer-card-native-voiceover-20261030/README.md) liegen als Text außerhalb des normalen Testtargets; dort bleibt nur die kurze Qualifier-Regression. Produktionsinhalt wurde nicht für das Reporterlimit gekürzt oder künstlich aufgeteilt. Keine akustische Aufnahme oder Beurteilung.

## Eingaben, Builds und Bilder

245Quell-/Test-/Ressourcen-/Buildeingaben eingefroren, Digest `d9dc440021ae02cdd8da8dd142f3e97ec66a34d8252a6cd77cf0c088eeddce5c`. Gegenüber dem fehlgeschlagenen Qualifier-Baseline-Lauf ändert sich ausschließlich die eine Produktzeile; der Test ist identisch. Fünf aktuelle SDKs bestanden, alle73Produktdateien zurückgelesen. Eine reguläre iOS-Paketmetadaten-Clean-Recovery wurde benötigt; der ursprüngliche Zwischenstand bleibt dokumentiert. Der Clean entfernte den UI-Runner: die erste UI-Vorbereitung scheiterte vor null Testausführungen. Ein reguläres `build-for-testing` stellte die Inputs wieder her, ohne manuelles Zurückkopieren alter Produkte. Die Test-/Runner-/Launchbytes entsprechen der roten Baseline; die App entspricht exakt den neuen SDK-Produkten.

Alle32kompilierten UI-/Launchinputs und245Quellen unverändert durch die aktuellen Läufe; installierte App vor/nach und Runner/Tests nachher auf beiden Geräten bytegeprüft. Neue App-Deltas statt doppelter Vollarchive; alle Eingaben aus versiegelten Archiven rekonstruiert. Fünf terminale Ergebnisbundles mit528Dateien/42.705.665Bytes vor Ort gehasht und vollständig zurückgelesen. Kein neuer Core-Lauf für diese reine Accessibility-Beschriftung.

107PNG vollständig dekodiert. Alle56ausgewählten aktuellen/Baseline-Zustände auf neun Kontaktbögen tatsächlich gesichtet; die unabhängige UIKit-Kontrolle zusätzlich als volles Bild. Sechs [eigene Nachrichtencaptures](screenshots/answer-card-native-voiceover-20261030/manifest.json) veröffentlicht. Der vorab festgelegte Vergleich der normalen iPhone-Ansicht vor VoiceOver ergibt **null geänderte RGBA-Pixel**:1134×2046, identische Capture-/Cropgeometrie und identischer PNG-Digest. Keine Maske, Registrierung oder Toleranz. Kein frisches iPad-Vorherpaar, kein Fokusrahmen-/Originalvergleich daraus.

Offen bleiben vollständige lange native Lektüre, die nicht ausgeführten Karten-/Quellenfälle, Switch Control, Dynamic Type, Kontrast, physische Abnahme sowie vollständige Originalgeometrie/-bewegung und produktive dynamische Karten. Ausschließlich fiktive UUID-Stores und Nachrichten; keine persönlichen Quellen, Nachricht, Anruf, Aufnahme oder reale Home-Aktion. Geräte-/Signing-Hold unverändert.
