# Was sich aus den vorhandenen OS-Builds verwenden lässt

17. Oktober 2026. Die verfügbare Quelle ist der lokale iOS-27-Simulator, Build 24A434, ARM64, mit Companion-Face-Bundles. Das ist kein vollständiger watchOS-Dump. Statisch gelesene Rechenoperationen und Architekturhinweise werden von sichtbarer HomeView-Gleichheit und öffentlicher API-Verfügbarkeit getrennt.

| Bereich | Beleg und verwertbarer Ansatz | Konkreter Stand | Offene Grenze |
|---|---|---|---|
| Foto-Platzierung | PhotosFaceLayoutCore bewertet Maskenabdeckung über vier Summenbildzugriffe | Eigener begrenzter Layoutkern mit Motivschutz, manueller Korrektur und Tests. [Details](photo-placement.md). | Originalranking, Kurationsregeln und allgemeine Vision-Qualität sind nicht vollständig rekonstruiert. |
| Konischer Verlauf | Spectrum verwendet zyklische Winkel und abschnittsweise Farbgewichte | Eigenständiger Baustein für [Fade, #18](https://github.com/Olli0103/homeview/issues/18) implementiert und separat geprüft. [Details](fade-conic.md). | Kein Beweis, dass HomeViews Fade den Spectrum-Renderer verwendet. Original-Fade-Zeitkurve bleibt unbekannt. |
| Flow-Typografie | Solid beschreibt Weight 400 bis 1000 und Width 90 bis 103. Stencil beschreibt Width 90 bis 106. | Eigene variable Solid-/Stencil-Formen mit gemeinsamen Metriken sind in [#15](https://github.com/Olli0103/homeview/issues/15) umgesetzt und geprüft. [Details](flow-typography.md). | Die ursprünglichen Glyphen werden nicht veröffentlicht. Die Existenz einer Achse belegt keine originale Zeitkurve. Der öffentliche Stand besitzt eigene geometrische Platzhalter. |
| Flow-Material | Fluid und Textglas sind verschiedene Rechen-/Materialschichten | Eigener CPU-Fluidkern und eigenes Metal-Glyphenmaterial vorhanden. | Apples internes Textglas ist kein öffentlich nutzbarer Renderer. Vollständiger GPU-Fluidpfad und Messungen fehlen. |
| Weltuhr | GMT/Alaskan trennt Stadt/Zeitzone und Sonnenzeiten; weitere Faces haben separate Tagespfade | Für [#53](https://github.com/Olli0103/homeview/issues/53) Foundation-Zeitzonen und ausdrücklich bezogene Sonnenzeiten verwenden. | Ganzzahlige Watch-Stundenoffsets nicht als allgemeines Zeitzonenmodell übernehmen. Halbe/viertel Stunden und DST bleiben Pflichtfälle. |
| Snoopy | Szenenauswahl, Animator- und Scorer-Struktur sind erkennbar | [#14](https://github.com/Olli0103/homeview/issues/14) bleibt blockiert. | Keine vollständige nutzbare Atlas-/Timeline-Grundlage. Ein Animator ohne Szenendaten ist kein vollständiges Face. |

## Prüfung dieses Durchgangs

Die Foto-Funktion wurde an 87 Instruktionspositionen erneut gegen die installierte Binärdatei geprüft. Die gemeinsame Shaderbibliothek mit `spectrumConicFrgShader` wurde erneut gehasht und gegen das vorhandene Katalogisat verglichen. Die zwei relevanten Schriftabschnitte wurden an ihren ursprünglichen Offsets erneut aus dem installierten Warlock-Binary gelesen und ihre SHA-256-Digests mit dem vorhandenen Metadatenbestand verglichen. Es wurden keine Schriften installiert und keine privaten Frameworks geladen.

Die Schrift-Metadaten und der mathematische Shaderbefund sind datierte Analyseergebnisse. Aus einer bytegleichen Bibliothek folgt weder, dass HomeView diesen Pfad aufruft, noch eine identische optische Wirkung. Rohdisassembly, AIR, originale Schriftbytes und Bildassets bleiben privat. Für öffentliche Implementierung und Tests verwenden wir eigene Quellen, eigene Fixtures und öffentliche Frameworks.

## Reihenfolge nach dem aktuellen Foto-/Datenschutzpaket

Der eigenständige konische Verlauf mit Nullwinkel, zyklischem Abschluss und Farbstops ist inzwischen implementiert und unter kontrollierten Phasen fotografiert. Die unbekannten Originalphasen bleiben getrennt offen. Die öffentliche Flow-Typografie verwendet jetzt eigene kubische Formen und gemeinsame Achsenmetriken. Sie übernimmt keine extrahierten Konturen; originale Glyphen-/Materialparameter und Zeitkurven bleiben eine getrennte Abnahme.
