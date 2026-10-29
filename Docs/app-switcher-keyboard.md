# Tastaturebene über dem Snapshot-Schutz schließen

29. Oktober 2026 · begrenzter Anschlussfix zu [#67](https://github.com/Olli0103/homeview/issues/67), Gesamtissue offen. Die zuvor korrigierten [offenen Dialoge](app-switcher-dialogs.md) sind ein getrennter Quellenstand.

## Vorher: zwei iPhone-Fehler, zwei grüne iPad-Gegenkontrollen

Zwei neue Fälle geben ausschließlich synthetische Marker in Assistent und verbundenem Fixture-Reminder ein. Sie betätigen weder Send noch Add. Die native Geste erreicht den tatsächlichen OS-App-Umschalter und die vollständig sichtbare HomeView-Karte; anschließend wird die tatsächliche Karte berührt und der erhaltene Entwurf geprüft.

Auf iPhone 18 Pro / iOS 27 Simulator bleibt bei beiden Fällen die Tastatur samt Vorschlagsleiste **über** der vorhandenen schwarzen Root-Abdeckung sichtbar. Der Entwurfstext selbst ist bereits verdeckt; die gesichteten Vorschläge sind generisch. **Kein beobachteter Canary-/Termintext-Leak wird daraus behauptet.** Der deklarierte vollständige Karten-Schwarzanteil liegt nur bei 62,09 % beziehungsweise 62,10 % statt mindestens 98 %. Auf iPad Air 11-inch (M4) / iOS 27 Simulator sind beide Karten bereits vorher ohne Tastatur geschützt (99,00 %); beide Vorherfälle bestehen dort einschließlich Rückkehr.

Alle 19 gebauten Produktdateien waren beim Vorherlauf bytegleich zum veröffentlichten Stand `d0312c2`. Nur die zwei neuen UI-Methoden waren hinzugekommen. Die beiden tatsächlichen iPhone-Fehler und die beiden erfolgreichen iPad-Gegenkontrollen bleiben separat erhalten.

## Nur die betroffenen FocusStates geändert

`AssistantView` löst seinen vorhandenen `typing`-FocusState bei Inaktivität; `DeviceRemindersView` beobachtet die ScenePhase und löst seinen vorhandenen `inputFocused`-FocusState ebenfalls. Keine globale First-Responder-Manipulation, Änderung der Root-Abdeckung, Authentifizierungs- oder Sitzungswiderruf bei bloßer Inaktivität. Voice-Vorbereitung behält ihren vorhandenen Lifecycle-Sonderfall.

Die gleichen vier Snapshot-Ausführungen bestehen danach ohne Teständerung. Die gesichteten vollständigen Karten sind ohne sichtbare Tastatur geschützt (iPhone 98,27 %, iPad 99,00 %). Nach tatsächlicher Kartenberührung bleiben die ursprünglichen Entwürfe erhalten, die Assistentenantwort ist unverändert und kein Fixture-Reminder wurde hinzugefügt. Die Tastatur öffnet nicht ungefragt erneut.

## Finale Prüfung an einem Quellenstand

**Zehn erfolgreiche UI-Ausführungen, fünf eindeutige Methoden je zwei Simulatoren**: vier neue Snapshot-Fälle und sechs vorhandene Regressionen für Assistenten-Entwurf/Navigation/echten Hintergrund, Reminder-CRUD mit Fixture-Read-back sowie synthetische Sprachvorschau vor bewusstem lokalen Mock-Send. Letztere Regression betätigt Send ausdrücklich nur gegen den lokalen Mock-Thermostat; Reminder-CRUD verändert nur eigene synthetische Providerdaten. Keine reale Home-Anbindung, Nachricht, Erinnerung oder Kontoverbindung.

Fünf arm64-SDK-Builds bestehen, ohne neue Laufzeitabnahme der vier Nicht-iOS-Plattformen. 225 finale Quell-/Testeingaben und dieselben kompilierten App-/Test-/Launch-Eingaben über Kandidat und Regressionen geprüft. Sechs ausgeführte Archive einschließlich der Vorherläufe vollständig zurückgelesen; installierte Apps je Lauf geprüft. Core-/Package-/Core-Testeingaben unverändert, kein neuer Core-Lauf. Die früheren zwölf Dialogausführungen werden nicht zu einer aktuellen 22er-Suite umdeklariert.

Die tatsächlichen Bilder ergänzen den groben Pixelguard; er ist weder OCR noch eine physische oder zeitliche Garantie. Rohbilder fremder OS-App-Karten/Bäume bleiben privat. Eigene synthetische Vordergrundbilder sind [gespeichert und bytegeprüft](screenshots/app-switcher-keyboard). Ein vor Prozessende versuchter Anhangexport scheiterte am noch unfertigen Ergebnisbündel; der Testlauf wurde weder abgebrochen noch wiederholt. Nach eingesammeltem Prozessende gelangen Ergebnis-/Bildexport und Prüfung regulär; dies war kein Produkt- oder Korruptionsbefund.

36 PNGs über Vorher-/Nachher-/Regressionsläufe dekodiert, sechs Übersichten und zwei vollständige native Karten tatsächlich gesichtet; 14 eigene Bildkopien bytegeprüft. 73 tatsächliche SDK-Produktdateien separat archiviert und zurückgelesen, 88 Core-/Package-/Core-Testeingaben bytegleich. Alle 58 Ressourcen und 17 Provenienzeingaben bestehen die aktuelle Assetprüfung; kein neuer historischer Rechteentscheid.

Finaler Quelldigest: `9612b6671648a330a6199830cc0097a16a6c6eae8e7224fa2eb23f5f3211eb59`.
Finales UI-Eingabearchiv: `cec3dc6b33659ef76ea91e701f188d4bd9abb1ba8858245909b2a04431ed8e95`.

[Getrennte Ergebnisse und Bildmanifeste](verification/app-switcher-keyboard.json) · [zwei ausgeführte Quellenvarianten](verification/app-switcher-keyboard-source.json) · [SDK-/Produktarchive](verification/app-switcher-keyboard-platforms.json).

**#67 bleibt OPEN, F095 partial/parity=false.** Diese zwei Eingaberouten sind geprüft, nicht sämtliche Textfelder, Dialoge oder native OS-Präsentationen. Physische Snapshots/Authentifizierung, echte Präsenz und vollständige Unterbrechungs-/Medienpolicy bleiben offen. Geräte-/Signing-Abnahme bleibt auf Eigentümerwunsch pausiert; keine erneute Nachfrage oder Home-Einrichtung.
