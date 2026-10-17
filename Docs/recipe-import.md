# Rezeptimport ohne erfundene Angaben

17. Oktober 2026 · [DAY-09, #55](https://github.com/Olli0103/homeview/issues/55).

Der Import verarbeitet bis zu zwanzig unterschiedliche strukturierte Rezepte pro Seite. Ein unvollständiger erster `Recipe`-Knoten verdeckt keine späteren gültigen Rezepte. Bei mehreren gültigen Ergebnissen wählt der Nutzer ausdrücklich das gewünschte Rezept. Gleicher Quellen-/Titel-/Zutaten-/Schrittinhalt erhält eine stabile lokale ID; erneuter Import erzeugt dadurch keine zweite Anheftung desselben Inhalts.

## Daten und Grenzen

- Fehlende Gesamtdauer und Portionen werden als **nicht angegeben** gezeigt. Es gibt keine erfundenen Standardwerte „1 Minute“ und „4 Portionen“ mehr. Einzelne bekannte Vorbereitungs-/Kochzeiten werden entsprechend beschriftet, nicht als belegte Gesamtdauer ausgegeben.
- Mehrere Yield-Angaben bleiben Text mit ihren Einheiten. Boolesche/ungültige Werte werden nicht zu einer Personenzahl umgedeutet.
- `HowToSection` und `HowToStep` erhalten ihre tatsächliche Reihenfolge. Überlange/zu viele Anweisungen werden abgewiesen, nicht still abgeschnitten.
- Explizite ISO-Dauern bis sieben Tage werden verarbeitet; nicht unterstützte Größen bleiben unbekannt. Der alte Test verlangte eine erfundene 24-Stunden-Kappung für extrem große Quelldauern. Die Abnahme verlangt stattdessen Ablehnung, plus korrekte 72 Stunden für eine tatsächlich unterstützte Dauer.
- Eindeutige narrative Minuten-/Stundendauern können einen Koch-Timer anbieten. Intervalle, Alternativen, ungefähre Angaben, unabhängige Mehrfachzeiten und nicht exakt als ganze Minuten darstellbare Sekundenangaben erzeugen keinen falschen Timer.
- Externe Cover-URLs müssen HTTPS ohne eingebettete Credentials verwenden. Fehlende Cover behalten die eigene erkennbare Ersatzgestaltung.

Der DOM-Import ist begrenzt und durch Seiten-/Requestgeneration, Navigation, Inaktivität und Abbruch abgesichert. Eine verspätete Antwort darf keinen inzwischen verlassenen Browser wieder durch eine Rezeptseite ersetzen. Eingebundene Website-Inhalte erhalten weiterhin keine native Befehlsschnittstelle.

Explizit gestartete Timer sind unabhängige Nutzeraktionen. Unpinning benennt sie nicht um und ordnet sie keinem anderen Rezept zu. Es behauptet auch nicht, bereits gestartete Systemalarme rückgängig zu machen. Ein fehlgeschlagenes Timer-Erstellen zeigt keinen erfolgreichen Start-Banner mehr. Früher gespeicherte Importe behalten ihre damaligen Angaben; ohne Originalquelle wird deren Herkunft nicht rückwirkend geraten.

81 Modelltests, drei gezielte UI-Fälle je iPad/iPhone und fünf SDK-Builds bestanden. Geprüft: mehrere Rezepte bis zur bewussten Auswahl, fehlende Metadaten, bestehender DOM-/Pin-/Kochfluss und die Kochbefehle. [Quellenbindung und Ergebnis](verification/recipes-checked.json).

Original-Cover-/Layoutparität bleibt Teil der gesonderten öffentlichen Asset- und visuellen Abnahmen. Hardware-/Handoff- und persönliche Browserkontoabnahme werden nicht behauptet.
