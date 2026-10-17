# Fade: zyklischer Verlauf als eigener Baustein

17. Oktober 2026, Teilumsetzung von [FACE-09, #18](https://github.com/Olli0103/homeview/issues/18).

Der bisherige diagonale Linearverlauf wird durch SwiftUIs öffentlichen `AngularGradient` mit eigener Palette ersetzt. Der Winkel beginnt oben am Zifferblatt und läuft im Uhrzeigersinn. Anfang und Ende besitzen dieselbe Farbe. Im Core-Modell werden negative, volle und ungültige Umdrehungen sauber normalisiert. Die Phase folgt einmal pro Stunde dem Minutenwert, bei Reduce Motion bleibt nur die Verlaufsphase fest. Die tatsächliche Uhr wird nicht angehalten.

Der untersuchte Spectrum-Shader aus dem installierten iOS-27-Companion-Bestand verwendet ebenfalls zyklische Winkel und abschnittsweise Farbgewichte. Das ist der mathematische Ansatz, nicht die Behauptung eines identischen HomeView-Fade-Renderers. Unsere Palette, Phasenfunktion und Interpolation sind eigene Festlegungen. Die drei belegten Spectrum-Einstiege und die erneut geprüfte Bibliotheksbindung stehen in der [Übernahmekarte](build-transfer-map.md). Keine private Shaderbibliothek wird eingebettet oder geladen.

Die Farbseiten wurden am vorhandenen Referenzzustand UI12 geprüft. Der Verlauf erhält dessen helle linke/obere und dunklere rechte/untere Tendenz bei der eingefrorenen Referenzzeit. Ziffern, Zeiger, Relief und das bisherige eigene Ausblendfenster bleiben erhalten. Das ist keine vollständige geometrische oder farbmetrische Originalabnahme. Vor allem fehlt weiterhin die Originalsequenz über Minuten-/Stundenwechsel. #18 bleibt deshalb offen.

## Prüfung

53 Coretests bestehen, einschließlich Nullwinkel, Drehrichtung, Farbstops, zyklischer Naht und Reduce Motion. Zwei gezielte UI-Tests auf einem frischen iPad-Simulator prüfen tatsächliche Hintergrundpixel bei verschiedenen Phasen und unveränderte Pixel bei Reduce Motion. Der Testphasen-Schalter wirkt ausschließlich mit `--uitesting`.

Ein erster Ganzbildvergleich über zwei App-Starts meldete Unterschiede. Die Analyse zeigte nur 607 abweichende Farbkanalwerte bei über 7,6 Millionen, maximal zwei Stufen, im Bereich der Ziffer 1. Der eigentliche Hintergrund war identisch. Die finale Prüfung vergleicht deshalb dekodierte Hintergrundpixel außerhalb von Zeigern, Nabe und Ziffern. Sie verwendet keine Toleranz. Auch der Wechseltest nutzt diesen Bildbereich, sodass bloße PNG-/Kantenunterschiede keinen falschen Bewegungs-PASS erzeugen.

Die fünf SDK-Ziele werden separat gebaut. Diese eng begrenzte Änderung erhält eine eigene Quellenbindung. Die vorausgehende vollständige 50er-UI-Suite gehört zum Foto-/Datenschutzstand davor; sie wird nicht als vollständiger 52er-Lauf dieses Folgestands ausgegeben.
