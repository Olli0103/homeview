# Native Fehlermeldungen im App-Umschalter schützen

29. Oktober 2026 · begrenzter Anschlussfix zu [#67](https://github.com/Olli0103/homeview/issues/67), kein vollständiger Datenschutz-/Hardware-PASS.

## Beobachteter Vorherstand

Zwei neue native Fälle nutzen ausschließlich den vorhandenen UUID-eigenen Speicher mit der synthetischen zukünftigen Version 99: ein abgewiesenes Thermostat-Speichern und eine abgewiesene Komplikationswahl im Editor-Picker. Kein neuer Produkt-Testdialog, persönliche Payload oder reale Quelle. Alle 165 Produkt-/Ressourceneingaben waren bytegleich zu `eb81e22`; nur die UI-Matrix wurde ergänzt.

Alle vier Vorherausführungen auf iPhone 18 Pro und iPad Air 11-inch (M4), jeweils iOS 27.0 Simulator, zeigen die generische native Fehlermeldung **über der schwarzen Abdeckung** im tatsächlichen OS-Umschalter. Der volle Karten-Schwarzanteil liegt bei 81,15–81,46 % beziehungsweise 92,79–92,91 %. Das ist kein beobachteter privater Inhaltsleck-Befund. Native Fenster-/App-Kartenidentität und vollständig sichtbare eigene Karte werden vor dem groben Pixelguard verlangt.

Nur der unabhängige letzte Privacy-Guard darf nach erfolgreicher Navigation weiterlaufen. Dadurch werden auch bei seinem Vorherfehler die echte Kartenrückkehr, genaue Fehlermeldung, unveränderter Wert, ursprünglicher Picker und Read-only-Relaunch geprüft. Diese Rückkehrprüfungen bestehen schon vorher.

## Ersten Kandidaten verworfen

Ein rein phasenabhängiger Präsentations-Binding-Getter verdeckt die vier Alerts, stellt sie nach der Rückkehr aber nicht wieder sichtbar her: vier fehlgeschlagene Alert-Existenzprüfungen. Dieser Kandidat ist nicht ausgeliefert. Aus dem Verschwinden wird weder eine bewiesene Löschung des Model-Fehlers noch ein bewiesener UIKit-Callback-Auslöser abgeleitet.

## Abgegrenzte Korrektur

Nur `RootView.swift` und `FaceEditor.swift` ändern Produktcode. Ein gemeinsamer SwiftUI-Modifier trennt den logischen Fehlerinhalt vom nativen Präsentationszustand. Inaktivität beendet die Präsentation, nicht die Fehlermeldung. Aktivität präsentiert den vorhandenen Fehler erneut; Generation und erwartete Meldung grenzen alte Präsentations-/Bestätigungsrückmeldungen ein. Bewusstes OK quittiert weiterhin die aktuelle Meldung. Keine neue Authentifizierungsentwertung, Änderung des Core-Speichers oder reale Aktion.

Die **unveränderte** neue Zweimethodenmatrix besteht danach auf beiden Simulatoren: ganze Karten geschützt, genaue Meldung nach tatsächlicher Kartenberührung wieder vorhanden, bewusstes OK bedienbar, 68° beziehungsweise Komplikationsauswahl und ursprünglicher Picker erhalten. Der volle grobe Kartenanteil liegt bei 98,23–98,27 % auf iPhone und 98,98–99,00 % auf iPad. Tatsächliche Bildsichtung ergänzt diesen Guard; er ist keine OCR-/Zeit-/Hardwaregarantie. Die Rückkehr-Screenshots werden vor dem nachfolgenden `waitForExistence` aufgenommen: iPad zeigt teils den Präsentationsübergang, nicht den endgültig ruhenden Alert. Die genaue Wiederherstellung wird anschließend durch native Element-/Text- und OK-Bedienprüfungen belegt.

## Quellen- und Artefaktbindung

Zwölf aktuelle UI-Ausführungen, sechs eindeutige Methoden je zwei Simulatoren: vier neue Alert-Ausführungen plus acht vorhandene Regressionen für Kalender/echten Hintergrund/Fresh Unlock, Future-Store-Schreibschutz, Face-/Slot-Erhalt und Detail-/Editor-Sheets. Fünf frische arm64-SDK-Builds; daraus folgt keine neue Nicht-iOS-Laufzeitabnahme. Alle 73 SDK-Produktdateien einschließlich der fünf generierten iOS-AppIntents-Dateien sind archiviert und bytegeprüft.

231 finale Quellen und identische kompilierte App-/Test-/Launch-Eingaben über aktuelle Fälle und Regressionen; acht Archive aller Vorher-/Kandidaten-/Regressionsläufe zurückgelesen und installierte Appbytes je Lauf geprüft. 163 von 165 Produkt-/Ressourceneingaben unverändert. Alle 88 Core-/Package-/Core-Testeingaben entsprechen dem vorherigen 398-Coretest-Stand; kein neuer Core-Lauf. Zwölf eigene ursprüngliche Future-Store-Dateien bleiben genau 14 Bytes mit SHA-256 `9a2f382f9e837c60ef6c2dcc8efeb1b0e2e37ce828e692deb08fb9b0d798d2d7`.

Historisch insgesamt 20 UI-Ausführungen: zwölf aktuelle Erfolge, vier Vorher-Privacyfehler und vier verworfene Kandidaten-Rückkehrfehler. Keine Umdeklarierung als 20 aktuelle Erfolge. 100 PNGs dekodiert, zwölf Übersichten und vier vollständige Einzelbilder tatsächlich gesichtet; acht eigene innere Kartenbereiche pixel-/bytegeprüft und ihre zusätzliche Übersicht gesichtet. 58 aktuelle Ressourcen und 17 Provenienzeingaben geprüft, kein neuer historischer Rechteentscheid. [Quellen, genaue Ergebnisse, Bild-/Produktmanifeste und Grenzen](verification/app-switcher-alerts.json). [Eigene innere Kartenbereiche](screenshots/app-switcher-alerts) sind deterministisch aus den Originalen ausgeschnitten; rohe OS-Bilder, fremde Karten und abgerundete Außenbereiche bleiben privat.

Finaler Quelldigest: `958357fca2e6f8ecbaf6b1cd02bc5caad30164568e74981bc59561d4f59385ce`.

**#67 bleibt OPEN, F095 partial/parity=false.** Nur diese zwei generischen App-Alerts sind geprüft; native MessageUI-Composer, weitere OS-Präsentationen, physische Snapshots/Authentifizierung, echte Präsenz und vollständige Unterbrechungs-/Medienregeln bleiben getrennt offen. Geräte-/Signing-Pause und Home-Sperre unverändert. Keine echten persönlichen Konten, Nachrichten, Anrufe oder Datenlöschung.
