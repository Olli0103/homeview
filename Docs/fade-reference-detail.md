# Fade: Zeigerform, Länge und Relief

17. Oktober 2026 · [#18](https://github.com/Olli0103/homeview/issues/18) bleibt offen.

`efff917` korrigiert den sichtbaren Einzelzustand nach UI12: längerer Minuten- und
Sekundenzeiger, schmale Ansätze an der Nabe und weiches querlaufendes Zeigerrelief.
Die Ziffern sind etwas größer, schwerer und weiter außen angeordnet. Das Relief
verwendet ausschließlich öffentliche SwiftUI-Canvas-APIs und eigene Parameter.
Keine Fontkonturen oder Originalbilder werden gebündelt. Andere Analoguhren
behalten ihre bisherigen Standardlängen und flachen Zeiger.

## Nachweis

103 Modelltests, drei gezielte UI-Fälle je iPad/iPhone (sechs Ausführungen) und
fünf SDK-Builds bestanden. Die UI-Prüfung umfasst zwei eigene Fade-Phasen,
Reduce Motion und die unveränderte alternative Home-Analoguhr mit Thermostat.
103 Modelltests nach Codecommit erneut bestanden; identische 116 Quellen vor/nach
Prüfung und gegen den Commit verifiziert. Keine UI-Fehler, Skips oder von XCTest
gemeldeten Runtime-Warnungen. Das ist keine neue vollständige UI-Suite.

Die tatsächlichen eigenen Bilder wurden auf beiden Simulatorgrößen gesichtet.
Ein früherer breiter Zeiger bis zur Nabe wurde im Bildvergleich verworfen und vor
diesem Prüfstand durch den schmalen Ansatz ersetzt. Die Tests vergleichen
veränderte/verharrende dekodierte Pixel, nicht nur verschiedene PNG-Dateien.

[Quellen und Ergebnisse](verification/fade-reference-detail.json) ·
[eigene Bilder und Digests](screenshots/goal-20261017/fade-detail-manifest.json).

## Grenze

Der Einzelzustand ist näher an der Vorlage, aber die exakte Originalzeitkurve,
weitere Stunden-/Minutenübergänge, Licht, Schriftform und physische Leistung sind
nicht abgenommen. Die eigene vorhandene Ausblendfunktion wird durch diese
Geometriekorrektur weder als Apple-Algorithmus bestätigt noch ersetzt. Kein
Original-PASS und kein Abschluss des fortlaufenden Gesamtauftrags.
