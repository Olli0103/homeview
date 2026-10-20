# Persönlicher Timeout unabhängig von der sichtbaren Oberfläche

Stand: 20. Oktober 2026 · [Issue #67](https://github.com/Olli0103/homeview/issues/67)

## Tatsächlicher Fehler

`AppModel.tick()` führte die Timeout-Sperre bisher nur aus, wenn `route != .face` und kein eingehender Demo-Anruf angezeigt wurde. Nach bewusster Entsperrung zum Zifferblatt zurückzukehren konnte deshalb Gerätefreigabe, Kalender-/Reminder-Caches, Demo-Profil und Entwürfe über die persönliche Frist hinaus erhalten. Ein eingehender Demo-Anruf konnte die Sitzung ebenfalls verlängern.

Eine eigene native Probe kompiliert das tatsächliche AppModel und die unveränderten App-/Core-/Shared-Quellen des Main-Targets. Lediglich eine angehängte read-only `gateStoreURL`-Eigenschaft macht den eigenen UUID-Testspeicher prüfbar. Der normale `--uitesting`-Pfad wählt den vorhandenen Fixture-Provider; keine echte Kalender-/Reminderquelle oder Geräteauthentifizierung.

Vor jeder Produktänderung: zehn Szenarien mit 39 Assertions, fünf Szenarien und 17 Assertions fehlgeschlagen. Frische Sitzungen, der bisher funktionierende Timeout aus einer persönlichen App und das erneute Öffnen bleiben Gegenkontrollen. Der Zeitstempel `lastInteraction` wird kontrolliert 600 Sekunden in die Vergangenheit gesetzt; dies ist weder ein echter Zwei-Minuten-Wartetest noch ein Präsenzsensor-Test.

## Korrektur

Nur `Sources/App/AppModel.swift` ändert sich:

- Der Fristablauf widerruft die persönliche Sitzung unabhängig von Zifferblatt und eingehendem Demo-Anruf über die vorhandene `lockPersonalAccess()`-Bereinigung.
- Ein Latch sperrt nur einmal pro Ruhephase. Eine neue `lastInteraction`-Zuweisung, insbesondere durch die normale `interact()`-Aktion, aktiviert die nächste Frist wieder. Weitere Ticks derselben Ruhephase erhöhen die Sitzungsgeneration nicht ständig.
- Die Entscheidung, eine andere Oberfläche zum Zifferblatt zurückzuführen, bleibt getrennt: Ein eingehender Demo-Anruf sowie die bereits geschützten Einrichtungs-/Resetanzeigen werden nicht bloß wegen dieser Routennavigation geschlossen. Der persönliche Zugriff läuft trotzdem ab.

Gerätefreigabe, Kalender-/Reminder-Caches, Profil und Nachrichten-/Assistentenentwürfe werden bereinigt; gespeicherte Inhalte werden nicht gelöscht. Eine bewusst freigegebene Gast-Musikqueue bleibt der vorhandenen eigenen Medienpolicy unterstellt. Keine umfassende neue Medienpolicy wird behauptet.

## Zusätzlicher Timer-Randfall

Der erste Kandidat besteht dieselben zehn Szenarien / 39 Assertions. Eine vor der nächsten Produktänderung ergänzte Gegenprobe zeigt aber: Läuft im selben Tick ein Timer ab, wird sein Ablauf gespeichert und der neue Hinweis danach von der Sperrbereinigung gelöscht. Elf Szenarien / 43 Assertions, genau eine fehlgeschlagene Assertion: `keeps_new_timer_banner`. Die zehn bisherigen Fälle bleiben unverändert erfolgreich.

Die Sperrbereinigung liegt jetzt vor den lokalen Ablaufmarkierungen und deren Effekten. Dadurch kann der gerade entstandene Hinweis sichtbar bleiben, ohne die persönliche Sitzung wieder zu öffnen. Der eigene Timerfall verwendet nur einen Snapshot-Marker in `nativeTimerIDs`, um den Chime-Zweig zu unterdrücken. Es wird kein Systemalarm angemeldet. Der native Host enthält zudem kein abspielbares Audioasset.

## Quellengebundener Abschluss

| Prüfung | Ergebnis | Grenze |
| --- | --- | --- |
| Tatsächliches AppModel | 11 Szenarien / 43 Assertions bestanden | Synthetisch abgelaufener Zeitstempel und Fixture-Quellen |
| Bestehende Kalender-Hintergrund-/Fresh-Unlock-UI | Je ein Erfolg auf iPad und iPhone | Kein neuer tatsächlicher Idle-/Präsenztest |
| Bestehende synthetische Antwortstimme-Hintergrund-UI | Je ein Erfolg auf iPad und iPhone | Kein echtes Vorlesen oder Audio-/Hardwaretest |
| SDK-Builds | iOS, macOS, tvOS, visionOS, watchOS bestanden | Compile-/Buildnachweis, keine Geräteabnahme |

Die ursprüngliche Zehnerprobe ist vor/nach der ersten Korrektur bytegleich. Die Erweiterung um genau den Timerfall ist vor/nach der Reihenfolgekorrektur bytegleich; alle ursprünglichen Fälle bleiben darin erhalten. Kein nachträglicher Testfilter oder gelockerte Erwartung.

Ein erster externer Probe-Aufbau nahm irrtümlich das separate iOS-Widget in den macOS-Host auf und scheiterte beim Kompilieren, bevor irgendein Szenario lief. Danach wurde wie beim tatsächlichen Main-Target `Sources/Widgets` ausgeschlossen. Der Vorbereitungsfehler und alle historischen Fehlläufe bleiben erhalten; kein Produktfehler daraus behauptet. Eine frühere UI-Buildvorbereitung führte zu null UI-Ausführungen und wird nicht als Gerätebeleg gezählt.

[Messbericht, Ereignisfolgen, Befehle und Archivdigests](verification/face-idle-privacy.json) · [206 Quellinputs](verification/face-idle-privacy-source.json) · [native Probe](verification/face-idle-privacy-probe.swift.txt). Die vier nativen Archive enthalten je 315 Einträge, der finale UI-Stand 234 Einträge; die Vorbereitungsdateien sind separat gesichert. Eigene UI-Bilder und installierte Appbytes sind gebunden. Keine neuen Core-Package-Tests werden aus diesen nativen Szenarien gemacht.

## Offen

**#67 bleibt OPEN; F095 bleibt partial und ohne Parity-Abnahme.** Nicht belegt sind eine tatsächliche Präsenzquelle, physische Geräteauthentifizierung, App-Switcher-Snapshots, die vollständige Unterbrechungs-/Medienpolicy oder Originalgleichheit. Der native Host rendert keine RootView und führt keine neue verspätete Providerantwort aus; geprüft wird die tatsächliche Timeout-/Sperr-/Cachelogik. Die iOS-UI-Fälle sind vorhandene Hintergrundregressionen.

Keine Home-Anbindung, echten persönlichen Daten, Konten, Berechtigungsdialoge, Kamera-/Mikrofonaufnahme, echten Nachrichten/Anrufe, Systemalarmregistrierung oder neuen Live Activities.
