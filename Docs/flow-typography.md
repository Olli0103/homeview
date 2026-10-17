# Eigenständige variable Flow-Ziffern

17. Oktober 2026 · [FLOW-01, #15](https://github.com/Olli0103/homeview/issues/15).

Die öffentliche App verwendet eigene kubische Ziffernskelette, keine OS-Schriftdateien oder daraus extrahierte Konturen. Solid und Stencil teilen sich dieselbe Form- und Metrikgrundlage. Die Stencil-Unterbrechungen werden aus der vereinigten Strichfläche geschnitten; sie sind keine nachgebaute Apple-Schrift.

## Verbindlicher Zeichenraum

- Breitenachse 0,90 bis 1,06; Stärke 0 bis 1 ergibt 0,10 bis 0,18 Strichbreite im Einheitszeichenraum.
- Jeder Kontrollpunkt und seine halbe Strichbreite bleiben innerhalb des Zeichenraums. Runde Enden/Verbindungen und kubische Kurven überschreiten diese Hülle nicht.
- Advance, Laufweite, Randreserve und die Skalierung beider Ziffern werden gemeinsam berechnet. Die Ziffer 1 behält dieselbe Laufweite wie die 8; Minutenwechsel lassen die Zeile nicht springen.
- Alle 1.440 Tageszeiten sind im 12- und 24-Stundenformat geprüft. Die normale App folgt dem lokalen Stundenformat; Referenzaufnahmen bleiben explizit bei 24 Stunden.
- Eigene langsame Breiten-/Stärkenbewegung. Reduce Motion, inaktive App und synthetische Standbilder frieren die Achsen ein. Keine Behauptung einer originalen Achsenzeitkurve.

## Abnahme

56 Coretests, vier gezielte UI-Fälle je iPad/iPhone und fünf SDK-Builds bestanden. Der Glyphenatlas enthält alle zehn Ziffern in Solid/Stencil an beiden Achsenecken. UI-Prüfungen decken außerdem Stil-/Hintergrundwechsel, farbiges Metal-Material ohne Hintergrund sowie Bewegung/Reduce Motion ab.

Die Erstfassung hatte bei gestrichelten Kurvenverbindungen sichtbare Reststücke; ihre Bilder und Prüfläufe bleiben historische Arbeitsartefakte und sind nicht die veröffentlichte Endabnahme. Nach Korrektur wurden die betroffenen Prüfungen wiederholt. Ein Zwischenbild enthielt trotz vorhandener Accessibility-Elemente nicht alle Glyphen. Die Endprüfung fordert deshalb sichtbare Bildpixel in jeder der zehn Zellen und wartet begrenzt auf das vollständige Rendering.

[Quellenbindung und Ergebnisse](verification/flow-rendered.json) · [eigene Bilder und Digests](screenshots/iteration-20261017-block2/flow-rendered-manifest.json).

Das technische Paket eigener nutzbarer Ziffern ist von originalgetreuer Apple-Typografie, Glas, Fluidbewegung und kompletter visueller Parität getrennt. Die bleiben in [#16](https://github.com/Olli0103/homeview/issues/16) und [#78](https://github.com/Olli0103/homeview/issues/78) offen. SDK-Builds sind keine Hardwareprüfung.
