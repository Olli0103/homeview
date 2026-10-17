# Wetter-Glasziffern nach UI05

17. Oktober 2026 - [#21](https://github.com/Olli0103/homeview/issues/21).

Die Produktreferenz UI05 zeigt durchscheinende Glasziffern, kein nahezu deckendes
weiß-blaues Textgefälle. Dieser Schritt ersetzt die bisherige Füllebene durch
einen eigenen öffentlichen Layer-Shader auf normalem Systemtext.

- Hintergrund und Ziffern verwenden dasselbe eigene Wolkenfeld und dieselbe
  Bewegungsphase. Die Textposition wird im gemeinsamen 600-Punkte-Koordinatenraum
  abgebildet; Maskengradienten erzeugen eine eigene Randnormale und begrenzte
  Hintergrundbrechung. Dezente Reflexe und eine helle Körpertönung bleiben sichtbar.
- Nur die zur Laufzeit gerenderte Alpha-Maske des Systemtexts wird abgetastet.
  Keine gespeicherten/extrahierten Schriftkonturen, privaten Frameworks oder
  proprietären Originalshader werden eingebettet. Die eigene Flow-Materialtechnik
  und der vorhandene Wetterhimmel werden weiterverwendet, kein neues Fremdpaket.
- Temperaturhöhe, vertikale Platzierung und das kleinere, separat hochgestellte
  Gradzeichen folgen dem beobachteten UI05-Aufbau. Wolkenform und Licht bleiben
  abweichend; der Feldverlauf ist keine Rekonstruktion von Apples Originalalgorithmus.
- Die ausdrücklich markierte Demo verwendet AQI 21 aus dem beobachteten UI05-Beispiel,
  wie bereits die Demo-Werte 54 Grad, 7 mph und 76 Prozent. Verbundene Daten erhalten
  weiterhin keinen erfundenen AQI: der vorhandene Anbieter liefert ihn nicht, also
  bleibt der Wert dort unbekannt. Die doppelte Demo-Angabe im Zustandstext entfällt;
  die separate Demo-/Quellenzeile bleibt sichtbar.

## Prüfung

[Quellenbindung und Resultate](verification/weather-glass.json) -
[eigene Simulatorbilder und Digests](screenshots/iteration-20261017-block2/weather-glass-manifest.json).
Gezielte Tests prüfen die unterschiedlichen Demo-/Verbindungswerte, die Bewegung
und den exakten Stillstand der dekodierten Ziffern-/Himmelsregion bei Reduce Motion,
die unveränderte eigenständige Wetter-App, 0 Prozent Bedeckung, unbekannte Werte,
Nacht/offline und die Navigation vom Zifferblatt zur App. Keine echten Accounts
oder Smart-Home-Geräte werden dafür benutzt.

Ein vorläufiger einzelner Simulatorlauf wurde mit Signal kill beendet. Ein
nachfolgender Prototyplauf bestand; das erklärt nicht die Ursache des Abbruchs.
Beide sind getrennte private Arbeitsbelege, keine finalen Produktnachweise.
Die Endquelle bekommt einen eigenen eingefrorenen Lauf auf beiden Simulatoren.

[Eigener Vorher-/Nachher-Vergleich](screenshots/iteration-20261017-block2/weather-glass-own-before-after.png) - [Bildherkunft](verification/weather-glass-comparison.json).

**99 Modelltests, sieben gezielte UI-Fälle je iPad/iPhone (14 Ausführungen) und fünf
SDK-Builds bestanden auf denselben eingefrorenen Quellbytes.** Null Fehler, Skips
oder von XCTest gemeldete Runtime-Warnungen. Kein neuer vollständiger UI-Suite-PASS.

## Originalgrenze

**#21 bleibt offen.** Form-/Lichtdetails, die genaue Brechung, Himmel-/Wetterphasen,
weitere Temperaturen/Einheiten/Zustände und physische Leistung sind nicht als
Original akzeptiert. Eine bewegte Ziffernregion beweist weder Originalbewegung noch
korrekte physikalische Optik. Die gemeinsame eigene Illustration ist kein
astronomischer oder energievalidierter Wetterrenderer. Weitere Geräteplattformen
werden kompiliert, nicht pauschal zur Laufzeit abgenommen.
