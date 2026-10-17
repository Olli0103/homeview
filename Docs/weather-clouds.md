# Strukturierter Wetterhimmel nach UI20

17. Oktober 2026 - [#21](https://github.com/Olli0103/homeview/issues/21).

Der vorige Layoutschritt trennte die Wetter-App vom Wetter-Zifferblatt. Der Himmel
bestand weiterhin aus stark unscharfen Ellipsen und traf die plastischen Wolken der
Originalreferenz nicht. Dieser eigene Renderer ersetzt diese Flecken durch ein
begrenztes Volumenfeld mit Konturen, Eigenverschattung und Tages-/Nachtfarbe.
Die Quelle ist weiterhin der vorhandene Open-Meteo-Adapter; kein weiterer Abruf
oder Account ist erforderlich.

## Herkunft und Grenzen

- Eigener Metal-Code mit Wert-Rauschen, glatter Interpolation, fünf Frequenzanteilen
  und höchstens 16 Tiefenproben pro Pixel. Nur öffentliche SwiftUI/Metal-APIs.
  Keine extrahierten Apple-Texturen, Originalshader, privaten Frameworks oder
  neuen Paketabhaengigkeiten. Inferno wurde kurz als vorhandene MIT-Bibliothek
  geprüft, bietet aber keinen passenden Wolkenrenderer; kein Code daraus kopiert.
- Wolken bleiben im oberen Himmel. Gemeldete 0 Prozent Bedeckung umgehen das
  Wolkenfeld vollständig. Wenn die Quelle keine Bedeckung liefert, ist die aus
  dem Zustand gewählte Schicht nur Illustration, kein erfundener Messwert.
- Schrift erhält dezente eigene Schatten, damit Ortsname, Temperatur und Uhrzeit
  auch vor hellen Wolken lesbar bleiben. Form und Stärke sind noch nicht exakt
  gegen die Originallichtfuehrung abgenommen.
- Bewegung folgt dem vorhandenen MotionTimeline-Pfad: reduzierte Bewegung,
  inaktive Szene und normale Screenshot-Fixtures stehen still. Die Sonnenaufhellung
  ist eine Illustration, keine berechnete reale Sonnenposition.
- Tippen auf das Wetter-Zifferblatt öffnet jetzt die getrennte Wetter-App. Dieser
  App-Pfad wird funktional geprüft; die genaue Originalgeste bleibt separat offen.

Die ersten Prototypen wurden nach Sichtprüfung verworfen: ein marmoriertes
Höhenfeld und ein zu grobes/weiches Volumen waren kein Original-PASS, auch wenn
Build und Navigation bestanden. Der erste gemeinsame Testlauf zeigte außerdem
die noch fehlende Verknüpfung vom Zifferblatt zur App. Die reparierte Endquelle
wird getrennt eingefroren und erneut geprüft; kein fehlgeschlagener Vorlauf wird
als finaler PASS ausgegeben.

## Nachweis

[Quellen und Testergebnisse](verification/weather-clouds.json) -
[eigene Testbilder und Digests](screenshots/iteration-20261017-block2/weather-clouds-manifest.json).
Die Bewegungsprüfung vergleicht dekodierte RGBA-Pixel in einem vorab bestimmten
Himmelsbereich (x:20-75 Prozent, y:3,5-17 Prozent des Displays). Dort liegen keine
Uhr, Ortsbeschriftung, Schalter, Ecken oder Host-Bedienelemente. Positive Bewegung
muss Pixel ändern; Reduce Motion muss dieselben Pixel exakt unverändert lassen.
Der Null-Bedeckungsfall prueft einen blauen statt weißen Himmelsbereich.

[Eigener Vorher-/Nachher-Vergleich](screenshots/iteration-20261017-block2/weather-clouds-own-before-after.png) - [Bildherkunft](verification/weather-clouds-comparison.json).

**99 Modelltests, sieben gezielte UI-Faelle je iPad/iPhone (14 Ausfuehrungen) und
fuenf SDK-Builds bestanden auf identischen eingefrorenen Quellen.** Null Fehler,
Skips oder von XCTest gemeldete Runtime-Warnungen. Kein neuer kompletter UI-Suite-PASS.

## Weiter offen

**Keine Originalabnahme und keine Schließung von #21.** Die genaue Wolkenverteilung,
Tiefe, Licht-/Strömungsphase und Wetterübergänge sind weiter abweichend. Das
Wetter-Zifferblatt hat noch keine originalgetreuen Glasziffern. Regen, Schnee und
Frostrand sind weiterhin eigene vereinfachte Effekte. Eine Begrenzung der
Schleifen ist kein Nachweis für Energieverbrauch oder Bildrate auf physischen
Geräten. Insbesondere wird hier keine gemessene Echtzeit- oder Leistungsabnahme
für die zusätzlichen Plattformen behauptet.
