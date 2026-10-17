# Kleine Analoguhr im Home-Raster

17. Oktober 2026 · [#19](https://github.com/Olli0103/homeview/issues/19), weiterhin offen.

`27dde45` korrigiert die sichtbare Zeigergeometrie der kleinen Home-Raster-Uhr nach
UI13: kürzerer Stundenzeiger, längerer Minutenzeiger, schmale Ansätze und öffentliches
Canvas-Relief. Der neue optionale Stundenradius behält für alle anderen Uhren den
bisherigen Standard 0,56 bei; nur dieses Raster nutzt 0,50. Minutenradius 0,94 statt
0,84. Die Zeitrechnung und MockHome-Zustände werden nicht durch gemalte Fixwerte
ersetzt. Keine System-/HomeKit-Freigabe oder proprietären Assets.

## Integrierter Nachweis

Merge `b874075`: 104 Modelltests, drei gezielte UI-Fälle je iPad/iPhone (sechs
Ausführungen) und fünf SDK-Builds bestanden. 116 Quellen vor/nach Prüfung und gegen
den Mergecommit identisch. Keine UI-Fehler/Skips oder von XCTest gemeldeten Runtime-
Warnungen. Nach Featurecommit erneut 104 Modelltests. Keine neue vollständige Suite.

Die Auswahl zeigt fünf Face-Varianten und das Home-Raster, prüft tatsächliche
Thermostat-Navigation aus der Uhr sowie 68°→69° im Mock und enthält die alternative
Home-Analoguhr und Numerals-/Fade-Referenzzustände als Shared-Clock-Regression.
Die Referenzaufnahme wird vor dem Licht-Toggle gesichert; das bisherige Bild nach
dem Toggle bleibt ein eigener Interaktionszustand, kein identischer Originalfall.
Eigene Bilder beider Simulatorgrößen gesichtet.

[Quellen und Ergebnisse](verification/home-grid-clock.json) ·
[eigene Bilder und Digests](screenshots/goal-20261017/home-grid-clock-manifest.json).

## Weiter offen

Exakte Originalschrift/Lichtführung, weitere Uhrzeiten/Varianten und reale
Hardware-/Home-Abnahme bleiben offen. Die bisherige Kamerafläche ist in diesem
Prüfstand noch eine klar synthetische Vektorszene; eigene generierte Demo-Standbilder
werden getrennt integriert. Kein Original-PASS und kein Ende des Gesamtauftrags.
