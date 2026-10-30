# Numerals: belegte Varianten und ursprünglicher Uhrenvertrag

30. Oktober 2026 · [#19](https://github.com/Olli0103/homeview/issues/19)

**Späterer Abschluss:** Die damals fehlende UI09 ist inzwischen [umgesetzt und verglichen](abstract-ui09.md); #19 ist im ursprünglichen Uhrenvertrag closed/completed. Die folgenden Ergebnisse bleiben der historische analoge Teilstand03c9ef4, nicht die Behauptung einer vollständigen Originalparität.

**Teillieferung, #19 bleibt offen:** Der zugeordnete ursprüngliche F018-Vertrag enthält auch UI09, die unbenannte abstrakte Digitalansicht. Deren0/1/9-Formen sind noch nicht implementiert/verglichen. Die unten geprüften analogen Varianten ersetzen dieses Kriterium nicht; die nächste Umsetzung adressiert genau diese Lücke, ohne UI09 als Flow oder zusätzlichen bestätigten Original-Face-Namen auszugeben.

## Umfang

Der ursprüngliche Auftrag verlangt eine nutzbare Schriftgrundlage, abgestimmte Metriken/Zeiger sowie den dokumentierten visuellen Vergleich der referenzierten Formen und Zeiten. Die spätere pauschale Forderung nach einer identifizierten privaten Originalschrift, sämtlichen denkbaren Uhrzeiten und einer physischen Abnahme war kein zusätzliches ursprüngliches #19-Kriterium. Vollständige Original-Parity und reale Geräte bleiben getrennte Prüfungen; sie werden hier nicht behauptet.

Die bisherige öffentliche gerundete Runtime-Schrift und die bereits kalibrierten Positionen, vier festen Zahlenformen **12/9/3/6**, Zeigerlängen, Ansätze und Nabe bleiben unverändert. Keine Fontdatei, extrahierte OS-Kontur oder Originalgrafik wird gebündelt.

## Fehlende belegte Variante

UI10 zeigt Grün mit schwarzen Ziffern/Datum. Die bereits archivierte S07-Folge `ZrX5EXJ3cpN3jSaC7GjMdX` zeigt einen lavendelfarbenen Grund mit rosa Ziffern/Datum und weißen Zeigern. Letztere Variante fehlte in Renderer und Editor; derselbe neue native Test scheitert deshalb auf iPhone und iPad gegen den unveränderten veröffentlichten Produktcode.

Beide Varianten sind nun explizit wählbar und pro Face gespeichert. Die Namen **Green style/Lavender style** sind eigene Bedienlabels, keine behaupteten Original-Menütexte. Die neue Palette ist eine eigene Foto-Näherung: Hintergrund149/161/235, Schrift184/100/200. Die Aufnahme liefert keine kalibrierte Displayfarbmessung oder bekannte Beleuchtung/Weißbalance. Das bisherige Grün62/147/92 und die gesamte Geometrie werden nicht nachjustiert.

## Referenz- und Funktionsmatrix

| Beleg | Vergleichsgegenstand | Zeitgrenze |
|---|---|---|
| UI09 | Unbenannte abstrakte Digitalansicht; noch fehlende eigene Replik |10:09; weiterhin offen |
| UI10 | Grün, feste12/9/3/6, Datumsposition, weiße Zeiger/Nabe | Marketingzustand10:09:30 |
| S07, zusätzliche bereits geprüfte Folge | Lavender/Pink, dieselben vier festen Zahlenformen, weiße Zeiger | Ereignisaufnahme ungefähr11:25; eigene kontrollierte Pose11:25:55 ist **keine gemessene Originalsekunde** |
| UI07/UI13 | Kleine Home-/Raster-Analoguhr, öffentliche Zahlen1–12 und Zeigergeometrie | Marketingzustand10:09; kontrollierte Replik10:09:30 |
| UI45 | Große Home-Analoguhr und Zeigerstellung | Perspektivaufnahme ungefähr9:25; eigene Pose9:25:15 ist **keine gemessene Originalsekunde** |
| UI12 | Gemeinsame Zeigerimplementierung/Fade-Kontrollansicht | Kein Abschluss der Original-Fade-Zeitkurve aus #18 |
| Funktion | Gleiche lokale Zeit UTC/Tokyo, 12-Stunden-Periodizität und GB-Prozess-Locale-Eingabe | Keine Änderung/Rücklesung der globalen OS-Uhrformat-Einstellung |

Die Ereignisaufnahmen enthalten Perspektive, Reflexionen und Gehäuse. Sie werden nicht als flache native Screens oder exakte Pixel-/Farbziele bilanziert. Unbekannte Sekunden werden nicht erfunden. Die neueren Macworld-Fotos mit sichtbaren5/7/8 gehören zur ringförmigen analogen Gestaltung, nicht zur hier implementierten festen Vierergruppe; ein offizieller Face-Name wird daraus nicht abgeleitet.

## Prüfergebnisse

Der gebündelte Lauf prüft beide Paletten, tatsächlichen Editor, Speicherung/Prozessneustart, Nacht-Rückkehr, unverändertes Grün und unverändertes Modular sowie Zeitzonen/Periodizität und die oben aufgeführten eigenen Uhrenaufnahmen. Core prüft zusätzlich den wiederholten New-York-DST-Stundenwert. Quellen, Laufstände und Ergebnisse werden im [Prüfbericht](verification/numerals-observed-variants-20261030.json) getrennt dokumentiert.

469Coretests, sechs aktuelle native Flows über zwei Testpins bei20exakt identischen Appdateien und fünf SDKs bestanden. Der Uhren-Matrixfall auf dem iPhone wird nicht ohne Grund wiederholt: er bestand bereits am identischen App-Paket. Zwei ursprüngliche Palettenfehler und der separate Nullkanal-Testfehler bleiben erhalten. Vorher-/Nachher-Grün hat auf beiden Geräten im ganzen Viewport exakt0geänderte RGBA-Pixel; auch Speicherung, Nacht-Rückkehr, Grün-Wiederherstellung und Modular-Nachbar wurden mit unveränderter0Pixel-Grenze geprüft.

Eine neu eingeführte, unqualifizierte Null-G/B-Erwartung war falsch: der gespeicherte native Nacht-PNG hat23756Pixel mit kleinem G/B-Anteil, maximal6 je Kanal. Der bestehende App-Nachtvertrag (helle PixelR>25, G/B jeweils höchstens0,4R) hat im selben Bild null Fehler. Nur diese neue Testannahme wird an den bestehenden Vertrag angeglichen; der Produkt-Nachtpfad bleibt unverändert und der ursprüngliche FAIL erhalten. Die Ganzbild-Erhaltungsgrenzen bleiben exakt0RGBA, ohne Masken.

Originalschriftidentität, feine Glyphen-/Relief-/Lichtabweichungen und vollständige Pixel-/Animations-Parity bleiben ausdrücklich nicht abgenommen. Sie sind keine nachträglich als bestanden ausgegebenen Ergebnisse dieses begrenzten Uhrenvertrags. Home-, Geräte- und Signingpausen bleiben unverändert.
