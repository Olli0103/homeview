# Wetterlicht und Glasmaterial nach UI05

17. Oktober 2026 · [#21](https://github.com/Olli0103/homeview/issues/21).

Der direkte UI05-Vergleich zeigte einen zu dunklen unteren Himmel und zu dunkle
Glaskörper. Der vorhandene eigene Renderer erhält einen helleren unteren
Tagesverlauf, eine hellere durchscheinende Ziffernfläche und schmalere helle
Randreflexe. Die gemeinsame Himmelsfunktion wird nun vom Hintergrund und von der
gebrochenen Ziffernansicht benutzt. Damit existieren keine getrennten SwiftUI- und
Metal-Kopien derselben Farbpalette mehr. Wolkenform, Bewegungsphase und Geometrie
sind gegenüber dem vorherigen Glas-Schritt unverändert.

Die erste Kalibrierung erzeugte zu starke Eckreflexe. Ihre separaten Prototyptests
und Builds gelten nur für diesen Zwischenstand. Vor der Endprüfung wurden die
breiten Spitzlichter zurückgenommen; der endgültige Stand wird getrennt geprüft.
Die Nacht behält ihre bisherige Himmelspalette und geringere Glaskörpertönung.

[Eigener Vorher-/Nachher-Vergleich](screenshots/iteration-20261017-block2/weather-light-own-before-after.png) ·
[Bildherkunft](verification/weather-light-comparison.json) ·
[Quellen und gezielte Ergebnisse](verification/weather-light.json) ·
[eigene Testbilder mit Digests](screenshots/iteration-20261017-block2/weather-light-manifest.json).

## Ergebnis des eingefrorenen Stands

Codecommit `2e13843`: 99 Modelltests, neun gezielte UI-Fälle je iPad/iPhone (18 Ausführungen) und fünf
SDK-Builds bestanden. Null Fehler/Skips oder von XCTest gemeldete Runtime-Warnungen.
Kein neuer vollständiger UI-Suite-PASS. Alle 113 erfassten Quelldateien blieben vor
und nach den Prüfungen identisch. Nach dem Codecommit erneut 99 Modelltests bestanden.

Die dekodierten, vorab festgelegten Ziffern-/Himmelsregionen ändern sich im bewegten
Positivfall auf beiden Geräten. Bei Reduce Motion sind in beiden Regionen auf
beiden Geräten exakt null RGBA-Kanäle verändert. Sichtprüfung von Demo-Face,
Stadtansicht, Nacht und klarem Himmel auf beiden Simulatoren abgeschlossen.
Unbekannte Werte bleiben unbekannt; der beobachtete Demo-AQI 21 wird weiterhin
nicht als verbundener Messwert ausgegeben. Regen/Schnee, Nacht/Offline,
Einheiten und die Navigation zur separaten Wetter-App bestehen ihre gezielten Tests.

## Prüfgrenzen

Eine begrenzte, vor der finalen Bildauswertung festgelegte freie Himmelsregion aus
UI05 dient als zusätzliche Farbreferenz. Die medianen 8-Bit-RGB-Werte sind näher
an dieser Produktgrafik; das ist weder eine kalibrierte Farbmessung noch ein
Originalpixel-PASS. Der private Originalvergleich wird nicht mit veröffentlicht.

Die eigene öffentliche Metal-/SwiftUI-Implementierung verwendet weiterhin nur
Laufzeit-Systemtextmasken. Keine Originalgrafiken, extrahierten Apple-Schriftformen,
privaten Frameworks oder Originalshader werden eingebettet; kein neues Fremdpaket.

**#21 bleibt offen.** Wolkenkonturen, gerichtetes Sonnenlicht, genaue Lichtbrechung,
weitere Originalzustände und physische Leistung bleiben unakzeptiert. Automatische
Tests verwenden ausschließlich synthetische Daten und MockHome. Echte Homes und
persönliche Accounts werden nicht angesprochen.
