# Weltuhr: sechs lokale Textfarben kontrastiert

30. Oktober 2026 · begrenzter Teil von [#73](https://github.com/Olli0103/homeview/issues/73), **keine weitere Issue-Schließung**. [#53](https://github.com/Olli0103/homeview/issues/53) und die Original-/Hilfsmittelabnahme bleiben offen.

Nur sechs Textzuweisungen in `Everyday.swift`: Zonenkennung in Städtewahl und beiden Detail-Layouts, Erklärung unter der Liste, Sonnenzeiten und Modellhinweis im Tageslichtbalken. Auf weißem Hintergrund nun Schwarz mit65%Deckung statt `.gray`. Die17 Schriftmetriken, Layouts, native Suche, Symbolfarben, Modelle, Sonnenberechnung, Provider und Tests sind unverändert;165 weitere Produkt-/Ressourceneingaben bytegleich.

## Gemessener Umfang

Die bereits gebundenen normalen P10-Aufnahmen wurden wiederverwendet: **keine neuen Vorher-UI-Läufe**, vier frühere Ausführungen,96 bytegeprüfte PNG-Kopien. Identische native ROIs und unveränderter eigener4,5:1-Vertrag: mindestens100 neutrale Vordergrundpixel,35%nahezu weißer Hintergrund, sRGB-Kontrast des100.-dunkelsten Pixels; der dunkelste Einzelpixel bleibt eine separate Obergrenze.

| Messung | Vorher | Aktuell |
|---|---|---|
| Fünf Textrollen je Gerät, zehn Bedingungen | höchstens3,261:1; eigener Vertrag verfehlt |6,897–7,005:1; zehn bestanden |
| Vier schwarze positive Kontrollen |21:1 |21:1 |
| Vorab vollständige Außenvergleiche |36 eingefrorene Paare |27 exakt; **neun strikt fehlgeschlagen**, siehe unten |
| Zielrahmen und Clips |48 Paare |48 exakt |

Das eigene einheitliche4,5-Ziel bedeutet nicht, dass jede Rolle zuvor den für große Schrift geltenden Mindestkontrast unterschritt. Gemessen wurden tatsächlich sichtbare normale Textregionen, nicht alle Sätze, größte Schrift, native Hilfsmittel oder allgemeine Lesbarkeit.

## Bildabweichung bleibt erhalten

Neun iPhone-Detailpaare unterscheiden sich außerhalb der unverändert eingefrorenen Textmasken: jeweils6452Pixel im unteren OS-Home-Indikator, native Boundingbox `[387,2397,818,2411]` bei1206×2436Pixeln. Der Indikator fehlt im Vorherbild und ist aktuell sichtbar. Ganze Bilder und Differenz wurden gesichtet. **Kein nachträglicher Ausschluss dieser Region, keine Maskenerweiterung und kein behaupteter Gesamt-Pixel-PASS.** Die übrigen27 qualifizierten Außenvergleiche sind exakt. Zwölf Städtewahl-Posen waren schon vor der Änderung wegen nicht vollständig inventarisierter weiterer Zonenzeilen unqualifiziert und bleiben es.

## Aktueller Funktionsnachweis

**16 aktuelle native iPhone-/iPad-Ausführungen, fünf SDK-Builds und sechs Tooling-Tests bestanden.** Acht Normal-/Großschrift-Inventuren sowie acht bestehende Tageslicht-/unbekannte-Zone-/echte-OS-Snapshot-/Rückkehrregressionen. Keine neue Bruchteilzonen-Neustartprüfung: der historische P10-Fall wird nicht umetikettiert. Die38 bestehenden Textausdehnungsbedingungen bleiben grün; das sind keine38 neuen Korrekturen. Acht fehlende isolierte AX-Textkinder bleiben ohne Schriftmessungs-PASS. Größte Schrift zeigt gespeicherte Scrollposen und teils abgeschnittene Nicht-Zieltexte, keine vollständige Satz-/Hilfsmittelabnahme.

235 Quellen, tatsächliche kompilierte Inputs/installierte App- und Runnerbytes, sechs neue und zwei wiederverwendete UI-Archive sowie73 SDK-Produkte vollständig zurückgelesen.234 neue native PNGs dekodiert; zwölf eigene Inventur- und vier Regressionstafeln sowie beide Kontrasttafeln tatsächlich gesichtet.96 neue Inventur-Ganzbildduplikate nur dekodiert, nicht einzeln gesichtet. Zwei Schriftpräferenz-Controller haben ihre sechs Änderungen einschließlich Rückstellung auf `large` nachweislich beendet.89 Core-/Paket-/Testinputs unverändert; kein neuer Core-Lauf, historische405 Tests separat.

[Quellen, Einzelwerte, Ergebnisse, unveränderte Masken und ausdrücklich rote Vergleiche](verification/world-clock-contrast.json) · [14 eigene unveränderte native Bildausschnitte](verification/world-clock-contrast-images.json).

Kein Playback, neue Aufnahme, Ortung, Account-/Home-Zugriff, Systemalarm, native Hilfsmittelaktivierung oder physische/Signing-Abnahme. Paketmetadaten sind kein neuer Siri-/Kurzbefehle-Aufruf. Der Gesamtauftrag läuft weiter; nächste Priorität ist ein vollständiger Mock-Schloss-Sicherheitsvertrag bei#25, nicht eine weitere kleine Schriftlieferung.
