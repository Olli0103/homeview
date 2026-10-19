# Sekündliche Modellarbeit nur bei aktiver RootView

20. Oktober 2026 · Teilkorrektur von [#81](https://github.com/Olli0103/homeview/issues/81). **Keine Geräteenergie- oder vollständige Performance-Abnahme.**

## Reproduzierter Fehler

Die RootView abonnierte ihren sekündlichen Combine-Publisher auch bei inaktiver oder Hintergrund-Phase. Eine eigene native macOS-Probe mit tatsächlicher RootView und AppModel zeigt drei verletzte Erwartungen: Die Modellzeit wird bei beiden Phasen wiederholt aktualisiert, und ein abgelaufener lokaler Vordergrundtimer gibt bereits im Hintergrund seine Ablaufmeldung aus.

Im Baseline-Lauf `951364c` bewegt sich die Modellzeit während der beiden Beobachtungsfenster um rund 2,6 Sekunden weiter. Die ScenePhase ist ausdrücklich injiziert; diese Messung ist kein Nachweis echter Betriebssystem-Suspendierung oder Hardware-Energieaufnahme.

## Korrektur `6e571a8`

Die RootView verwendet bei aktiver ScenePhase weiterhin den vorhandenen Combine-Timer mit Autoconnect. In anderen Phasen erhält `onReceive` stattdessen einen leeren Publisher. Dadurch wird die periodische Subscription getrennt, nicht nur der Inhalt ihrer Callback-Funktion übersprungen. Ein Wechsel zurück zu aktiv ruft die tatsächliche `tick()`- und Activity-Synchronisierung einmal auf: Timerfristen bleiben absolute Zeitpunkte und werden beim Wiederkehren abgeglichen.

Reduce Motion darf die semantische Uhr oder laufende Timer nicht einfrieren. Der vorhandene Bewegungsschalter ändert diese Bedingung nicht. Timerdaten, Persistenzformat, MotionTimeline, WatchRoot und Systemeinstellungen werden nicht geändert.

## Begrenzte Prüfmatrix

| Native Probe | Erwartung |
| --- | --- |
| Aktive Oberfläche | Modellzeit läuft weiter |
| Inaktiv und Hintergrund | keine wiederholte Aktualisierung der Modellzeit |
| Vordergrundtimer läuft im Hintergrund ab | keine lokale Ablaufmeldung dort; nach Rückkehr abgeglichen und Receipt gespeichert |
| Rückkehr | Uhr läuft wieder |
| Vorhandener `--reduce-motion`-Schalter | semantische Zeit läuft trotzdem |
| RootView entfernt | keine weiteren wiederholten Ticks |
| Nebeneffekte | Display-Wake aus, keine Systemalarm-IDs, kein Audio-Asset |

Die erste Harness-Vorbereitung kompilierte nicht: Der macOS-Reduce-Motion-Environmentwert ist nicht beschreibbar und der Seitenname war falsch. Null ausgeführte Assertions; danach wurde ausschließlich die Probe korrigiert. Sie nutzt den bestehenden Testschalter statt einer Systemeinstellung. Der ausgeführte Vorherlauf prüft elf Bedingungen, drei scheitern. Derselbe native Nachherlauf besteht alle elf Bedingungen. Während beider inaktiven Beobachtungsfenster ändert sich die Modellzeit nun um exakt null Sekunden; nach Rückkehr ist der Ablauf-Receipt gespeichert. Ergebnisse und Messwerte stehen im [quellengebundenen Bericht](verification/foreground-pulse.json).

Vier bestehende UI-Ausführungen auf iPad/iPhone bestehen: verstrichene Zeit und pausierte Peers über tatsächlichen Simulator-Hintergrundwechsel sowie verborgenes Weiterzählen, Einblenden und Pause. Keine neuen UI-Fälle werden gezählt. Fünf SDK-Builds bestehen. 197 Quelldateien, native Ausführungseingaben, 26 kompilierte App-/Widget-/Test-/Launch-Eingaben und installierte Appbytes sind gebunden. 20 eigene PNGs sind dekodiert, zwei Kontaktübersichten gesichtet und zehn Viewports ausgewählt; laufende Countdownbilder erhalten keine erfundene statische Pixelgleichheit.

Core und Coretests sind unverändert: 291 frühere Modelltests bei `5f12a7f`, 68 bytegleiche Dateien, kein neuer Core-Lauf. Die native Probe nutzt einen eigenen UUID-Speicher, keine persönlichen Konten und kein WAV-Asset. Keine neuen Systemalarme, Live Activities, Kamera, Mikrofon oder Home-Verbindung.

## Offen

#81 bleibt offen. Nicht gemessen sind CPU/GPU, Wakeups, Framezeiten, Speicher- und Energieverbrauch, physische iPad-/Watch-Szenen, sämtliche Animationen oder neun Kamerafeeds. Der WatchRoot verwendet eine separate Tick-Subscription und ist durch diesen RootView-Fix nicht abgenommen. Der native Testschalter ist keine reale Reduce-Motion-Systemeinstellung. Aus beobachteter verringerter Modellarbeit folgt keine quantifizierte Batterie- oder Beschleunigungsbehauptung.
