# Motivgeschützte Foto-Uhrplatzierung

17. Oktober 2026, Umsetzung zu [PHOTO-02, #12](https://github.com/Olli0103/homeview/issues/12).

## Was aus dem OS-Build verwertbar war

Im installierten iOS-27-Simulator, Build 24A434, ARM64, wertet `PFLCCoverageValidator coverageOfTimeLabel:` in PhotosFaceLayoutCore ein Uhrenrechteck gegen eine Maske aus. Der gelesene Bereich liegt bei 0x1130 bis vor 0x128c. Vier Zugriffe auf ein Summenbild liefern die Maskensumme, normiert durch Rechteckfläche mal 255. Das ist eine Standard-Summenbildoperation. Die Auswahl aller Bildausschnitte und Apples vollständige Rankingfunktion sind damit nicht rekonstruiert.

Die untersuchte Binärdatei hat SHA-256 `a7eaec70a4d42a5ab48e21f9cc6412b60cd27807d6bee6ad851c438f507d4331`. Die 87 Instruktionspositionen des vorhandenen Auszugs wurden erneut gegen die installierte Datei geprüft. Rohdaten, Disassembly und OS-Assets bleiben außerhalb dieses Repositories. Keine private Bibliothek wird geladen oder ausgeführt.

Vorhandene öffentliche Technik genügt. Vision liefert die Motivmaske, Core Image deren Raster und freigestellten Vordergrund. Eine zusätzliche Bibliothek ersetzt die produktspezifische Uhren-/Ausschnittbewertung nicht. Öffentliche Grundlage: [Lift subjects from images, WWDC23](https://developer.apple.com/videos/play/wwdc2023/10176/). Keine neue externe App-Abhängigkeit.

## Eigener Layoutkern

`PhotoSubjectMask` enthält eine begrenzte Summenbildtabelle. Rechtecke sind auf den sichtbaren Bereich begrenzt; leere und ungültige Rechtecke liefern keine NaN-Abdeckung. Tests prüfen auch weiche Maskenwerte, nicht nur binäre Flächen.

`PhotoPlacement` bewertet oben, unten und mittig platzierte Uhren sowie fünf Ausschnitte entlang der längeren Bildachse. Die Bewertung bevorzugt erhaltene Motivmasse und wenig Uhrüberdeckung. Stabile Reihenfolge und Epsilon verhindern Wechsel bei nahezu gleichen Bewertungen. Bei fehlender Maske bleibt der Bildausschnitt zentriert. Wenn kein quadratischer Ausschnitt mindestens 98,5 Prozent der erkannten Motivmasse erhält, bleibt das ganze Bild mit freien Rändern sichtbar.

Mehr als 18 Prozent Maskenabdeckung des Uhrenrechtecks schaltet die Tiefenüberlagerung ab. Der Vordergrund verdeckt dann nicht die Uhr. Kandidaten, Schwellenwerte und Gewichtung sind unsere Entscheidungen. Sie stammen nicht aus einer vollständigen Apple-Spezifikation.

Die Prüfung des Core-Image-Rasters hat eine zunächst zusätzliche vertikale Spiegelung aufgedeckt. `render(_:toBitmap:)` liefert die hier benötigte obere Bildzeile bereits zuerst. Der Code dreht diese Zeilen nicht nochmals um. Ein synthetischer Core-Image-Test mit weißem oberen und schwarzem unteren Bildteil sichert die Orientierung.

## Integration und Korrektur

Bild und freigestellter Vordergrund müssen exakt dieselbe Transformation erhalten. Die Uhrposition wird unabhängig davon gesetzt. Nutzer können die Uhrposition wählen, automatische Rahmung ausschalten, den Ausschnitt verschieben und die Korrektur zurücksetzen. Einstellungen gehören zum bewusst ausgewählten Bild, nicht zu einem persönlichen Account.

Korrekturen werden über einen lokalen SHA-256-Schlüssel der ausgewählten Bildbytes gespeichert. Die Tabelle ist auf 100 Einträge begrenzt. Sie enthält weder Bibliotheks-IDs noch Pfade. Alte Speicherstände erhalten eine leere Korrekturtabelle. Beim Neustart wird das gespeicherte Bild erneut analysiert. Verspätete oder abgebrochene Analysen ersetzen nicht das inzwischen ausgewählte Bild.

Die Entwicklung verwendet selbst gezeichnete Testflächen. Sie stammen nicht aus Referenzfotos, OS-Beispielpaaren oder persönlichen Alben. Die realen Freigaben von PhotosPicker/PhotoKit sowie die Vision-Qualität auf beliebigen persönlichen Bildern sind weiterhin gesonderte Geräteabnahmen. Der Layoutkern macht keine vollständige Originalpixel- oder Motivverständnis-Zusage.
