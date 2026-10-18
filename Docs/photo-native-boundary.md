# Native Foto-Freistellung: abgegrenzter Simulatorbefund

18. Oktober 2026. Kein neuer Renderer-Fix oder erfolgreicher Depth-Nachweis.
Der veröffentlichte Glas-/Kopfschutzstand bleibt unverändert.

Die Untersuchung verwendet ausschließlich das eigene erzeugte Demo-Porträt,
bewusst über „Use Demo Photo“ ausgewählt. Keine reale Fotobibliothek, Kamera
oder persönliches Konto wurde geöffnet. Temporäre Diagnoseänderungen wurden
nicht in die App integriert. Ihre Quellprüfsummen und Ergebnisse sind separat
gebunden; neun Konfigurationsausführungen in fünf Diagnosemethoden sind **kein**
Freistellungs-PASS und keine neue vollständige UI-Regression.

## iOS-27-Simulator, Build 24A434

| Kontrollierter Pfad | Beobachtung |
|---|---|
| Bisheriges CI-CGImage, automatisch | Gesicht und allgemeiner Vordergrund: Vision-Domain Code9 |
| Direktes ImageIO-Bild, automatisch | Gleiches Ergebnis |
| Angebotene GPU explizit gesetzt | Für beide Anfragen tatsächlich eine GPU-Stufe gesetzt; weiterhin Code9 |
| Frisch gestarteter Ausgangspfad erneut | Weiterhin Code9, kein beobachteter Aufwärm-Fix |
| Angebotene CPU für Gesichter | Ein erkanntes/akzeptiertes Gesicht; allgemeiner Vordergrund bietet keine CPU |
| Normalisiertes 8-Bit-Bild | Keine Verbesserung; beobachtet8bpc/32bpp/alpha5/RGB |
| Personensegmentierung, balanced | Fehler; eigene App-Aufzeichnung meldet fehlende Modellressource und „E5RT is not supported“ |
| Personensegmentierung, fast, angebotene CPU | Puffer192×256 erhalten, aber tatsächlich nur Nullwerte |
| Rohpuffer gegen Default-/Software-Raster | Lesbarer OneComponent8-Puffer, Maximum0/Nichtnull0; beide Rastertotalen0 |

Die schnelle Variante verliert somit in diesem Fall keine vorhandenen Motivwerte
erst bei der Rasterisierung. Sie liefert für dieses Testporträt keine brauchbare
Personenmatte. Die allgemeine Vordergrundanfrage meldet „Could not create
inference context“ ohne weiteren Grund. Deren genaue interne Ursache ist durch
diese Versuche nicht vollständig bewiesen. Aus diesem einen Bild wird keine
allgemeine Aussage über jede Person oder jedes Gerät abgeleitet.

## Getrennte Hostkontrolle

Auf dem Mac erkennt derselbe öffentliche CI-Eingabepfad für dasselbe erzeugte
Asset ein Gesicht und eine Vordergrundinstanz, automatisch und mit tatsächlich
konfigurierter angebotener GPU. Das CG-Format stimmt überein. Es werden weder
identische katalogkodierte Eingabebytes noch eine bereits geprüfte skalierte
Maske, Vordergrund-PNG oder vollständige Tiefendarstellung der Host-App behauptet.
Instanzerkennung ist nicht schon ein abgenommener Freistellungs-Renderpfad.

## Konsequenz

Der vorhandene öffentliche Gesichtsschutz und die manuelle Korrektur bleiben
nutzbar. Ohne echte Matte wird kein Depth-Effekt behauptet und keine gezeichnete
Gesichtsfläche als Alpha ausgegeben. Es werden keine proprietären OS-Modelle
kopiert, Frameworks gepatcht oder Schwellen zur Freigabe gelockert. Hohe
Originaltypografie, allgemeine native Fotoqualität und physische Geräteabnahme
bleiben offen. Die übrige freigegebene Arbeit läuft weiter.

[Getrennte Quellen-/Ergebnisbindung](verification/photo-native-boundary.json) ·
[veröffentlichter Materialstand](photo-glass-material.md).

## Getrennter nachfolgender Mac-Adapterlauf

Der [neue vollständige Mac-Adapter-Nachweis](photo-native-mac.md) liefert für das
eigene gebaute Demo-Porträt eine tatsächlich kodierte Vordergrund-PNG mit
nichttrivialem Alpha und eine nutzbare Modellmaske. Das erweitert den früheren
reinen Host-Instanznachweis, ersetzt ihn aber nicht rückwirkend. Kein Mac-App-
Render-, iOS-Simulator- oder physischer iPad-PASS; die obigen Grenzen bleiben.
