# Öffentliche Podcast-Feeds

19. Oktober 2026 · [MEDIA-03, #59](https://github.com/Olli0103/homeview/issues/59).

Die Podcast-Ansicht lädt einen selbst eingegebenen öffentlichen HTTPS-RSS-Feed und spielt ausgewählte Audio-Enclosures über AVPlayer. Auswahl und App-Neustart starten keine Wiedergabe. Die Metadaten, die ausgewählte Folge und die letzte Wiedergabeposition bleiben lokal erhalten. Entfernen eines Feeds entfernt auch dessen lokale Episoden und Positionen.

RSS-Parsing übernimmt [FeedKit 10.9.4](https://github.com/nmdias/FeedKit/releases/tag/10.9.4), exakt auf Revision `545aba8b9357fb00ffe51483b659519d96a9d635` fixiert. Ein separater Wegwerf-Checkout wurde auf dem aktuellen Mac gebaut. Die MIT-Lizenz liegt in den App-Ressourcen. Kein eigener XML- oder Audio-Decoder.

Der Client akzeptiert nur HTTPS ohne eingebettete Zugangsdaten, Fragment oder fremden Port. Er setzt keine Cookies, gespeicherten Zugangsdaten oder HTTP-Caches ein. Feedabruf maximal 30 Sekunden, 2 MB XML, acht gespeicherte Feeds, 100 Episoden je Feed. DTD-/Entity-Deklarationen, nicht unterstütztes XML, nicht sichere oder nicht als Audio deklarierte Enclosures werden abgewiesen. Fehlende Dauer bleibt ausdrücklich unbekannt, statt eine Zahl zu erfinden. Feedfehler ersetzen eine gewählte Folge nicht durch Demoaudio. Eine Generationsgrenze verhindert, dass verspätete Abrufe entfernte Inhalte erneut einsetzen.

Play, Pause und ±15 Sekunden steuern den nativen Player. Die Aktivitätsleiste führt zur gewählten Folge zurück. Musik, Voice-Eingabe, Anruf-Demo und Hintergrundwechsel pausieren diese Wiedergabe. Beim Zurückkehren zu einem bereits ausgewählten verbundenen Musiktitel erscheint dessen Player wieder; Play/Resume und Pause benutzen denselben App-Audiowechsel wie der übrige Music-Pfad. Vorher öffnete die Ansicht stets die Suche und der direkte Resume-Button umging die Podcast-Pause. Dieser konkrete Fehler ist Teil des Pakets, keine vollständige MusicKit-Abnahme.

Hintergrund-Streaming, Downloadverwaltung, Apple-Podcasts-Katalog, private Abos und Apple-Accountsync sind nicht implementiert. Physische Audioausgabe, AirPlay und Langzeitbetrieb sind getrennte Abnahmen.

## Eigene Testdaten

Der nur unter beiden Testargumenten `--uitesting --podcast-fixture` sichtbare Testfeed enthält zwei frei erfundene Folgen. Exakt deren Fixture-URLs werden ausschließlich im Testmodus auf das gebündelte eigene WAV abgebildet. Andere Feedfehler werden nicht auf Testaudio umgebogen. Das WAV enthält 60 Sekunden selbst erzeugten 220-Hz-Sinuston, mono, 16 kHz/16 Bit; weder Sprache noch fremde Aufnahmen. Es ist ein Funktionssignal, keine Musik.

Automatische Prüfungen verwenden ausschließlich diese Daten und isolierte Teststores. Die zusätzlichen URLSession-Transporttests injizieren ein privates URLProtocol; sie prüfen den echten Client bei Erfolg, HTTP 503 und deklariertem Übermaß, ohne eine externe Anfrage. Das ist keine Live-Feed-, Apple-Account- oder Hardwareabnahme. Apple Home bleibt deaktiviert.

## Nachweise

181 Modell-/Transporttests bestanden. Sechs unterschiedliche ausgewählte native Fälle je iPad/iPhone sind über die dokumentierten Checkpoints abgedeckt. Der letzte Quellenstand wiederholt die drei vom zusätzlichen Musikfix betroffenen Fälle je Gerät erfolgreich; keine erfundene durchgehend grüne Gesamtsuite. Alle fünf arm64-SDK-Builds bestehen. 48 Bilder der qualifizierten ursprünglichen/letzten Läufe plus zwölf Bilder des gesonderten Seek-Folgelaufs dekodiert; 26 ausgewählte Zustände auf Kontaktbögen gesichtet. 16 eigene Viewport-PNGs sind veröffentlicht.

[Quellenbindung und vollständige Checkpoint-Ergebnisse](verification/podcast-rss.json). Fehlgeschlagene Piloten bleiben fehlgeschlagen: zuerst überdeckte Accessibility-IDs, danach eine falsche absolute Zeitannahme im Test und zuletzt der tatsächliche Music-Rückkehrfehler. Keine nachträgliche Umdeutung in PASS. Allgemeine noch ausstehende Music-Play-/Resume-Races und Gast-/Medienpolicy aus #67/#80 werden damit nicht pauschal freigegeben.
