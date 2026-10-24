# Weltuhr: vollständige Zonenwahl und Tag-/Nachtverlauf

Datum: 24. Oktober 2026. Bezug: [DAY-07 / #53](https://github.com/Olli0103/homeview/issues/53), F068.

## Ausgangslage

Die Weltuhr kannte 17 kuratierte Städte mit Koordinaten. Nicht kuratierte Zonen ließen sich weder wählen noch speichern; ein Tagesverlauf fehlte vollständig. Die Sonnenhöhe war bereits als eigener Offline-Näherungswert vorhanden, aber nur als aktuelles Hell/Dunkel sichtbar.

## Umsetzung

- **Zonenwahl:** `WorldCity.allZones` bildet alle `TimeZone.knownTimeZoneIdentifiers` der laufenden Plattform ab. Kuratierte Städte behalten Anzeigename und Koordinaten; alle übrigen Zonen erhalten einen aus dem letzten Identifier-Teil abgeleiteten Namen (`America/Argentina/Buenos_Aires` → "Buenos Aires", Unterstriche werden zu Leerzeichen) und **keine** Koordinaten.
- **Speichergrenze:** `WorldCity.normalized` akzeptiert jetzt jede von der Plattform bekannte Zone, dedupliziert und begrenzt weiterhin auf zwölf Einträge. Unbekannte Identifier werden verworfen. `AppModel.addWorldCity` prüft dieselbe Bedingung, die Obergrenze von zwölf und die Doppelung.
- **Keine erfundene Sonne:** Für Zonen ohne Koordinaten liefert die Uhr `daylight == nil` und `DaylightWindow.unavailable`; die Oberfläche zeigt "No sun position for this time zone." und "Currently light unknown" statt eines geratenen Werts.
- **Tag-/Nachtverlauf:** `DaylightWindow.compute` tastet den lokalen Kalendertag der Stadt in 10-Minuten-Schritten ab, sucht Vorzeichenwechsel der Sonnenhöhe gegen −0.833° und verfeinert jede Kreuzung mit 24 Bisektionsschritten. Ergebnis sind Aufgangs-/Untergangszeitpunkt und deren Lage im Tag als Bruchteil 0…1. Polartag und Polarnacht werden als eigene Art gemeldet, wenn keine Kreuzung existiert.
- **Detailansicht:** Antippen einer Stadt öffnet ein Sheet mit großer Uhrzeit, Datum, UTC-Offset, Tagesdifferenz und einem Balken von Nacht zu Tag. Der Balken nutzt ausschließlich die berechneten Bruchteile; ohne Koordinaten bleibt er neutral grau.

## Nachweise (24. Oktober 2026)

- 395 Coretests ohne Fehler, davon elf Weltuhr-Methoden (vier neu).
- Fünf Plattform-Builds: iOS, macOS, tvOS, visionOS, watchOS bestanden.
- Vier UI-Ausführungen: zwei Fälle auf iPhone 18 Pro (35,9 s / 44,7 s) und zwei auf iPad Air 11-inch M4 (37,2 s / 45,1 s), alle bestanden.
- Zwei Fehlschläge desselben neuen Falls sind erhalten: eine falsche Texterwartung im Test und ein vom Container vererbtes Accessibility-Identifier, das den Done-Knopf überschrieb. Beide Ursachen sind benannt und behoben, die Erwartungen wurden nicht gelockert.
- Detailansichten als PNG aus den bestandenen Läufen exportiert und gesichtet: Sydney mit Tagesbogen zwischen 07:06 und 18:52, Shanghai ohne Sonnenstand.
- Rohdaten: [verification/world-clock-zones-daylight.json](verification/world-clock-zones-daylight.json).

## Grenzen

- Die Sonnenhöhe bleibt das bisherige Modell niedriger Ordnung (NOAA-Näherung), keine Ephemeride, keine Refraktion, keine Höhenlage, kein Wetter. Aufgangs-/Untergangszeiten sind daher Näherungen im Bereich weniger Minuten, nicht sekundengenau.
- Zonen ohne kuratierte Koordinaten zeigen bewusst keinen Tagesverlauf. Eine echte Koordinatenquelle wäre eine eigene, zu belegende Ergänzung.
- `allZones` hängt an der Zonenliste der laufenden Plattform; ein geräteübergreifend identischer Katalog ist nicht garantiert und wird nicht behauptet.
- Keine Originalabnahme von Apples Weltuhr-Detailansicht; Layout, Typografie und Balkenform sind eigene Näherungen. F068 bleibt `parity_accepted: false`.
