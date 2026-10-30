# Wetterdaten, CAMS-AQI und Zustandsabnahme · #21

30. Oktober 2026. Abschlussorientierte Prüfung des unveränderten ursprünglichen Daten-/Wetterzustandsvertrags; keine pauschale Abnahme von F019 oder der exakten Apple-Animationen.

## Tatsächliche Änderung

Der vorhandene Forecast-Abruf wird nach demselben Geocoding um den dokumentierten öffentlichen Air-Quality-Endpunkt ergänzt. Ein europäischer Index wird nicht mit US-AQI oder Prozenten verwechselt. Die Quelle ist ein CAMS-Modell über Open-Meteo, kein lokaler Luftsensor. Eigenständiger positiver Quellenzeitpunkt, finite nichtnegative Werte und separate Altersprüfung; keine Ersatzwerte für fehlende, Null-, negative oder ungültige Felder. Werte oberhalb100 bleiben zulässig. Ein fehlgeschlagener optionaler Abruf verwirft den nutzbaren Forecast nicht; Abbruch bleibt Abbruch. Ephemere Sessions, fester HTTPS-Host, keine Accounts, Schlüssel oder Ortung. Acht Sekunden URLRequest-Timeout, keine gesonderte absolute Gesamtlaufzeitgarantie.

Face und Wetter-App zeigen den gelieferten Wert als EU AQI. Quelle/Modellzeit und gegebenenfalls Outdated stehen separat da; die App nennt CAMS ENSEMBLE/CAMS global sowie die Datenquellen. Ein fehlender AQI bleibt — / AQI not supplied. Das ausdrücklich markierte synthetische Demo-Beispiel21 ist keine reale Luftmessung. In der Wetter-App bleiben weitere Bedingungen im vorhandenen ScrollView erreichbar; nicht alle Forecast-/Sonnenfelder sind gleichzeitig auf einer Bildschirmseite sichtbar.

## Daten- und Fehlergrenzen

457 Coretests auf dem dokumentierten Checkpoint; zusätzliche AQI-Tests prüfen unter anderem Null/fehlend/negativ, Nullzeit, falsche Typen, unabhängig veraltete/future-validity Daten und Werte oberhalb100. Die bestehenden Tests decken alle29 aktuell dokumentierten WW-Codes jeweils tags/nachts für aktuelle/stündliche Bedingungen, unbekannte Codes, fehlende Metriken, Einheiten, IANA/DST, polare Tagesmarker sowie Quellen-/Ortswechsel ab.

Sechs isolierte native URLProtocol-Szenarien verwenden den echten WeatherService, Decoder und ausschließlich eigene Antworten: Erfolg, optionales HTTP503, ungültiges JSON, fehlender Index, Abbruch und fehlgeschlagener Forecast. Unveränderte Werte/Zeitpunkte, exakte Anfragefolge und achtsekündige Requestkonfiguration sind geprüft, keine Live-Anfrage in diesen Tests. Ein separates natives Programm ruft tatsächlich das öffentliche Wetter und CAMS für Berlin ab. Reale Antwort und Quellenzeiten sind separat erhalten; kein Live-Nachweis sämtlicher Wetterzustände.

## Native Zustände

**Zehn aktuelle native UI-Ausführungen bestanden**, fünf je iPhone18Pro/iPadAirM4, keine Fehler/Skips/strukturierten Runtime-Warnungen. Neun Klassen × Tag/Nacht × zwei Geräte ergeben36 Zustandskombinationen und72 Face-/App-Zustände. Jede Kombination kommt durch den echten Decoder, normalen Connect-/Updateweg und tatsächliche Navigation; Uhr, Temperatur, Wind, Feuchte, Sonnenuntergang und unbekannter AQI bleiben innerhalb des Displays. Bekannte/fehlende/veraltete AQI-Werte, Demo-Trennung und Einheiten sind zusätzlich geprüft. Eigene Niederschläge/Frostränder verdecken die wichtigen Werte in den gesichteten Zuständen nicht. Keine vollständige Motion-/WCAG-/Originalabnahme daraus.

170 nativePNG vollständig dekodiert;88 ausgewählte Zustandsbilder auf16 Kontaktseiten tatsächlich gesichtet. Die sieben Bedingungsgruppen sind nicht sieben vollständig verschiedene Animationsmodelle: Regen und Gewitter teilen die eigene Partikeldarstellung, Wolkenbedeckung steuert mehrere Bedingungen. Keine29Originalanimationen behauptet. Weitere zwölf erfolgreiche mobile Ausführungen gehören zum klar getrennten vorherigen AQI-Prüfstand, nicht zu einer finalen22er-Suite.

