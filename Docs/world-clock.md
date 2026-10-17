# Weltuhr: Zonenwahl und lokale Tageszustände

17. Oktober 2026 · [DAY-07, #53](https://github.com/Olli0103/homeview/issues/53).

Bis zu zwölf Städte aus einem kuratierten Katalog lassen sich hinzufügen, suchen und entfernen. Gespeichert werden eindeutige IANA-Zonenkennungen; keine festen UTC-Offsets. Leere Listen bleiben bei Neustart leer, alte Speicherstände erhalten die vier bisherigen Standardstädte. Unbekannte, doppelte und überzählige Kennungen werden beim Laden begrenzt.

Jede Zeile zeigt lokale Uhrzeit, Datum, aktuell gültigen UTC-Offset und gegebenenfalls den vorigen/nächsten Tag relativ zur Anzeigezone. Foundation berücksichtigt die Zeitzonenregeln des installierten Betriebssystems, einschließlich halber/viertel Stunden, verschiedener DST-Wechseltage und südlicher Sommerzeit.

Der Sonnen-/Mondindikator ist eine **offline berechnete Tageslichtschätzung**, kein Wetterdienst und keine Mondphase. Er verwendet Stadtkoordinaten und das [NOAA-Modell für Sonnenpositionen](https://gml.noaa.gov/grad/solcalc/solareqns.PDF), am 17. Oktober 2026 gelesen. Die Berechnung berücksichtigt den Sonnenhöhen-Grenzwert −0,833°. Polartag und Polarnacht werden nicht durch feste Uhrzeitgrenzen ersetzt. Nahe dem Sonnenauf-/untergang ist dies eine Näherung, keine Ephemeridenabnahme.

## Prüfgrenzen

Die Corefälle prüfen Kathmandu/Delhi, Adelaide, unterschiedliche europäische/amerikanische DST-Regeln, Datumsgrenzen, ausgelassene/doppelte Stunden, Polartag/-nacht und Speichermigration. Der synthetische UI-Fall fügt Kathmandu hinzu, kontrolliert 15:54 zur eingefrorenen UTC-Referenzzeit, startet neu, entfernt die Zone und prüft den nächsten Neustart.

Referenzgeometrie und ein originaler animierter Sonnenzeitverlauf bleiben eine gesonderte offene Sichtabnahme. Es werden weder Geräteortung noch Kalender, Konten oder Hausgeräte abgefragt.

61 Modelltests, der beschriebene UI-Fall auf iPad und iPhone sowie fünf SDK-Builds bestanden. [Quellenbindung und Ergebnis](verification/world-contained.json). Die Prüfung deckte außerdem eine zunächst fehlende Touchfläche im Städte-Picker und eine vererbte Accessibility-Kennung auf; beide sind korrigiert.
