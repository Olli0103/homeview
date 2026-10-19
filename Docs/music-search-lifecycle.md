# Verspätete und abgebrochene Musik-Suchen

19. Oktober 2026 · [QA-05, #80](https://github.com/Olli0103/homeview/issues/80).

Drei konkrete Fehler im bestehenden Suchpfad sind reproduziert und korrigiert:

- Ein verspäteter Suchfehler überschreibt nach dem Trennen nicht mehr „Disconnected“.
- Die Abschlussbereinigung einer alten Suche entfernt nicht mehr die Ladeanzeige einer neueren Sitzung.
- Eine abgebrochene Suche installiert keine Ergebnisse und pausiert keine laufende Wiedergabe.

Erfolg, Fehler und defer-Bereinigung prüfen dieselbe Sitzungsgeneration. Erfolg und Fehler verlangen zusätzlich eine aktive Verbindung und einen nicht abgebrochenen Task.

Die drei Tests steuern Providerantworten direkt über Continuations, ohne künstliche Sleeps. Vor der Korrektur drei fehlgeschlagene Tests/fünf Assertions; danach alle drei grün. Sie sind in den 171 Integrations-Modelltests enthalten. Zusätzlich bestehen 16 gezielte iPad-/iPhone-Integrationsausführungen; nach der getrennten Statuszeilenkorrektur sechs betroffene UI-Ausführungen und fünf SDK-Builds, darunter synthetische Suche, Titelauswahl, Pause, Assistentenübergabe und Wetter. Keine neue umfassende Medien- oder echte MusicKit-Abnahme.

[Quellbindung, Geräte und Ergebnisse](verification/issues-20261019.json).

Der asynchrone Play-/Resume-Pfad wurde mit diesem damaligen Suchfix nicht abgenommen. Der nachfolgende [gezielte Play-/Resume-Fix](music-playback-lifecycle.md) korrigiert vier zusätzlich reproduzierte Zustandsfehler und die native Playerübergabe. Die allgemeine Medien-/Sperrpolicy bleibt darüber hinaus offen. #67/#80 bleiben für ihre breiteren Kriterien offen. Apple Home bleibt deaktiviert.
