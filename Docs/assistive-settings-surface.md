# iOS27-Simulator: beobachtete Hilfsmittelgrenze

30. Oktober 2026 · [#73](https://github.com/Olli0103/homeview/issues/73) bleibt offen.

Auf den beiden eigenen iOS27.0/24A434-Simulatoren (iPhone18Pro und iPadAir11M4) ist der normale öffentliche Settings-Pfad zu AssistiveTouch nicht erreichbar. Die tatsächliche Accessibility-Seite wurde oben und nach drei ausschließlich auf ihrer Tabelle ausgeführten Scrolls aufgenommen. Die Bilder zeigen den gesamten kurzen Inhalt bis „General“; die letzten Scrollposen bleiben am Ende. „Touch“, „AssistiveTouch“, „Switch Control“, „Voice Control“ und „Zoom“ erscheinen weder in den beobachteten Menübäumen noch in diesen sichtbaren Menüs. Die UIKit-Abfrage `UIAccessibility.isAssistiveTouchRunning` bleibt auf beiden Geräten vorher/nachher `false`.

Das ist eine **konkrete Grenze dieses beobachteten Simulator-Menüpfads**, keine allgemeine Aussage über öffentliche APIs, echte Geräte oder sämtliche anderen Aktivierungsmöglichkeiten. Kein versteckter Preferences-Link, privates Framework, Hostschalter oder App-Override wurde eingesetzt. Kein Hilfsmittel wurde aktiviert; keine App-Bedienung mit diesen Hilfsmitteln wird als bestanden ausgegeben. Die originale Abnahme bleibt erforderlich.

## Getrennte Ausführungen

- Ein früher Telefonlauf scheitert am nicht erreichten `Touch`-Button. Die erste Vermutung eines reinen Selektorfehlers wurde durch die vollständige Menüinventur nicht bestätigt; der Fehler bleibt erhalten.
- Zwei spätere read-only Inventuren, je eine pro Gerät, bestehen ohne Skip oder strukturierte XCTest-Runtime-Warnung. „Bestanden“ bezeichnet ausschließlich ihre Menü-/Zustandsaufnahme, **nicht** AssistiveTouch-, Sprachsteuerungs-, Schaltersteuerungs- oder Zoom-Bedienung.
- Zehn native PNGs vollständig dekodiert und auf einer Übersicht gesichtet; ein ursprüngliches Telefonbild zusätzlich in voller Größe geprüft. OS-Bilder, Menübäume und Rohprotokolle bleiben privat.

[Quellen, Einzelzahlen und Zustandsberichte](verification/assistive-settings-surface-20261030.json) · [exakter späterer Diagnosequelltext](verification/assistive-settings-inventory-20261030.swift).

Nur temporärer UI-Diagnosecode war während der Ausführungen ergänzt; die 253 Produkt-/Test-/Projektinputs sind danach vollständig auf den veröffentlichten Stand `0369baf` zurückgesetzt und bytegeprüft. Pro Testpin 33 kompilierte App-/Runner-/Launcheingaben archiviert/zurückgelesen sowie installierte eigene App-/Runnerbytes geprüft. Kein neuer Core-, Fünf-SDK- oder HomeView-UI-PASS. Keine persönliche Bibliothek, Verbindung, Mikrofon-, Kamera-, Nearby-Device- oder Home-Nutzung. Geräte-/Signingpause unverändert.

Der Backlogauftrag geht mit dem offenen nativen TV-Timer-Sprachfokus weiter; dieser Simulatorbefund schließt kein Issue.
