# Weltuhr: Tagesverlauf nicht jede Sekunde neu berechnen

31. Oktober 2026 · Softwarearbeit an [#53](https://github.com/Olli0103/homeview/issues/53).

Die Weltuhr erzeugt bei jeder Modellzeit-Aktualisierung neue Lesewerte. Ihr
Sonnenverlauf tastete dabei denselben lokalen Kalendertag erneut ab, obwohl
sich innerhalb dieses Tages weder Koordinaten noch die Berechnungsgrundlage
ändern. Uhrzeit, UTC-Offset und der aktuelle Tageslichtstatus dürfen dagegen
nicht für einen ganzen Tag eingefroren werden.

Nur das abgeschlossene `DaylightWindow` wird nun in Foundations vorhandenem
`NSCache` gehalten. Der Schlüssel umfasst exakte Koordinaten, Zeitzonenkennung
und **beide tatsächlichen Grenzen des lokalen Tages**. Dadurch bleiben DST-Tage
mit 23/25 Stunden, lokaler Tageswechsel, Datumsgrenze und geänderte Standorte
getrennt. Die Solarformeln, Abtastung und Horizontsuche sind unverändert.

Der Cache hält unveränderliche Werte, ist nebenläufig verwendbar, flüchtig und
nicht persistent. Die konfigurierte Grenze von 64 Einträgen ist ein nativer
Cache-Hinweis, keine harte Speicherquote. Verdrängung oder konkurrierende
Cache-Misses dürfen lediglich erneut rechnen; sie verändern keine Ergebnisse.
Unbekannte Koordinaten liefern weiterhin keinen erfundenen Sonnenstand.

## Begrenzter Nachweis

[Quellen, Messwerte und Grenzen](verification/world-clock-computation-20261031.json).

- 17 Weltuhr-Coretests vor und nach Änderung bestanden. Zusätzliche Fälle prüfen
  DST-Tageslängen, Mitternacht, verschiedene Orte innerhalb derselben Zone,
  Zonenwechsel und unbekannte Koordinaten.
- Derselbe optimiert kompilierte native Prüftreiber rechnet je Durchlauf 1.512
  angeforderte Fenster: 21 kuratierte/ausdrücklich synthetische/koordinatenlose
  Standorte × sechs Datumsfälle × zwölf Sekundenpositionen. Drei Durchläufe je
  Binärstand, **identische vollständige Ergebnis-Digests**; keine 1.512
  unterschiedlichen Kalendertage behauptet.
- Je Stand 216 nebenläufige Zusatzvergleiche stimmen mit den seriellen Werten
  überein. Die Matrix enthält Polarzustände, DST, Mitternacht, gebrochene Offsets
  und Apias ausgelassenen Kalendertag.
- Median des begrenzten Rechenlaufs: vorher **166,452 ms**, nachher **18,424 ms**
  (rund 9,0×). Erster Cache-Durchlauf 25,444 ms, folgende 18,424/17,609 ms.
  macOS 27.0.1/26A434, arm64, Apple Swift 6.4, `-O` und Sprachmodus 6.

Das ist **keine** Messung von Gesamt-App-CPU/GPU, Speicherbedarf, Bildrate,
Batterie, langfristigem Betrieb oder physischen Zielgeräten. Der absolute
Zeitgewinn dieses kurzen Rechenlaufs wird nicht in eine Akkuersparnis umgerechnet.
Keine neue UI-/Pixel-/Fokusprobe; Oberflächen und Ressourcen sind unverändert.

Der reproduzierbare [Prüftreiber](../Tests/NativeProbes/WorldClockComputationProbe.swift)
wird zusammen mit `Sources/Core/WorldClock.swift` durch
`xcrun swiftc -O -parse-as-library -swift-version 6` kompiliert. Vorher-/Nachher-
Quellen und beide tatsächlichen Probe-Binärdateien bleiben gebunden erhalten.
Quell-/SDK-Archivdeltas werden gegen das bytegeprüfte vorherige Fotopaket
vollständig rekonstruiert, statt unveränderte Ressourcen erneut zu archivieren.

Alle fünf SDK-Ziele bestanden. 263 Quellinputs und 73 Produktdateien sind
aus dem bytegeprüften Fotopaket und den neuen Deltas vollständig rekonstruiert
und zurückgelesen: nur drei Quell- und sechs Produktdateien neu archiviert.
Der erste Rechenlauf bleibt als früherer Versuch erhalten; die oben genannten
finalen Messwerte stammen aus dem separat vor/nach binärgebundenen Paar.

**#53 bleibt OPEN.** Die fehlende konkrete Originalansicht/-kurve, Genauigkeit
einer Ephemeride und physische Abnahme werden dadurch nicht nachgewiesen.
Auch #81 ist keine erledigte Leistungs-/Energieabnahme. Home-/Geräte-/Signing-
Hold unverändert; keine Systemzeit, Zone, Ortung oder persönlichen Daten geändert.
