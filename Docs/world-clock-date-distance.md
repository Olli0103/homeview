# Weltuhr: tatsächlicher Abstand zwischen Kalendertagen

20. Oktober 2026 · Teilkorrektur von [#53](https://github.com/Olli0103/homeview/issues/53).

## Fehler

Am Zeitpunkt **1. Januar 2026, 11:30 UTC** ist es in der Referenzzone UTC−12 noch **31. Dezember, 23:30**, in Auckland mit UTC+13 dagegen bereits **2. Januar, 00:30**. Die lokalen Kalenderdaten liegen zwei Tage auseinander, obwohl nur 25 Stunden Zeitzonenabstand bestehen.

Das vorhandene Modell berechnet korrekt `dayDifference = 2`. Die Oberfläche verwendete jedoch für jede positive Differenz nur **Next day**. Ein neuer Fall fügt Auckland über den echten Städte-Picker hinzu und scheitert gegen unveränderten Produktcode auf iPad und iPhone genau an der fehlenden Beschriftung **2 days ahead**. Die Vorherbilder zeigen das falsche Next day unter dem Datum 2. Januar.

## Korrektur

`WorldClockReading.dayRelation` liefert bei gleichem Datum keinen Zusatz, bei ±1 unverändert **Previous day/Next day** und sonst den tatsächlichen Tagesabstand **N days ahead/behind**. WorldClockView verwendet diesen Wert im bisherigen Textstil. Die Stundenberechnung, IANA-Zonen, Sommerzeit, UTC-Offsets, Datumsformatierung, Auswahl/Persistenz und Sonnenstandsschätzung bleiben unverändert.

Zwei neue Modellfälle prüfen den konkreten Auckland-/UTC−12-Jahreswechsel, die bisherigen Einzeltag-/Gleichtag-Fälle sowie die entgegengesetzte Datumsgrenze. Die negative Zweitages-Grenze verwendet bewusst eine synthetische IANA-Stadt für UTC−12 gegenüber Kiritimati; sie ist **keine neue auswählbare Stadt** im kuratierten Katalog.

## Gegenprüfung und Grenzen

Der vollständige Core-Lauf umfasst 293 Tests mit zwei neuen Fällen. Die vier finalen UI-Ausführungen prüfen den neuen Zweitagesfall und den bestehenden Kathmandu-/Neustart-/Entfernen-Fall auf iPad und iPhone. Die zwei früheren UI-Fehler bleiben als Vorherbefund dokumentiert, nicht als finale Fehler versteckt. Fünf SDK-Builds, gebundene Quellen/App-/Test-/Launch-Eingaben, installierte Appbytes und Archive stehen im [Ergebnisbericht](verification/world-date-distance.json).

Eigene Bilder werden dekodiert und gesichtet. Der geänderte Datumszusatz ist sichtbar; eine unveränderte ganze Weltuhr-Pixelmatrix wird nicht behauptet. Dies ist keine neue Genauigkeits- oder Originalabnahme des Sonnenzeitverlaufs.

**#53 bleibt offen** für Originalgeometrie und den belegten Tag-/Nachtverlauf. F068 erhält dadurch keine vollständige Parity-Abnahme. Keine Geräteortung, Konten, Kalender, Kamera, Mikrofon, Systemalarme oder neuen System-Live-Activities; **keine Home-Anbindung**.
