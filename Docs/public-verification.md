# Öffentliche Kopie: Prüfung

17. Oktober 2026. Frische Prüfung nach Austausch der Referenzassets und Ziffernkonturen.

| Prüfung | Ergebnis |
|---|---|
| Modelltests | 32 bestanden, 0 Fehler |
| Gezielte UI-Tests iPad Air 11-inch M4, iOS 27 | 5 bestanden, 0 Fehler, 0 übersprungen, keine Runtime-Warnungen |
| Gezielte UI-Tests iPhone 18 Pro, iOS 27 | 5 bestanden, 0 Fehler, 0 übersprungen, keine Runtime-Warnungen |
| SDK-Builds | iOS, macOS, tvOS, visionOS, watchOS erfolgreich |

42 erfolgreiche Testausführungen auf dieser öffentlichen Quellbasis. Die gezielte UI-Auswahl prüft farbige Glyphen bei ausgeschaltetem Flow-Hintergrund, weitere Bewegung nach 30 Sekunden, Stillstand bei Reduce Motion, bewusst ausgewählte synthetische Galerie sowie Browser-Rezeptimport bis Kochansicht und Anheften. Keine neue vollständige UI-Suite behauptet.

Vier echte Simulatorbilder mit öffentlichen Ersatzassets wurden visuell geprüft und unverändert kopiert. Farbige Glas-/Segmentformen und Platzhalterfoto sind sichtbar. Dies ist Funktions-/Renderingprüfung, keine Originalpixelabnahme.

- [Flow, iPad](screenshots/flow-public-ipad.png)
- [Flow, iPhone nach 32 Sekunden](screenshots/flow-public-iphone.png)
- [Foto-Platzhalter, iPad](screenshots/photos-public-ipad.png)
- [Foto-Platzhalter, iPhone](screenshots/photos-public-iphone.png)

Quelldigest: `226a53b5c6c3a984495617f2174c44eab2593d07060529391e5202ab1caa6e12`. Dateiliste und Einzelhashes in [source-manifest.json](source-manifest.json), Screenshotdigests in [screenshots/manifest.json](screenshots/manifest.json).

Ein parallel gestarteter erster Testbundle-Build kollidierte mit dem Plattformbuild auf derselben Xcode-Build-Datenbank. Nach Abschluss der Plattformbuilds wurde er seriell erfolgreich wiederholt. Alle oben berichteten UI-Ergebnisse stammen aus dem erfolgreichen finalen Lauf.

Keine physische Hardware-, persönliche Account- oder Apple-Home-Abnahme. Apple Home bleibt gesperrt. Historische private Screenshots und Testzahlen zertifizieren diese veränderte öffentliche Kopie nicht. Rohlogs mit lokalen Pfaden werden nicht veröffentlicht.
