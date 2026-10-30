# Öffentlicher nativer Prüftreiber

`WeatherPublicProbe.swift.txt` ist der exakt verwendete eigene CLI-Treiber, außerhalb aller normalen App-/Testtargets. Er wird gemeinsam mit dem jeweiligen `Sources/App/WeatherService.swift` und `Sources/Core/WeatherData.swift` kompiliert. Bei ausdrücklicher manueller Ausführung fragt er nur die öffentliche Stadt Longyearbyen ab; keine Ortung, Konten oder Home-Initialisierung. Alte und korrigierte Decoder-Binärstände wurden getrennt erhalten. Das ist kein vollständiger Wetter-/Original-/physischer Abnahmetreiber.
