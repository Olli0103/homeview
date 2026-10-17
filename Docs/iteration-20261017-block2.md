# Zweites Issue-Paket: Software ohne Smart-Home-Eingriffe

17. Oktober 2026. Auftrag: umsetzbare Issues bearbeiten, keine realen Hausgeräte schalten; Kalender und andere explizite Anbindungen sind erlaubt. Apple Home bleibt bereits bei der Adapterkonstruktion gesperrt. Keine Discovery, Home-Einrichtung, Szenen, realen Kamera-Streams oder Geräteaktionen wurden ausgeführt.

## Neun einzeln geprüfte Codepakete

| Issue | Änderung | Code-Commit | Modelltests | gezielte UI-Fälle je iPad/iPhone |
|---|---|---|---:|---:|
| [#15](https://github.com/Olli0103/homeview/issues/15) | [Eigene variable Flow-Glyphen und Metriken](flow-typography.md) | `8d7842b` | 56 | 4 |
| [#53](https://github.com/Olli0103/homeview/issues/53) | [Gespeicherte Zeitzonen, Datum und Sonnenstandsschätzung](world-clock.md) | `a06ce74` | 61 | 1 |
| [#47](https://github.com/Olli0103/homeview/issues/47) | [Kalendertagesgrenzen, Quellen und Freigabewiderruf](calendar-agenda.md) | `a99c929` | 66 | 3 |
| [#48](https://github.com/Olli0103/homeview/issues/48) | [Listenrechte, eigener Zielkalender und exakter Read-back](reminder-access.md) | `7000f41` | 69 | 3 |
| [#54](https://github.com/Olli0103/homeview/issues/54) | [HTTPS-Policy, Back/Forward, Offline und Stop](browser-navigation.md) | `023645b` | 73 | 3 |
| [#50](https://github.com/Olli0103/homeview/issues/50) | [Deutsch/englische Timer- und Kochbefehle](everyday-commands.md) | `45c8156` | 76 | 3 |
| [#55](https://github.com/Olli0103/homeview/issues/55) | [Mehrere Rezepte, stabile IDs, keine erfundenen Angaben](recipe-import.md) | `4524c87` | 81 | 3 |
| [#38](https://github.com/Olli0103/homeview/issues/38) | [Entwurf über Navigation, Löschung bei Sperre](assistant-draft.md) | `e3f6f13` | 81 | 3 |
| [#80](https://github.com/Olli0103/homeview/issues/80) | [Einzelreparatur, Originalbackup und schreibgeschützte Zukunftsversion](state-recovery.md) | `0296d04` | 86 | 3 |

Jeder Code-Commit hat zusätzlich fünf erfolgreiche SDK-Builds und einen erneuten erfolgreichen Modelltestlauf **nach dem Commit**. Diese Zwischenstände sind getrennte Nachweise, keine zusammengerechnete Vollsuite für einen späteren Stand. Es sind neun Code-Commits plus getrennte Dokumentationscommits, keine großen ungetesteten Sammeländerungen.

## Gemeinsame Regression

Der gesamte App-/Test-/Ressourcenstand ist auf `0296d04f6fa24b8c58b693e7bcef96454a4de25c` eingefroren. 107 relative Quellen, SHA-256 `bc08572ae729d0c9be67cccc2ec5f3b86a129380d9a4e818a799c4bc00676b9a`.

**Abgeschlossen:** Je 65 vollständige UI-Fälle auf iPad Air 11-inch M4 und iPhone 18 Pro, iOS 27.0 Build 24A434, bestanden. 130 UI-Ausführungen, null Fehler, null übersprungene Fälle und keine von XCTest gemeldeten Runtime-Warnungen. Zusammen mit den 86 Coretests sind das **216 erfolgreiche Modell-/UI-Ausführungen** auf denselben eingefrorenen Quellbytes. Die Quellenmanifest-Prüfung nach dem Lauf ist identisch.

[Terminaler Gesamtnachweis](verification/full-regression.json) · [erneuter Host-Datei-Read-back aus dem Voll-Lauf](verification/full-file-readback.json) · [neun getrennte Code-Checkpoints](verification/checkpoint-index.json).

86 Coretests auf macOS und die fünf SDK-Builds iOS, macOS, tvOS, visionOS und watchOS bestehen auf denselben Quellbytes. Ein kompletter SDK-Build ist weiterhin kein Runtime-/Hardwaretest der vier zusätzlichen Plattformen.

## Quellen und Bilder

Alle neun Code-Checkpoints wurden unabhängig gegen Git gelesen: 907 aufgeführte Datei-Digests stimmen mit den jeweiligen Commits überein. Die neuen Bilder verwenden Checkpoint-Präfixe, damit zwei Läufe nicht dasselbe Dateiziel überschreiben. Frühere Bilder wurden aus ihren ursprünglichen Git-Bytes zurückgelesen und gegen die damals gespeicherten Digests verifiziert. Alle Screenshots sind eigene synthetische Simulatorzustände, keine Apple-Originalreferenzen.

Der Speicherfehler-Test hat einen getrennten [Host-Datei-Read-back](verification/migration-file-readback.json); die UI-Meldung allein war kein Nachweis für unveränderte Dateien.

Vier terminale Vollsuite-Bilder wurden dekodiert gesichtet und bytegeprüft übernommen: [Flow-Atlas](screenshots/iteration-20261017-block2/full-iPad-flow-own-atlas-stencil-wide-heavy.png), [schreibgeschützte Zukunftsversion](screenshots/iteration-20261017-block2/full-iPad-store-future-version-readonly-after-relaunch.png), [Weltuhr](screenshots/iteration-20261017-block2/full-iPhone-world-kathmandu-fractional-zone.png), [bewusst ausgewähltes zweites Rezept](screenshots/iteration-20261017-block2/full-iPhone-recipe-multiple-choice-no-invented-duration.png). [Digests](screenshots/iteration-20261017-block2/full-manifest.json). Die Original-HomeKit-Adaptersperre ist zusätzlich [bytegeprüft unverändert](verification/home-boundary.json).

## Issue-Abgleich

Neu geschlossen sind [#15](https://github.com/Olli0103/homeview/issues/15), [#54](https://github.com/Olli0103/homeview/issues/54), [#55](https://github.com/Olli0103/homeview/issues/55) und [#76](https://github.com/Olli0103/homeview/issues/76), jeweils nur im beschriebenen Teilumfang. Danach hat der Eigentümer MIT ausdrücklich gewählt: [#4](https://github.com/Olli0103/homeview/issues/4) und die externe Lizenzfrage [#83](https://github.com/Olli0103/homeview/issues/83) sind mit veröffentlichter [LICENSE](../LICENSE) und [NOTICE](../NOTICE.md) geschlossen. Der externe Issue-Text blieb unverändert. Die 82 ursprünglichen Titel, Labels und Zustände wurden per GitHub-API zurückgelesen: sieben Pakete insgesamt geschlossen, **75 offen**; einschließlich #83 bleiben insgesamt 75 GitHub-Issues offen. [Read-back](verification/issue-readback-block2.json).

Der reine Lizenz-/Dokumentationscommit `99d2afd` verändert keine der 107 eingefrorenen Quellen. Der Lizenztext entspricht SPDX MIT; erneut 86 Modelltests nach dem Commit bestanden. [Lizenzprüfung](verification/license.json).

## Was damit nicht erledigt ist

Die vollständige Original-Parität ist nicht fertig. Hardware-, Account-, Sensor-, zweites-Gerät- und API-Gates bleiben offen. Ebenso existiert noch **weitere umsetzbare Softwarearbeit**, unter anderem GPU-Fluid, Feedwiedergabe, Sprachausgabe, Live Activities, Setup und feinere Gast-/Medienregeln. Diese Arbeit wird nicht als angeblich ausschließlich durch Hardware blockiert ausgegeben. [Verbleibende Arbeitsliste und Grenzen](remaining-work.md).

Echte Kalender/Erinnerungen verlangen weiterhin die bewusste In-App-Verbindung und Geräteentsperrung. Automatische Tests lesen oder ändern keine realen persönlichen Konten, rufen niemanden an, senden keine Nachrichten und öffnen keine echte Kamera/Mikrofonaufnahme. Ausdrückliche bestehende AlarmKit-Prüfungen verwenden nur eigene Simulatoralarme. Keine physische Originalpixel-, Energie-, Sprachqualitäts- oder komplette Bedienhilfenabnahme ist behauptet.
