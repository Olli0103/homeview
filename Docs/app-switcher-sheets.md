# Elf weitere Sheet-Präsentationen vor OS-Snapshots schützen

29. Oktober 2026 · Fortsetzung von [#67](https://github.com/Olli0103/homeview/issues/67). Gesamtissue bleibt offen. Vorheriger Stand: `11b3d79`; die früheren [Profil-/Stadtdialoge](app-switcher-dialogs.md) und [Root-Eingaben](app-switcher-keyboard.md) sind getrennte Nachweise.

## Tatsächlicher Vorherbefund

Alle elf noch ungeschützten app-eigenen SwiftUI-Sheet-Präsentationsstellen wurden auf iPhone 18 Pro und iPad Air 11-inch (M4), jeweils iOS 27 Simulator, geprüft. Die native SpringBoard-Geste, tatsächliche HomeView-Kartenkennung und vollständige Karten-Geometrie werden vor der Auswertung verlangt. **22 von 22 Vorher-Snapshots zeigen weiterhin Sheet-Inhalte.** Im Reset-Fall ist der selbst eingegebene synthetische Text `NOT_RESET` auf beiden Geräten sichtbar; auf dem iPhone zusätzlich die Tastatur.

Nicht jeder sichtbare Dialog enthält persönliche Daten. Die bisherige Redaktion privater Mock-Hausmitteilungen bei Inaktivität funktioniert bereits; kein neuer beobachteter Leak ihres entschlüsselten Namens wird daraus behauptet. Auch Informationsseiten sollen die vorhandene app-weite Snapshot-Policy nicht durch eine höhere Präsentationsebene umgehen.

Ein erster Vorherlauf mit acht fehlgeschlagenen Methodenausführungen stoppte jeweils am ersten Sheet der vier Gruppen. Der gesondert archivierte Matrix-Stand aktiviert Weiterführung nach Assertions und ergänzt die Reset-Rückkehrprüfung. Dieser zweite Vorherlauf führt alle elf Zustände je Gerät aus und scheitert ausschließlich an den 22 unveränderten Schutz-Guards. Seine acht fehlgeschlagenen Methodenausführungen bleiben separat erhalten. Alle 19 gebauten Produktdateien beider Vorherstände sind bytegleich zum zuvor veröffentlichten Produkt; keine Änderung am Produkt vor der Reproduktion.

## Begrenzte Korrektur

Sieben Produktdateien: Der vorhandene `snapshotPrivacyProtected()`-Modifier sitzt nun **innerhalb** aller elf betroffenen Präsentationen. Das Reset-Textfeld löst seinen eigenen vorhandenen FocusState bei Inaktivität. Keine globale First-Responder-Manipulation, neue Geräteauthentifizierung, Sitzungswiderruf bei bloßer Inaktivität oder Änderung der Provider-/Medien-/Resetlogik.

Die identischen Matrix-Tests bestehen anschließend: **22 von 22 vollständigen Karten ohne sichtbare Sheet-Inhalte oder Tastatur**. Nach Berührung der tatsächlichen OS-Karte bleiben die Dialoge bedienbar. Assistentenentwurf und `NOT_RESET` bleiben erhalten, Reset ist weiter deaktiviert; keine Send-/Resetaktion. Timer-Activity bleibt ausgeschaltet, Musik startet nicht, der Complication-Picker lässt sich normal schließen. Der normale Hintergrund-Widerruf bleibt eine getrennte Regression.

Der grobe Schwarzanteil für RGB unter 20 ergänzt die Sichtprüfung, ersetzt sie nicht. Eigene OS-Badges, runde Außenecken und native Sheet-Kanten/Griffe sind kein persönlicher Inhalt und keine behauptete perfekte Schwarzfläche.

| Zustand | iPhone vorher | iPad vorher | iPhone nachher | iPad nachher |
|---|---:|---:|---:|---:|
| Assistentenfähigkeiten | 12.15 % | 61.29 % | 98.23 % | 99.00 % |
| Antwort-Vorleseeinstellungen | 8.20 % | 60.25 % | 98.23 % | 99.00 % |
| Assistentenquelle | 8.08 % | 60.22 % | 98.20 % | 98.97 % |
| Mock-Hausmitteilungen | 8.27 % | 60.28 % | 98.23 % | 99.00 % |
| Strominfo | 10.08 % | 60.73 % | 98.23 % | 99.00 % |
| Timer-Activity-Einstellungen | 10.01 % | 60.74 % | 98.20 % | 98.97 % |
| Weltuhrdetails | 7.34 % | 60.01 % | 98.23 % | 99.00 % |
| Complication-Picker | 49.75 % | 61.78 % | 98.23 % | 98.98 % |
| Artwork-/Lyrics-Info | 8.46 % | 60.33 % | 98.20 % | 98.97 % |
| Einführung | 10.13 % | 60.75 % | 98.23 % | 99.00 % |
| Lokaler Reset mit Textfeld | 9.45 % | 61.12 % | 98.23 % | 99.00 % |

## Aktuelle Abnahme an einem Quellenstand

**20 erfolgreiche UI-Ausführungen, zehn eindeutige Methoden je zwei Geräte**, keine Skips oder strukturierten Runtimewarnungen:

- Acht Matrix-Ausführungen prüfen die elf zusätzlichen Sheet-Zustände auf beiden Simulatoren, inklusive tatsächlicher OS-Kartenrückkehr, Entwurfserhalt und Bedienung.
- Zwölf Regressionen prüfen Kalender-Umschalter und echten Hintergrund/Fresh Unlock, offene Profil-/Stadtdialoge, ungesendeten Assistenten-/nicht hinzugefügten Fixture-Reminder-Entwurf sowie verweigerte Reset-Authentifizierung und Widerruf ohne Löschung.
- Fünf arm64-SDK-Builds bestehen: iOS, macOS, tvOS, visionOS, watchOS. Dies ist keine neue Nicht-iOS-Laufzeitabnahme.

225 finale Quellen und dieselben kompilierten App-/Test-/Launch-Eingaben über Matrix und Regressionen vor/nach geprüft. Installierte Appbytes je Lauf verifiziert. Acht ausgeführte Eingabearchive einschließlich beider Vorherphasen vollständig zurückgelesen; SDK-Produktdateien separat archiviert und zurückgelesen. 88 Core-/Package-/Core-Testeingaben gegenüber `11b3d79` unverändert; **kein neuer Core-Lauf**. Alle 58 Ressourcen und 17 Provenienzeingaben sowie 105 Referenzpunkte/82 Backlogpakete bestehen die vorhandenen Prüfungen.

258 PNGs dekodiert; 14 tatsächliche Sichtprüfungen von Übersichten/Einzelbildern im Receipt, einschließlich aller 22 Vorher- und 22 Nachher-Karten und der Rückkehrzustände. Zwölf eigene synthetische Vordergrundbilder gespeichert und bytegeprüft. Rohe OS-Bilder/Bäume mit fremden Karten bleiben privat. Ein früher Build ohne explizite arm64-Auswahl scheiterte an FeedKit-Auflösung, bevor Tests liefen; der korrekte vorhandene Buildaufruf besteht. Ein erster Bildexport-Aufruf verwendete Python ohne Pillow und wurde anschließend im vorhandenen passenden Environment ausgeführt; kein Test wurde deshalb wiederholt.

Finaler Quelldigest: `6e2ea9bb29f6f64cc3d0ac63530080fcb9013f12470018a0799756fdb4c9132a`.

[Getrennte Läufe, Snapshot-Receipts und Bilder](verification/app-switcher-sheets.json) · [drei ausgeführte Quellenvarianten](verification/app-switcher-sheets-source.json) · [fünf SDKs und Produktarchiv](verification/app-switcher-sheets-platforms.json).

## Offene Grenzen

**#67 bleibt OPEN, F095 partial/parity=false.** Die 13 aktuell vorhandenen app-eigenen SwiftUI-Sheet-Stellen haben nun eine Abdeckung; hier beobachtet sind die elf benannten normalen Zustände plus die expliziten Regressionen, nicht jede dynamische Variante. Nativer Messages-Composer, Alerts/Fehlerpräsentationen, übrige Root-Textfelder, physische Snapshots/Authentifizierung, echte Präsenz und vollständige Unterbrechungs-/Medienregeln bleiben getrennte offene Grenzen. Keine pauschale Snapshot-, Timing-, OCR- oder Original-Parity-Garantie.

Geräte-/Signing-Abnahme bleibt auf Eigentümerwunsch pausiert. Keine Home-Anbindung, realen Konten, Nachrichten/Anrufe, Löschung bestehender persönlicher Inhalte oder neuen Systemalarme/Live Activities.
