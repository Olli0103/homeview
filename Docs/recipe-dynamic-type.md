# Rezepte: Systemschrift, Scrollwege und vier Textfarben

29. Oktober 2026 · Teilumfang von [#73](https://github.com/Olli0103/homeview/issues/73). Keine vollständige Hilfsmittel- oder Originalabnahme.

## Reproduzierter Befund und Änderung

Bibliothek, eigenes Rezept-Cover, Zutaten, Kochschritte und lokale Handoff-Ansicht wurden mit normaler Systemschrift (`large`) und größter Accessibility-Kategorie auf iPhone/iPad inventarisiert. Nach Qualifizierung des Scroll-Helfers bestanden acht Vorher-UI-Ausführungen; **46 Textausdehnungsbedingungen scheiterten mit Faktor 1,00**, während der bestehende semantische Vorleseeinstellungen-Titel als positive Gegenkontrolle auf beiden Geräten wuchs. Vier eigene flache Textrollen scheiterten in allen 16 Geräte-/Größenbedingungen am deklarierten Kontrastziel 4,5:1.

Vier Produktdateien ändern sich: lokale `ScaledMetric`-Rollen und Accessibility-Scrollanordnungen; `AppHeader` bekommt eine ausdrücklich optierte Anordnung, deren Standard weiterhin `false` ist. Lange Kochtitel liegen in der großen Anordnung im Scrollbereich, nicht in einem festen Header. Das Cover erhält nur bei Accessibility-Schrift eine dunkle Unterlage hinter dem weißen Text. Die vier nachgewiesenen Textfarben werden lokal dunkler. Modell, Rezept-/Transferdaten und vorhandenes `RecipeArtwork` bleiben unverändert. Das eigene Cover zeigt weiterhin das vorhandene Symbol-Platzhalterbild, keine neu behauptete Originalfotografie.

## Text und Kontrast

**46 von 46 Textausdehnungsbedingungen bestehen jetzt.** Gemessen werden 23 tatsächliche statische AX-Textrollen je Gerät, nicht die 24 Quell-Metrik-Properties. Höhen wachsen etwa 2,36–11,28-fach; der obere Wert enthält Zeilenumbruch und ist **kein elfmal größerer Font**. Kombinierte Button-/Label-Rechtecke mit Padding oder 44-Punkte-Untergrenze sind aus der Fontmetrik ausgeschlossen. Die semantischen positiven Kontrollen bleiben grün.

| Qualifizierter eigener Glyphenkern-Kontrast | Vorher | Nachher |
|---|---:|---:|
| Bibliotheks-Metadaten | 3,07 | 6,81 |
| Kochschritt-Caption | 3,26 | 7,00 |
| Timer-Label, Text und gleichfarbiges Symbol | 2,31 | 6,47 |
| Handoff-Quellenhinweis | 4,00 | 7,00 |
| Schwarzer Handoff-Titel, positive Kontrolle | 21,00 | 21,00 |

Alle 16 eigenen Nachherbedingungen qualifizieren. sRGB/relative Luminanz, zwei Punkte ROI-Erweiterung und Hintergrundring, bekannte Nachbartexte mit einem Punkt Abstand ausgeschlossen; mindestens 100 tatsächliche Vordergrundpixel und konservative Untergrenze über den 100. dunkelsten Pixel. Das misst den gerenderten Kern, nicht jeden Antialias-Rand oder ein physisches Display.

Die erste Nachheranalyse hatte **13 PASS und drei unqualifizierte ROIs**: Schwarze Außenecken des abgerundeten weißen Root-Canvas wurden fälschlich als dunkler Text erfasst. Originaldaten und Crops bleiben erhalten. Vor einer getrennten Neuauswertung wurde die Root-Geometrie (84-Punkte-Rundung im 600-Punkte-Canvas) gebunden: größte zusammenhängende weiße Fläche, eingeschlossene Löcher gefüllt, äußere schwarze Ecken ausgeschlossen. **Glyphenlöcher bleiben Teil der Messfläche**, kein Weißpixel-Filter. Dieselbe Oberflächenregel gilt vorher/nachher, Schwelle und Mindestpixelzahl unverändert. Zwei repräsentative binäre Masken tatsächlich gesichtet. Keine Anwendung auf Foto oder heterogenes Glas.

## Normalansicht und echte lokale Aktionen

14 positionsgleiche normale Rezept-Bildpaare haben **null geänderte Pixel außerhalb der vier deklarierten Farbrollen**. Sechs Cover-/Zutatenaufnahmen sind vollständig RGBA-pixelgleich, einschließlich unverändertem Artwork. Auch der normale zweite Kochschritt mit Fortschrittspunkten stimmt außerhalb seiner Farbrollen überein. Keine Bildregistrierung. Zwei zusätzliche Timer-Einrichtungsaufnahmen entsprechen den bereits veröffentlichten normalen Bildern exakt.

Die neue Inventur hakt die erste Zutat an und wieder ab sowie die letzte Zutat an, geht Schritt 1→2→1 und bis Finish, öffnet/schließt nur die lokale Handoff-Ansicht und erhält den Schritttext. Sie startet **keinen Timer**, bietet/akzeptiert keinen Transfer und endet mit leerem Timer und MockHome 68°. Eine getrennte bestehende Randaktions-Regression startet bewusst einen synthetischen Fünf-Minuten-Vordergrundtimer; keine native Alarm-/Live-Activity-/Tonabnahme daraus.

Große Absätze und Zutatenzeilen dürfen höher als der Scroll-Clip sein und passen nicht gleichzeitig ins Fenster. Sichtbare Scrollposen und tatsächliche Aktionsrückmeldungen wurden geprüft. Funktionale Mittelpunktaufrufe sind keine 44-Punkte-Randflächen- oder VoiceOver-Abnahme. `effective_clip`/`fully_in_clip` enthalten den tatsächlichen Scroll-Clip; die alten Zusatzfelder `intersects_clip`/`visible_intersection` dieser Inventur beziehen sich nur auf den Viewport und werden nicht als Scroll-Sichtbarkeitsbeweis verwendet.

## Test- und Belegbilanz

**Zwölf aktuelle UI-Ausführungen, vier eindeutige Methoden**, fünf SDK-Builds/73 Produktdateien und sechs Tooling-Tests bestehen am gemeinsamen 233-Dateien-Quellpin `ec7e9de…`. Aktuelle kompilierte UI-Eingaben identisch; installierte Appbytes und unveränderte Eingaben geprüft. Keine aktuellen Fehler, Skips oder strukturierten Runtime-Warnungen. Vier Produktdateien geändert, 161 andere Produktinputs und 89 Core-/Package-Eingaben unverändert; kein neuer Core-Lauf (vorheriger Stand 405).

Historie: **28 UI-Ausführungen, 24 PASS und vier erhaltene anfängliche Helferfehler**. Der Helfer hatte anfangs einen festen Footer gegen den unzuständigen Instruktions-Scrollbereich geprüft. Nach tatsächlicher AX-Abstammungsprüfung wurde der Vorherstand qualifiziert, noch vor Produktänderungen. Nachher kamen fünf reine Beobachtungsposen und Clip-Metadaten hinzu; sämtliche ursprünglichen Assertions sind exakt erhalten, **Vorher-/Nachher-UITestquellen aber nicht identisch**. Warm-Kompilierungen sind keine zusätzlichen UI-Ausführungen.

14 UI-Eingabearchive plus SDK-Archiv vollständig zurückgelesen; 220 native PNGs dekodiert. 26 native Übersichten erzeugt, davon 18 tatsächlich gesichtet; drei zusätzliche adaptive Übersichten decken die übrigen aktuellen Rezept-Viewport-Posen ab. Ein vorheriger Vier-Bild-Tooloutput war kontextbedingt abgeschnitten und zählt nicht als Sichtung. Zusätzlich zwei Farbübersichten, zwei Oberflächenmasken und acht volle große Viewportbilder geprüft. Nicht alle 220 Einzelbilder werden als einzeln gesichtet ausgegeben. 18 eigene PNGs bytegeprüft veröffentlicht; Schriftpräferenzen wieder `large`.

[Messungen, Quellpin, einzelne Ausführungen und Belegbilanz](verification/recipe-dynamic-type.json) · [eigene Bilder](screenshots/recipe-dynamic-type).

**#73 bleibt OPEN, F103 partial/parity=false.** Keine echten Konten, Home, Kamera/Mikrofon, Nachrichten/Anrufe, Hilfsmittel- oder physische Abnahme. Geräte-/Signing-Pausen unverändert; der Gesamtauftrag läuft weiter.
