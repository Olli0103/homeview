# Wettercode 97 und polare Sonnenzeit-Marker

30. Oktober 2026 · begrenzter Daten-/Fixture-Schritt für [#21](https://github.com/Olli0103/homeview/issues/21), keine neue Originaleffekt- oder Geräteabnahme.

## Zwei reproduzierte Fehler

Die aktuell gelesene [Open-Meteo-WW-Tabelle](https://open-meteo.com/en/docs#weather_variable_documentation) nennt 29 Codes, darunter97: „Heavy thunderstorm“. Bisher behandelte HomeView97 als unbekannt. Damit fehlten auch das vorhandene öffentliche Gewittersymbol und die eigene Niederschlagsillustration. Jetzt gehört97 zur bestehenden Gruppe `Thunderstorms`. Keine neue Gewitterphysik oder Apple-Animation; die vorhandenen groben Wettergruppen bleiben grob, insbesondere sind Regen-/Frost-Unterarten nicht eigenständig originalgetreu umgesetzt.

Ein tatsächlicher nativer Abruf der öffentlichen Stadt **Longyearbyen** zeigte anschließend einen zweiten Fehler: Sonnenaufgang und Sonnenuntergang wurden beide als 12:00 AM dargestellt. Die unabhängig gelesene öffentliche Antwort enthält für beide denselben positiven Timestamp wie `daily.time`. Der [offizielle Open-Meteo-Quellstand](https://github.com/open-meteo/open-meteo/blob/3660b7db86435b0d816f7b6b4f350bba03fd4e99/Sources/App/Helper/Solar/SunRiseSet.swift) bestätigt die Konvention:

- Polarnacht: Tagesanfang/Tagesanfang.
- Polartag: Tagesanfang/Tagesanfang + 86.400 Sekunden.

Das sind begrenzende Tagesmarker, keine tatsächlichen Sonnenereignisse. Der Decoder liest jetzt zusätzlich die bereits gelieferte erste `daily.time` und unterdrückt ausschließlich ein daran gebundenes solches Paar. Die Oberfläche zeigt dafür **—**, nicht zwei behauptete Mitternachtsereignisse. Mitternacht allein, ein normales verschiedenes Ereignispaar oder nur ein vorhandenes Ereignis werden nicht unterdrückt. Null, fehlende/ungültige Ereignisse und der erste fehlende Tageswert bleiben weiterhin unbekannt; keine Ersetzung durch den nächsten Prognosetag.

Der aktuelle `is_day`-Wert bleibt ausschließlich der gelieferte Wert. Keine Ableitung aus fehlenden Sonnenzeiten, kein erfundener Tag-/Nachtstatus und kein AQI. Der native öffentliche Wiederholungsabruf nach Korrektur bewahrt Stadt, Quelle, Fog, Nachtstatus, Temperatur und 48 Stundenwerte; beide Sonnenzeiten sind nun unbekannt statt 12:00 AM. Beide echten Abrufe verwenden den unveränderten WeatherService mit dem jeweiligen tatsächlichen WeatherData-Decoder, ohne Ersatzparser, GPS, Schlüssel oder Konto. Keine Live-Beobachtung aller 29 Wetterzustände oder beider Polarsaisons daraus.

## Regressionen und Plattformgrenze

Sechs neue Core-Testmethoden prüfen alle 29 aktuell dokumentierten Codes jeweils tags/nachts für aktuelle und stündliche Werte, unbekannte Codes, Polartag/-nacht mit Null/fehlenden Sonnenzeiten, unbekannten Tagesstatus, Tagesmarker, normale/isolierte Ereignisse, Quellen-IANA-Zeit über DST und nicht-ganzstündige Quellen-Offsets. Keine Abhängigkeit von der Host-Zeitzone; Unix-Zeit erhält keinen zweiten Offset. Die IANA-Zonenempfehlung für DST stammt ebenfalls aus der aktuellen Anbieter-Dokumentation.

Der erste unveränderte Produktstand scheitert in genau **einer von 15 Wetter-Methoden mit zehn verletzten 97-Bedingungen**. Nach dieser Zuordnung bestehen 454 Coretests. Der anschließende, erst durch den echten Abruf entdeckte Polarfall scheitert gegen den noch unveränderten Sonnendecoder in **einer zusätzlichen Methode mit 24 verletzten Bedingungen**. Nach dem eng gebundenen Markerfix bestehen **455 aktuelle Coretests**, null Fehler. Die neue Polar-Testquelle ist vor/nach identisch; der Zwischenstand 454 ist kein zusätzlicher 455er-Lauf. Alle tatsächlichen Quellen/Testprodukte der roten, Zwischen- und finalen Stände sind separat erhalten.

Fünf aktuelle SDKs bestehen. Alle 73 App-/Widgetprodukte vollständig aus vorhandener Basis und fünf geänderten Produktdateien zurückgelesen; keine zweite Vollkopie pro Gerät. Das bestehende gemeinsame DerivedData- und das bestehende SwiftPM-Verzeichnis werden wiederverwendet. Eine reguläre iOS-Paketmetadaten-Clean-Recovery ist erhalten, keine manuell reparierten AppIntents-Dateien. Keine reale Home-/Kamera-/Mikrofon-, Konto-, Systemalarm- oder Signing-Abnahme.

## Mobile Abnahme und gebundene Dateien

**Zehn aktuelle native UI-Ausführungen / fünf Methoden je iPhone und iPad bestanden**, null Fehler/Skips/strukturierte Runtime-Warnungen. Polar-Tag/-Nachtmarker gehen durch den echten Decoder; Gewitter 97 kommt als klar synthetischer Providerwert. Bestehende Regen-/Schnee-/Demo-, fehlende Werte, veraltet/offline sowie Orts-/Einheiten-/Forecastpfade bleiben grün. Keine vorherige rote UI-Ausführung behauptet: die Fehler wurden in Core und im echten öffentlichen Abruf reproduziert.

245 Quell-/Test-/Ressourcen-/Buildeingaben unverändert durch SDK/UI, Digest `59d1403ac033652515ae3315d8dccaa24e4e20b787c0b170427d0e9e9af07648`. Alle 32 App-/Runner-/Test-/Launchinputs sowie installierte App vor/nach und Runner/Tests nachher auf beiden Geräten bytegeprüft. Neue Testinputs nur als1.135.003-Byte-Delta; neue Appbytes aus dem SDK-Delta statt doppelter Vollarchive. Sämtliche Quell-/Binäreingaben vollständig aus versiegelten Archiven rekonstruiert.

22 PNG vollständig dekodiert; alle 22 Zustände auf 4 Kontaktbögen tatsächlich gesichtet, Gewitter/Polartag/Polarnacht auf beiden Geräten zusätzlich in voller Aufnahme. Acht eigene [Bildkopien](screenshots/weather-source-edge-states-20261030/manifest.json) mit Digests veröffentlicht. Zwei terminale Ergebnisbundles mit 124 Dateien / 16.187.605 Bytes vor Ort versiegelt und vollständig zurückgelesen, ohne zusätzliche Vollkopien. Keine Vorher-/Nachher-Pixelgleichheit, Original- oder kalibrierte Kontrastabnahme daraus. [Ergebnis-/Quellen-/Archivbindung](verification/weather-source-edge-states-20261030.json).

## Noch offen

Originalwolken/-phase, Regen-/Frostformen, Schrift/Brechung, sämtliche Originalübergänge und physische Energie/Bildraten sind dadurch nicht abgenommen. AQI wird weiterhin nicht vom Forecast-Pfad geliefert und nicht erfunden. #21 bleibt offen/F019 partial/parity=false; ursprüngliche Aufgaben und Abnahme bleiben erhalten. Home-Sperre, Geräte-/Signing-Hold und Snoopy-Ausschluss unverändert.
