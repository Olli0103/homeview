# Zurück zur sichtbaren HomeView-Kopie

17. Oktober 2026 · [#15](https://github.com/Olli0103/homeview/issues/15),
[#16](https://github.com/Olli0103/homeview/issues/16), [#78](https://github.com/Olli0103/homeview/issues/78).

Nach Eigentümerreview ist die Priorität verbindlich: Apples beobachtete HomeView-
Darstellung rekonstruieren, keinen eigenen visuellen Stil entwickeln. Der bisherige
Videoentwurf wurde verworfen. Technische Tests rechtfertigen keine visuelle Schließung.

## Flow: erster referenzgebundener Korrekturschritt

Die Originalaufnahme UI47 ist eine perspektivische Presseaufnahme (S08), kein nativer
Pixelscreenshot. Sie zeigt breite, weich aufgeblasene Ziffern, ein abgetrenntes
Schulterstück der 1, große nahezu geschlossene Nullen und die vertikale Aufteilung
der 9. Die bisherigen dünnen Monoline-Ziffern mit Fuß und gleichmäßigen horizontalen
Stencil-Schnitten trafen diesen Zustand sichtbar nicht.

- Breitere Laufweite und kräftige, stroke-sichere Körper statt generischer dünner
  Ziffern. Die 1 erhält keinen Fuß; Schulter und Stamm bleiben im Stencil getrennt.
- Die 0 hat eine kontinuierlich schließende Innenöffnung statt schmaler Überlappungs-
  artefakte. Die 9 erhält die beobachtete Aufteilung, ohne den alten horizontalen Steg.
- Helle Cyan-/Blau-/Rosafläche ohne die vorherige starke Hintergrundabdunklung.
- Gemeinsames Farbfeld hinter und durch die Ziffern; weicher Maskengradient, dezente
  Körpertönung und schmaler Randreflex statt harter Neon-/Schlagschattenwirkung.

Alle Koordinaten und Shader sind eigene öffentliche Implementierung. Keine OS-
Schriftkonturen, privaten Frameworks oder Originalgrafiken werden eingebettet.

[Eigene Vorher-/Nachher-Aufnahmen](screenshots/iteration-20261017-block2/flow-pixels-before-after.png).
Der private Dreifachvergleich enthält zusätzlich das Originalfoto, nur ungefähr
entzerrt und ausdrücklich nicht als Pixelgeometrie ausgegeben. Er wurde dem
Eigentümer als Arbeitsvergleich zugestellt, nicht als neues X-Video.

## Prüfung und offene Originalabweichungen

95 Modelltests, fünf gezielte UI-Fälle je iPad/iPhone und fünf SDK-Builds bestanden.
Bewegung nach 30 Sekunden und Reduce Motion vergleichen jetzt dekodierte RGBA-Pixel
in einem vorab festgelegten inneren 90%-Bereich des Flow-Displays, ohne Host-Uhr,
Bedienleisten, Ecken oder PNG-Metadaten. Die Uhrzeit ist fixiert. Der separate schwarze
Hintergrundtest fordert sowohl freie schwarze Flächen als auch farbige Materialpixel.

[Quellen und Resultate](verification/flow-pixels.json) ·
[Originale eigene Testbilder und Digests](screenshots/iteration-20261017-block2/flow-pixels-manifest.json).

**#15 bleibt offen.** Das ist eine sichtbare Kurskorrektur, keine Originalabnahme.
Insbesondere sind vollständige 0–9-Originalformen und Achsenstände, genaue Glas-
Lichtbrechung, individuell variierende Proportionen, Farb-/Strömungsphase und
Originalbewegung noch nicht getroffen oder vollständig belegt. Weitere Ziffern-
Schnitte werden nicht aus dem einzelnen Foto als original bewiesen ausgegeben.
Die sechs Material-Abtastradien haben keine physische Energie-/Performanceabnahme.

Nächste sichtbare Lücken sind die austauschgleichen Plus-Kreis-Platzhalter der
App-Icons, die persönlichen Favoriten/Typografie und die eigenständige Original-
Wetteransicht UI20. Weitere Funktionspakete sind dem visuellen Abgleich nachgeordnet.