246 eingefrorene Quell-/Test-/Ressourcen-/Buildeingaben sind dem Codecommit exakt gleich;32 kompilierte App-/Runner-/Test-/Launchdateien und installierte Bytes vor/nach beiden Geräten geprüft. Fünf finale SDKs,73 Produktdateien vollständig archiviert/zurückgelesen, unveränderte Dateien nicht pro Gerät verdoppelt. Ein regulärer iOS-Metadaten-Clean-Build ist protokolliert. [Ergebnisse und Abgrenzung](verification/weather-air-quality-20261030.json), [Source-Pin](verification/weather-air-quality-source-20261030.json), [eigene Bildherkunft](screenshots/weather-air-quality-20261030/manifest.json).

### Zurückgenommene Sichtungsannahme

Eine verkleinerte Kontaktseite wurde zunächst fälschlich als Headerüberlappung gelesen. Die vollständige native1134px-Aufnahme zeigt die vollständige getrennte Uhr. Eine zusätzliche, exakt erhaltene Drei-Zustands-Probe bestätigt positive Abstände auf beiden Geräten. Die zusätzliche absolute Pixelidentitätsforderung besteht nur auf dem iPhone; beim iPad scheitern zwei Assertions mit je347RGBA-Bytes, bei beobachteten0,075791Punkten Clock-Y-Unterschied zwischen unterschiedlichen Inhaltsposen. Dieser Vergleich ist dafür unqualifiziert, wird nicht nachträglich grün erklärt und begründet keinen exklusiven Produktfehler. Exakte Probe/Inputs/Bilder bleiben separat erhalten; sie ist kein neuer grüner Regressionstest. **Kein Header-Produktcode wurde geändert**, die normalen Tests wurden bytegenau auf den tatsächlich bestandenen Matrixstand zurückgesetzt. Künftige Kontaktseitenbefunde zuerst an nativer Originalauflösung und der tatsächlichen Geometrie prüfen.

## Ursprünglicher Vertrag und unveränderte Parity-Grenze

Die ursprünglichen Aufgaben/Kriterien bleiben wortgleich erhalten: Wetterdaten einschließlich Luftqualität/Sonnenzeiten mit Quellenzeit; keine erfundenen fehlenden Werte; eigene Wettereffekte und Tageszeitvarianten; Offline/Alter/Ort/Einheiten; vollständige Zustandsfixtures plus separater öffentlicher Abruf und keine verdeckten wichtigen Daten. Dieser ursprüngliche Daten-/Zustandsvertrag ist mit den oben begrenzten Belegen erfüllt. Es wird kein ursprüngliches Kriterium gelöscht oder durch eine vollständige Original-/Hardwarebehauptung ersetzt.

Die vorhandene Implementierung fasst WMO-Unterarten in sieben Darstellungsgruppen zusammen. Die Matrix prüft diese tatsächlich unterschiedlichen eigenen Renderzustände plus Frost und unbekannte Bedingungen, nicht29 verschiedene originale Apple-Animationen. Regenpartikel, Frost, Glas, Wolken, Schrift und Übergänge sind weiterhin keine vollständig belegte Originalkopie; F019 bleibt partial/parity=false. Visuelle Gesamt-Parity bleibt #78, physische Energie/Framezeiten #81. Keine neue Originalansicht aus der erneuten begrenzten Textrecherche, keine Originalbilder/privaten Bibliotheken im Repository. Home-Sperre, Geräte-/Signing-Pause und Snoopy-Ausschluss bleiben unverändert.

## Reproduktion

`swift test --disable-automatic-resolution`; SDKs über `Scripts/build_platforms.py`. Der isolierte native Transport ist in `Tests/NativeProbes/WeatherAirQualityTransport.swift` enthalten und wird mit dem echten `WeatherData.swift`/`WeatherService.swift` kompiliert. Native Auswahl: `testWeatherIllustrationMatrixDayKeepsEveryMetricVisible`, `testWeatherIllustrationMatrixNightKeepsEveryMetricVisible`, `testWeatherEuropeanAirQualityKeepsSourceTimeAndUnavailableFallbackSeparate` sowie die bestehenden Missing-/Demo-Fälle. Keine reale persönliche Quelle verbinden.
