# Musik: verspätete Starts, Resume und Eigentümerwechsel

19. Oktober 2026 · Teilfortschritt [QA-05, #80](https://github.com/Olli0103/homeview/issues/80) / [SYS-04, #67](https://github.com/Olli0103/homeview/issues/67).

Vier neue deterministische Continuation-Tests scheitern gegen die unveränderte vorherige Wiedergabeimplementierung mit vier Assertions:

- Ein später Play-Fehler ersetzt nach Disconnect „Disconnected“.
- Ein später Play-Erfolg setzt nach Disconnect die gerade gelöschte Titelauswahl wieder ein.
- Ein abgebrochener Play-Task installiert trotzdem die Titelauswahl.
- Ein später Resume-Fehler ersetzt nach Disconnect „Disconnected“.

Die Modellseite bindet Erfolg, Fehler und Polling jetzt an Verbindung **und** aktuellen Wiedergabeauftrag. Explizites Pause, Disconnect und angenommene neue Suchergebnisse widerrufen alte Play-/Resume-Aufträge. Titelauswahl und stabile Track-ID müssen noch gültig sein; Resume ohne gewählten Titel findet nicht statt. Disconnect leert auch die verstrichene Zeit. Die vier Reproduktionen bestehen nach dem Fix.

## Ein nativer Player, keine gegeneinander laufenden Starts

Nur einen späten UI-Callback zu verwerfen reicht für Audio nicht. `MusicPlaybackGate` serialisiert deshalb tatsächliche Queue-/Play-/Resume-Mutationen des nativen MusicKit-Players. Pause wirkt sofort und widerruft den laufenden beziehungsweise wartenden Auftrag. Ein altes, verspätet doch gestartetes Backend wird nach dessen Rückkehr pausiert, **bevor** der nächste gültige Start beginnen darf. Eine alte Bereinigung kann somit keinen bereits begonnenen Nachfolger pausieren.

Vier weitere kontrollierte Backendtests prüfen: Pause vor und nach verspätetem Start, genaue Übergabereihenfolge zum Nachfolger, abgebrochener wartender Auftrag ohne Backendaufruf und Fehlerbereinigung vor erfolgreichem Neuversuch. Keine Sleeps, echten Songs, Netzwerke oder Konten. Kehrt der SDK-Auftrag gar nicht zurück, wird nicht parallel ein zweiter Start zugelassen; dies ist keine behauptete MusicKit-Timeout- oder Hardwarezuverlässigkeit.

Der native Suchadapter bindet zusätzlich seinen **eigenen** Song-Cache an eine Suchgeneration und Abbruchprüfung. Ein vom Modell verworfenes altes Suchergebnis darf nicht im Adapter die Zuordnung von UI-Index zu tatsächlichem Song austauschen. Nach einer widerrufenen Berechtigungswartephase wird auch nicht noch eine Katalogsuche gestartet. Die tatsächliche Anbieterantwort wird automatisiert nicht abgefragt; das ist ein kompilierter Adapterfix, keine Live-Account-Abnahme.

Allgemeine Gast-/Präsenz-/Medienpolicy, Hardware-Snapshots und die übrige vollständige Migrations-/Offline-Matrix sind nicht hiermit erledigt. #67/#80 bleiben offen. Apple Home wird weiterhin nicht konstruiert oder verbunden.

189 Modelltests, vier gezielte native Ausführungen (zwei je iPad/iPhone) und fünf arm64-SDK-Builds bestehen auf dem gebundenen Abschlussstand. Acht eigene PNGs dekodiert und vollständig auf zwei Kontaktbögen gesichtet; zwei neue Podcast-Fokus-Viewports veröffentlicht. [Vollständige Quellenbindung und Ergebnisse](verification/music-playback-lifecycle.json). Der vorherige Vierfachfehler bleibt als Reproduktion erhalten.
