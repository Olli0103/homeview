# Done-/Cancel-Flächen und native Toolbar-Gegenkontrollen

29. Oktober 2026 · begrenzter Teil von [#73](https://github.com/Olli0103/homeview/issues/73), Gesamtissue offen.

## Ergebnis

Sieben app-eigene Done-/Cancel-Labels erhalten mindestens 44 native Bildschirmpunkte je Seite und ein rechteckiges Hit-Shape **innerhalb** des Button-Labels. Bei Recipe Handoff wird die bestehende Canvas-Skalierung berücksichtigt. Beim Notices-Button lag der bisherige 60×44-Rahmen außerhalb des Buttons und vergrößerte dessen gemeldetes Rechteck nicht.

Zwei native System-Toolbar-Buttons bleiben dagegen **unverändert**: Musik-Info und Timer Live Activities. Ihre gemeldete AX-Höhe von 36 Punkten ist nicht gleichbedeutend mit einer nur 36 Punkte hohen Touchfläche. Beide Diagonalecken eines zentrierten 44 Punkte hohen Proberechtecks funktionieren tatsächlich; die getesteten Y-Koordinaten liegen jeweils zwei Punkte außerhalb des gemeldeten AX-Rechtecks. Das ist ein positiver Koordinatennachweis, keine vollständige flächige Vermessung des UIKit-Hit-Tests.

## Gemessene app-eigene Rechtecke

Punkte, Vorher → aktueller Stand. Beide Ecken wurden je Gerät in getrennten frischen Starts mit eigenen UUID-Demostores ausgeführt.

| Ziel | iPhone | iPad |
|---|---|---|
| Fähigkeiten | 40,33 × 20,33 → 44,00 × 44,00 | 40,50 × 20,50 → 44,00 × 44,00 |
| Profil-Editor | 40,33 × 20,33 → 44,00 × 44,00 | 40,50 × 20,50 → 44,00 × 44,00 |
| Recipe Handoff | 32,76 × 16,59 → 44,10 × 44,10 | 68,99 × 35,16 → 68,99 × 45,11 |
| Reset abbrechen | 52,67 × 20,33 → 52,67 × 44,00 | 52,50 × 20,50 → 52,50 × 44,00 |
| Stromadapter | 40,33 × 20,33 → 44,00 × 44,00 | 40,50 × 20,50 → 44,00 × 44,00 |
| Mock-Notices | 40,33 × 20,33 → 60,00 × 44,00 | 40,50 × 20,50 → 60,00 × 44,00 |
| Sprach-Cancel | 65,33 × 25,33 → 65,33 × 44,00 | 65,50 × 25,50 → 65,50 × 44,00 |

Die bereits funktionierenden Vorher-Randaktionen werden nicht als defekt dargestellt. Alle 36 tatsächlich ausgeführten qualifizierten Vorher-Randaktionen führen korrekt zurück; der Fix vergrößert die sieben app-eigenen Trefferrechtecke.

## Erhaltene Fehlversuche und Testqualifikation

| Prüfstand | PASS | FAIL | Einordnung |
|---|---:|---:|---|
| Erste Vorhermatrix | 0 | 36 |24 app-eigene Größenfehler,8 AX-Größenbefunde an System-Toolbars,4 Sprach-Cancel-Vorbehalte vor dem Tap |
| Gezielter Sprach-Vorherlauf | 0 | 4 | Zu geringe Höhe; beide echten Randaktionen und exakter Entwurfserhalt bestehen |
| Erster Label-Kandidat |28|8| Sieben app-eigene Ziele bestehen; Toolbar-AX-Höhe bleibt 36. Wirkungsloser Toolbar-Umbau verworfen |
| Aktuell, ein eingefrorener Build |36|0|28 app-eigene Größen-/Randfälle und 8 unveränderte native Toolbar-Gegenkontrollen |

Sprach-Cancel meldete zunächst `isHittable=false`, obwohl die aufgenommenen Bilder und der vollständige tatsächliche Scroll-Clip das Control zeigen. Nur diese AX-Vorbedingung wurde im gezielten Vorherlauf durch protokollierten AX-Status plus weiterhin verpflichtendes Enabled, Clip-Containment, exakten Koordinatentap und tatsächliche Zustandsrückkehr ersetzt. Seine vier ursprünglichen Vorbedingungsfehler bleiben erhalten. Kein Center-Tap ersetzt die Randprüfung.

Die Toolbar-Qualifikation wurde nach dem beobachteten 36-Punkte-Clamping und **vor** den folgenden Änderungen/Koordinatenprüfungen separat festgelegt. Beide Toolbar-Produktdateien wurden exakt auf `b3da92c` zurückgestellt. Die 44-Punkte-AX-Anforderung bleibt für die sieben app-eigenen Controls unverändert; für die System-Controls wird der echte, ausdrücklich außerhalb des AX-Rechtecks gelegene Touchpunkt geprüft. Frühere AX-Bounds-Fehler werden nicht rückwirkend zu grünen Tests oder bewiesenen Produktfehlern umetikettiert.

Die ersten 32 ausgeführten Nicht-Sprach-Vorherfälle stammen noch von der vorherigen Test-Helferfassung; die begrenzten Vorbedingungs-/Toolbar-Qualifikationen sind im [vollständigen Beleg](verification/secondary-hit-regions.json) getrennt. Alle vier aktuellen Läufe nutzen exakt gleiche Quellen und kompilierte Produkte. Insgesamt 112 historische und aktuelle Ausführungen sind erhalten, davon 64 PASS/48 FAIL – **nicht 112 aktuelle PASS**.

## Rückkehr und Grenzen

- Fähigkeiten-Dialog erhält den ungesendeten Entwurf; Sprach-Cancel stellt denselben früheren Entwurf wieder her, ohne ihn zu senden.
- Profil-Editor öffnet erneut für Alex. Kein Layout oder Favorit wird verändert; Auswahl eines Demo-Profils ist keine Geräteauthentifizierung.
- Handoff erhält den aktuellen Kochschritt. Kein Offer/Accept, Timerstart oder echter Transfer.
- Musik bleibt auf `Play`; Timer Live Activities bleiben ausgeschaltet. Keine Wiedergabe oder Systemaktivität erstellt.
- Reset wird ausschließlich vor Authentifizierung geöffnet und abgebrochen, danach ohne Freigabe wieder geöffnet. Kein Löschen. Mock-Notices bleiben leer.
- Nach jeder aktuellen Randaktion zeigt der Mock-Thermostat weiterhin68°. Keine Home-Verbindung, echten Konten, Nachrichten, Anrufe, Mikrofonaufnahme oder sonstigen persönlichen Provider.

Fünf **aktuelle** SDK-Builds mit vollständigen iOS-Shortcut-Artefakten und 73 archivierten Produktdateien bestehen. Der zusätzliche Fünf-SDK-Stand des verworfenen ersten Kandidaten bleibt historisch.89 Core-/Package-Eingaben sind exakt unverändert gegenüber dem früheren 405-Test-Stand; kein neuer Core-Lauf wird beansprucht. Sechs bestehende Tooling-Tests bestanden. Quellen, zehn UI-Archive, installierte Apps und SDK-Archiv wurden nach Bytes zurückgelesen.

Dieser Stand prüft normale Systemschrift und zwei Diagonalecken, nicht jede Stelle der Fläche, VoiceOver-Reihenfolge, Voice Control, Switch Control, AssistiveTouch, gesamten Kontrast, Zoom oder physische Geräte. Der im Profil-Editor sichtbare dunkle Text auf dunklem Hintergrund wird separat weiterverfolgt; diese Trefferflächenprüfung ist kein Kontrast-PASS. Originaltreue und Geräte-/Signing-Pause unverändert. **#73/F103 bleiben partial, parity=false.**

## Eigene Bilder

| Beispiel | Vorher | Aktuell |
|---|---|---|
| iPhone Recipe Handoff | [Bild](screenshots/secondary-hit-regions/before-phone-handoff.png) | [Bild](screenshots/secondary-hit-regions/current-phone-handoff.png) |
| iPad Sprach-Cancel | [Bild](screenshots/secondary-hit-regions/before-ipad-voice-cancel.png) | [Bild](screenshots/secondary-hit-regions/current-ipad-voice-cancel.png) |

Unveränderte native Gegenkontrollen: [Musik auf iPhone](screenshots/secondary-hit-regions/current-phone-native-music.png), [Timer auf iPad](screenshots/secondary-hit-regions/current-ipad-native-timer.png). Diese Bilder allein zeigen keine unsichtbare Trefferfläche; die tatsächlichen Koordinaten, nativen Rechtecke, Return-Assertions, Quellen-/Binär-/Bildhashes und Prüfstandgrenzen stehen im [Beleg](verification/secondary-hit-regions.json). Keine Originalreferenzbilder veröffentlicht.
