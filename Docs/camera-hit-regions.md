# Demo-Kamera: native Trefferflächen und Talkback-Zustand

Stand: 20. Oktober 2026 · [Issue #73](https://github.com/Olli0103/homeview/issues/73)

Diese Änderung betrifft ausschließlich die eigene Demo-Oberfläche. Vier generierte, gebündelte Standbilder werden in vier oder neun Slots gezeigt. Kein Stream, keine echte Kamera, kein Home-Zugriff. Mock-Talkback schaltet nur lokalen Zustand und einen Hinweistext um; kein Mikrofon oder Audio.

## Reproduktion vor der Änderung

Acht neue UI-Fälle wurden vor jeder Produktänderung eingefroren: vier vollständige öffentliche XCTest-Hitflächen-Audits, zwei tatsächliche Randpfade, Talkback-Wert/Reset und ein eigenes eingefrorenes Kamera-Face. Der ungefilterte Audit sammelt sämtliche sichtbaren Befunde, nicht nur die Kamera-Controls.

| Vorher | iPad | iPhone |
| --- | ---: | ---: |
| Erfolgreiche UI-Ausführungen | 6 | 1 |
| Fehlgeschlagene UI-Ausführungen | 2 | 7 |
| Auditbefunde: Vierer-/Neunerraster/Detail/Talkback | 0/0/0/0 | 1/1/1/1 |
| Höhe des Rasterumschalters im strikten Randfall | 28,52 pt | 13,65 pt |
| Talkback-AX-Wert | leer | leer |

Auf dem iPhone ist auch der tatsächlich vermessene Talkback-Button nur 39,06 Punkte groß. Der reine Status „Demo still“ wird dort als zu kleines interaktives Ziel beanstandet, obwohl er keine Aktion hat. Der erste Fehler eines Randfalls beendet dessen Ausführung: Das ist ein Vorbedingungsfehler, kein behaupteter Fehlschlag einer noch nicht ausgeführten Aktion.

## Begrenzte Korrektur

Nur `Sources/App/CameraAndCommunication.swift` ist als Produktdatei geändert:

- Rasterumschalter, opt-in Header-Close und Detailcontrols bekommen lokal mindestens `ceil(44 / nativeCanvasScale)` Referenzpunkte. Vorhandene größere Größen bleiben erhalten; kein globaler Design-Fix.
- Die App-Rasterzeilen passen in den nach Header und Umschalter verbleibenden Raum. Das Kamera-Face verwendet weiterhin seine bisherigen Abstände und 288-Punkte-Zeilen.
- Der statische Status bleibt mit seinem Demo-/Offline-Text als AX-Element lesbar, reagiert ausdrücklich nicht auf Benutzereingaben. Er wird nicht als aktive Aktion angeboten.
- Mock-Talkback stellt „On (demo)“ / „Off (demo)“ als AX-Wert bereit. Bestehende lokale Zustandsrücksetzung beim Schließen und Rasterwechsel bleibt bestehen.

### Sichtbares Clipping ist keine begrenzte AX-Fläche

Der erste Kandidat besteht 18 von 20 Ausführungen. Die zwei Restfehler betreffen den unveränderten Überschneidungstest des Neunerrasters. Acht Auditlisten sind bereits leer; das allein beweist keine korrekte Geometrie.

Zwei zusätzliche reine Messausführungen mit unveränderten Produktbytes zeichnen die tatsächlichen AX-Rechtecke und App-Hierarchie auf. Beide Geräte liefern je sechs überlappende Rechteckpaare. Sichtbare Kacheln bleiben getrennt; ihre AX-Rechtecke sind jedoch quadratisch und höher als die sichtbaren Zeilen. Beispielsweise meldet das iPhone 116,76 Punkte Höhe bei nur 81,69 Punkten Abstand zur nächsten Zeile. Das iPad meldet245,43Punkte Höhe bei 197,67 Punkten Abstand.

Das Label innerhalb des Buttons bekommt deshalb selbst die berechnete Höhe, Clipping und eine rechteckige Trefferform. Nur den äußeren Button zu beschneiden hatte nicht ausgereicht. Der zusätzliche Messfall ist nach Archivierung entfernt; die ursprünglichen neuen Testbytes sind im Abschluss exakt wiederhergestellt. Kein Auditfilter, keine Testlockerung.

## Abschluss und Belegbindung

20 funktionale UI-Ausführungen bestehen, zehn je Gerät: die unveränderten acht neuen Fälle plus die beiden bestehenden Demo-/Nacht-/Offlinefälle. Acht vollständige Auditlisten sind leer. 14 tatsächliche native Zwei-Punkte-Randaktionen prüfen Umschalter, letzten Slot, Rasterrückkehr, Header-Close, Talkback ein/aus und Detail-Close mit konkreten Folgezuständen. Dabei werden mindestens 44 × 44 Punkte, Hittability und volle rechteckige Viewport-Enthaltenheit verlangt. Alle neun Kachelrechtecke werden auf gegenseitige Überschneidung geprüft.

Talkback-AX-Wert und Rücksetzung sind nach Rasterwechsel sowie Schließen/erneutem Öffnen beobachtet. Der vorhandene Nacht-/Offlinefall prüft weiterhin den monochromen Zustand. Fünf aktuelle SDK-Builds bestehen. Keine neuen Core- oder separaten nativen Modellläufe werden behauptet.

Das gesamte eingefrorene eigene Kamera-Face bleibt auf iPad und iPhone exakt RGBA-identisch: keine Maske, keine Toleranz, null veränderte Pixel oder Kanäle. Das ist kein Originalvergleich und keine Pixelgleichheitsbehauptung für die bewusst angepassten App-/Detailansichten.

Die Historie bleibt erhalten:56funktionale UI-Ausführungen, 45 bestanden / elf frühere Fehler; zusätzlich zwei erfolgreiche reine Messausführungen. Insgesamt 58 Ausführungen, 47 erfolgreich. Vier eingefrorene Archive enthalten jeweils 206 Quell- und 28 kompilierte/runbezogene Eingaben; sämtliche 234 Einträge sind zurückgelesen. Auch installierte Appbytes werden je Gerät geprüft. PNG-Anzahl, Bildauswahl, native Rechtecke, sämtliche ungefilterten Befunde, Bilddigests und SDK-Befehle stehen im [Messbericht](verification/camera-hit-regions.json); die [206 Quellinputs](verification/camera-hit-regions-source.json) binden den Abschlussstand.

## Offen

**#73 bleibt OPEN; F103 bleibt partial und ohne Parity-Abnahme.** Tatsächliche VoiceOver-/Voice-Control-/Switch-Control-/AssistiveTouch-Bedienung, Fokusreihenfolge/Ansagen, Dynamic Type/Zoom/Kontrast, physische Geräte und Originalabnahme fehlen weiterhin. Keine Hilfsmittel oder Berechtigungen wurden eingeschaltet. Keine Home-Anbindung, Kamera-/Mikrofonaufnahme, Konten, Systemalarme, neuen Live Activities oder echten Nachrichten/Anrufe.
