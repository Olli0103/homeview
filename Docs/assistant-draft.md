# Assistenten-Entwurf und Navigation

17. Oktober 2026 · [AI-06, #38](https://github.com/Olli0103/homeview/issues/38).

Ungesendeter Text gehört jetzt zur laufenden App-Sitzung statt nur zur kurzlebigen Assistentenansicht. Navigation zum Face und zurück erhält ihn, ohne den Befehl auszuführen. Ein Ansichtswechsel während einer laufenden Aufnahme stellt den vorherigen Textentwurf wieder her; abgeschlossene Vorschauen bleiben ebenfalls Entwürfe bis zum ausdrücklichen Senden.

Die Sitzungsgrenze hat Vorrang: Hintergrund, Abmelden oder Profil-/Datensperre leeren den Entwurf. Eine Generationskennung verhindert, dass ein anschließend verschwindender Voice-Dialog alten Text wieder einsetzt. Der Entwurf wird nicht in die lokale Snapshot-Datei geschrieben.

81 Modelltests, drei gezielte UI-Fälle je iPad/iPhone und fünf SDK-Builds bestanden. Die neue Sequenz prüft Textnavigation, Navigation während synthetischer Aufnahme, unveränderten Mock-Thermostat ohne Send sowie Cachelöschung nach echtem Simulator-Hintergrund. Bestehende Preview-/Send- und Audio-/Navigationsfälle sind eingeschlossen. [Quellenbindung und Ergebnisse](verification/draft.json).

Genaue Originalgestenkurven, physische VoiceOver-/Tastatur-/Switch-Control-Abnahme und reale Spracherkennung sind hiermit nicht behauptet. Das übergreifende Original-Abnahme-Issue bleibt offen.


## Ergänzung · 19. Oktober 2026

Größenflexible Eingabe statt verkleinerter Assistentenfläche: Send bleibt auf iPad/iPhone mit Tastatur 48 Punkte groß. Cmd-Shift-S, bewusstes Tastatur-Schließen, Entwurf/Rotation und getrenntes Scrollen geprüft. 16 erfolgreiche UI-Ausführungen über zwei Checkpoints; vorherige Fehlversuche bleiben separat erhalten. Escape-/physische Tastatur-/Originalabnahme bleiben offen. [Aktueller Lieferumfang und Nachweisgrenzen](assistant-input.md).
