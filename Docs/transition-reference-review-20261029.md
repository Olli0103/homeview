# Vorhandene Gesten-GIFs vollständig nachgeprüft

29. Oktober 2026 · [#6](https://github.com/Olli0103/homeview/issues/6) / [#7](https://github.com/Olli0103/homeview/issues/7). **Quellennachprüfung, kein neuer Original-/Produkt-/Hardware-PASS.**

Zwei bereits katalogisierte S07-GIFs aus dem [TechRadar-Hands-on vom 14. Oktober](https://www.techradar.com/home/smart-home-hubs/ive-tried-apples-homeview-and-it-could-bring-my-smart-home-together-with-less-iphone-time) wurden gegen ihre bisherigen Dateidigests zurückgelesen und vollständig dekodiert, nicht nur erneut grob gestichprobt:

| Sequenz | GIF-Frames / Dauer | Tatsächlich gesichtet |
|---|---|---|
| `2SGgVQxTxWtexDdgiVfKnQ` | 84 / 5.880 ms | Vier sichtbare linksgerichtete Face-Wechsel mit überlappenden alten/neuen Ansichten |
| `SLGADnGeMyNj6CZ6geg9VP` | 74 / 5.180 ms | Snoopy-Animation; keine Navigation oder Abbruchregel |

Alle 158 vollständigen Frame-PNGs wurden gespeichert/dekodiert, vier Tafeln gesichtet und drei Übergangsframes zusätzlich groß betrachtet. Originale, abgeleitete Bilder und Kontaktbögen bleiben privat auf der externen Projektakte. [Digests, tatsächliche GIF-Zeiten und Grenzen](verification/original-transition-gifs-20261029.json). Die eingefrorenen 24 Quellen / 51 Referenzzustände werden **nicht** um diese erneute Auswertung erhöht.

Die frühere S07-Formulierung „vier Gesten-GIFs“ ist zu weit: Vier animierte GIFs sind nicht vier Gestentraces. Die vollständig geprüfte Snoopy-Folge liefert keinen Nachweis einer Navigation; die verbleibenden zwei GIFs sind nicht Teil dieser vollständigen Nachprüfung.

Die erste Folge zeigt reaktive Fluidziffern → verblassende Analogziffern → Modular mit Agenda/Datum/Uhr/Wetter → Foto mit Tiefenuhr → Home mit großer Analoguhr. Die erste Ansicht wird weiterhin nicht ungeprüft als eigenes Flow identifiziert. Sichtbare Nachbarn in diesem Demoaufbau beweisen keine vollständige feste Standardreihenfolge oder die Abwesenheit einer benutzerabhängigen Reihenfolge. Deshalb wird `Face.allCases` nicht allein auf dieser Grundlage umsortiert.

Das Original zeigt gerundete überlappende Ansichten, aber die 70-ms-GIF-Abstände sind keine nativen UI-Frames oder Latenz-/Touchmessung. Aufnahme-/Konvertierungsrate, Fingerfreigabe, Geschwindigkeit, Schwellen und Abbruchbedingungen bleiben ungeklärt. Die eigene Navigation entscheidet derzeit auf Drag-Ende und verwendet eigene Animationen; die explizite `FaceView(selection:)` bindet bereits die ausgehende Face-Art. Daraus folgt keine vollständige Stabilität sämtlicher dynamischer Inhalte oder Original-Federkurve.

Keine zusätzlichen Langsam-/Schnell-/Abbruchkurven oder Editoroptionen gefunden. #6/#7 bleiben offen; weitere Softwarekorrekturen bleiben davon unabhängig möglich. Physische/signierte Abnahmen bleiben pausiert, keine Home-Anbindung oder privaten Apple-Binaries/-Assets verwendet.
