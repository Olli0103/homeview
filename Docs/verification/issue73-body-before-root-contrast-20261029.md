<!-- homeview-backlog:SYS-10 -->

## Ziel

Accessibility über alle zentralen Flows abnehmen.

## Stand

Beschriftete Controls und alternative Navigation vorhanden. Native Wetter-Einstellungs-, App- und Dialog-Trefferflächen, fokussierte Sichtbarkeit sowie drei Assistenten-Systemschriftrollen und das Vorleseeinstellungen-Done-Rechteck auf iPad/iPhone korrigiert; keine vollständige Accessibility-/Hilfsmittelabnahme. Zusätzlich sieben app-eigene Done-/Cancel-Rechtecke korrigiert; zwei unveränderte System-Toolbar-Controls mit tatsächlichen Randpunkten außerhalb ihrer gemeldeten AX-Bounds gegengeprüft. Der Profil-Editor verwendet nun zur dunklen Sheet-Präsentation passende lokale semantische Textfarben; vier statische Rollen auf iPhone/iPad kontrastgebunden geprüft.

Timer-Titel, Status und Auswahl skalieren jetzt mit der Systemschrift; eine separate scrollbare Accessibility-Anordnung erhält die Aktionen. Vier normale Timer-Ansichten bleiben exakt pixelgleich. Die neue begrenzte mobile Abnahme ist unten getrennt nach zwei Testpins und bytegleicher App dokumentiert.

Auch die Timer-Einrichtung passt Titel/Zeit, Dauer und Start lokal an große Schrift an. Ihre normalen Aufnahmen bleiben exakt gleich; die bereits vorher funktionierenden Start-Randaktionen wurden nicht wegen kleinerer AX-Bounds umgestaltet.

Priorität: P1. Typ: validation. Bereich: accessibility.

## Referenzumfang

- F103: VoiceOver, Zoom, Voice Control, Switch Control, AssistiveTouch

## Konkrete Arbeit

- [ ] VoiceOver-Reihenfolge, Werte, Fokus und dynamische Updates prüfen
- [ ] Zoom/Dynamic Type sowie Kontrast und reduzierte Bewegung abnehmen
- [ ] Voice Control, Switch Control und AssistiveTouch mit der eigenen UI prüfen
- [ ] Gestenexklusive Aktionen per zugänglichem Control anbieten

## Abnahme

Face-Editor, Sperre, Timer, Kamera, Rezept und Verbindungen sind ohne präzise Wischgeste oder Sehvermögen bedienbar. Ergebnisse je Hilfsmittel dokumentieren.

## Testgrenze

Automatisierte Tests verwenden synthetische persönliche Daten und MockHome. Apple Home bleibt gesperrt, bis der Eigentümer die Einrichtung ausdrücklich fortsetzt. Keine Nachrichten oder Anrufe automatisch ausführen. Persönliche Accounts und physische Geräte werden gesondert und bewusst abgenommen.

Stand: 17. Oktober 2026. Quellen und ursprüngliche Referenzbilder werden nicht mit veröffentlicht. Build-Erfolg ist keine Originalgleichheit. Vollständige Zuordnung in [Docs/function-coverage.json](https://github.com/Olli0103/homeview/blob/main/Docs/function-coverage.json).


## Ruhender Timer: benanntes Accessibility-Control · 19. Oktober 2026

Belegcommit `66a5de8`, Produktcode `9ce13b5` · [Begrenzte Reproduktion und Gegenprüfung](https://github.com/Olli0103/homeview/blob/main/Docs/timer-accessible-controls.md) · [Quellen-/Bild-/Ergebnisbericht](https://github.com/Olli0103/homeview/blob/main/Docs/verification/accessible-timer.json).

Die zwei neuen Baseline-Ausführungen gegen unveränderten Produktcode scheitern auf iPad/iPhone am fehlenden benannten Control zum Einblenden. Ein regulärer SwiftUI-Button „Show timer controls“ stellt jetzt den aktuellen Countdown als Accessibility-Wert und einen Hinweis auf Pause/Fortsetzen/Löschen bereit. Er liegt ausschließlich im ausgeblendeten Zustand über der bisherigen Tippfläche und zeichnet keine neue sichtbare Geometrie. Countdown-Identifier und sichtbare Controls bleiben erhalten; Button und Flächentipp teilen dieselbe Interaktions-/Einblendaktion.

Danach bestehen sechs UI-Ausführungen: der neue Fall und die vorhandenen tatsächlichen Vier-Sekunden-/Touch-/laufenden-Timer-Fälle je Gerät. Wert10:56, Einblenden, Resume/Delete und Rückkehr zur Einrichtung geprüft; bestehende Fristrücksetzung und verborgenes Weiterzählen erhalten. Gesamte Historie acht UI-Ausführungen, sechs erfolgreich/zwei dokumentierte Baselinefehler, keine Skips oder Runtime-Warnungen. Fünf SDK-Builds grün. 197 Eingaben, 26 kompilierte App-/Widget-/Test-/Launch-Eingaben und installierte Appbytes gebunden. Core unverändert: 291 frühere Tests bei5f12 bleiben historische Ergebnisse mit68bytegleichen Core-/Testdateien, kein neuer Core-Lauf.

Die ganzen eingefrorenen ruhenden Viewports1592×1592(iPad)/1134×1134(iPhone) sind ohne Maske und Toleranz identisch: null geänderte RGB-Pixel/-Kanäle, auch PNG-Digests gleich. Das gilt für diese Referenzzustände, nicht als Original-/Geräteabnahme.36PNGs dekodiert, vier Kontaktübersichten und zwei vollständige Einblendbilder gesichtet, zehn eigene Bilder veröffentlicht. Drei externe Archive vollständig zurückgelesen.

Eine zusätzliche eigene offscreen AppKit-AX-Vorbereitung kompilierte, erreichte mit dem gewählten Traversal jedoch nur den Root-AXGroup-Knoten. Null Assertions und kein accessibilityPerformPress ausgeführt; Ursache nicht bestimmt. Daraus wird weder ein Produktfehler noch ein bestandener macOS-/Hilfsmittelnachweis abgeleitet. Keine Systemhilfsmittel oder Berechtigungen eingeschaltet.

**#73 bleibt OPEN; F103 bleibt ohne Parity-Abnahme.** Belegt ist das benannte Simulator-AX-Element mit Wert und Touch-Aktion, nicht tatsächliche VoiceOver-/Voice-Control-/Switch-Control-/AssistiveTouch-Bedienung, Fokus/Reihenfolge/Ansagen, Dynamic Type/Zoom/Kontrast oder sämtliche zentralen Flows. Keine echten Konten, Kamera, Mikrofon, Systemalarme oder neuen System-Live-Activities verwendet. Keine Home-Anbindung; ursprüngliche Kriterien unverändert.


## Footer-Trefferflächen · 20. Oktober 2026

Veröffentlicht mit `951364c`, Produktcode `e6a7c54`. [Reproduktion und Grenzen](https://github.com/Olli0103/homeview/blob/main/Docs/footer-hit-regions.md) · [Messbericht und eigene Bilder](https://github.com/Olli0103/homeview/blob/main/Docs/verification/timer-hit-regions.json).

Der vollständige öffentliche XCTest-Flächen-Audit meldete im sichtbaren Timerzustand auf beiden Geräten vier zu kleine Footer-Controls: Faces, Apps, Assistant und Control Center, etwa 17–22 × 17–19 Punkte. Sie haben jetzt native 44 × 44-Punkte-Trefferflächen ohne Überschneidungen. Der äußere 30-Punkte-Layout-Slot bleibt erhalten. Tatsächliche Taps am oberen/rechten/unteren Rand öffnen alle vier eindeutigen Ziele, auch außerhalb dieses Slots. Der ungefilterte Audit ist auf beiden Simulatoren leer.

Die finalen vier UI-Ausführungen bestehen; gesamte Historie 16 Ausführungen, zehn erfolgreich und sechs dokumentierte frühere Fehler. Zwei dieser Fehler betreffen ausschließlich die numerische Frame-Messung knapp unter 44 Punkten; finaler Test mit 1e-9-Punkt-Toleranz, keine Lockerung des Audits oder der Navigations-/Rand-Taps. Fünf SDK-Builds am identischen Produktcode bestanden. Ganze eingefrorene Timer-Viewports auf iPad/iPhone ohne Maske oder Pixeltoleranz exakt unverändert, einschließlich ihrer Position/Größe im vollständigen Screen. 28 PNGs dekodiert, zehn Übersichten gesichtet, zehn eigene Bilder veröffentlicht. Alle fünf Archive und installierten Appbytes zurückgelesen. Core unverändert, kein neuer Core-Lauf.

**#73 bleibt OPEN.** Das ist keine Abnahme anderer Ansichten, tatsächlicher Hilfsmittel, Fokus/Ansagen, Dynamic Type/Kontrast oder physischer Geräte. Ursprüngliche Kriterien und F103 ohne Parity bleiben unverändert. Keine echten persönlichen Daten, Mikrofon/Kamera, Systemalarme oder neuen System-Live-Activities verwendet. Keine Home-Anbindung.


## Rezept-/Koch-Trefferflächen · 20. Oktober 2026

Veröffentlicht mit `956ec75`, Produktcode `4c932da`. [Reproduktion und Grenzen](https://github.com/Olli0103/homeview/blob/main/Docs/recipe-hit-regions.md) · [Messbericht und eigene Bilder](https://github.com/Olli0103/homeview/blob/main/Docs/verification/cooking-hit-regions.json).

Vollständige öffentliche XCTest-Flächen-Audits für Rezeptcover, Zutatenliste und Kochschritt: vorher auf dem iPhone sechs etwa 18 Punkte hohe Zutaten-Buttons sowie zu kleine Handoff-/Timeraktionen; auf beiden Geräten eine winzige passive Fortschrittsanzeige. Die acht Aktionen erhalten skalierungsbewusste, nach oben gerundete native Mindesthöhe von 44 Punkten. Zutaten bleiben scrollbar. Der vollständige Fortschritt gehört zum vorhandenen Schritttext, dekorative Punkte sind eine nicht interaktive Canvas-Zeichnung. Keine Audit-Ausnahmen oder entfernte Information.

Final alle acht UI-Ausführungen erfolgreich; alle sechs ungefilterten Befundlisten leer. Echte Rand-Taps schalten erste/letzte Zutaten, starten den eigenen lokalen Fünf-Minuten-Timer und öffnen den Handoff-Angebotsdialog, ohne ein Angebot abzusenden. Fortschritt aktualisiert sich auf „Step 2 of 3“, die Timerliste bestätigt den tatsächlich erzeugten Timer. Fünf aktuelle SDK-Builds erfolgreich. Das gesamte Rezeptcover bleibt auf beiden Geräten pixel- und PNGbytegleich. Zutaten-/Kochlayout wächst absichtlich; dort keine Pixelgleichheit behauptet.

Gesamte Historie: 22 UI-Ausführungen, 15 erfolgreich, sieben dokumentierte frühere Fehler (einschließlich zu kleiner erster Rundung und leerem Knoten trotz accessibilityHidden). Keine Testlockerung, Skips oder Runtime-Warnungen. Drei Archive und installierte Appbytes vollständig zurückgelesen; 50 PNGs dekodiert, sechs Übersichten gesichtet, 18 eigene Bilder veröffentlicht. Core unverändert, kein neuer Core-Lauf.

**#73 bleibt OPEN.** Tatsächliche Bedienungshilfen, Fokus/Ansagen, Dynamic Type/Kontrast, andere Ansichten, Original-/Hardwareabnahme und echte Zwei-Geräte-Übergabe bleiben offen. Ursprüngliche Kriterien und F103 ohne Parity bleiben unverändert. Nur eigene synthetische Daten; keine Mikrofon-/Kameraaufnahme, Systemalarme oder neuen System-Live-Activities. Keine Home-Anbindung.


## Assistenten-Trefferflächen und echte Randaktionen · 20. Oktober 2026

Veröffentlicht mit `4ec0108`, Produkt-/Teststand `4137efd`. [Reproduktion und Grenzen](https://github.com/Olli0103/homeview/blob/main/Docs/assistant-hit-regions.md) · [Messbericht und 18 eigene Bilder](https://github.com/Olli0103/homeview/blob/main/Docs/verification/assistant-hit-regions.json).

Ungefilterte öffentliche XCTest-Flächen-Audits in vier Ansichten: Ausgangsansicht, sichtbare Kartenaktionen nach Scrollen, Quellen- und Fähigkeitenblatt. Vorher iPad drei kleine Kopf-Controls (Capabilities 149,5×18, Readout 105×18, Spracheinstellungen 20,5×16 Punkte), iPhone zwei (Readout 104,67×18, Einstellungen 21,33×16). Zusätzliche Größenassertionen stoppten beim Rezeptknopf mit 20,5/20,33 Punkten Höhe und Done mit 40,5/40,67 Punkten Breite. Diese vier Fälle stoppten VOR dem jeweiligen Rand-Tap; keine falsche Behauptung eines bereits gelieferten Fehl-Taps. Der Quellenchip funktionierte schon am oberen Rand. Beide Blätter bestanden den öffentlichen Audit bereits vorher.

Nur zwei Produktansichten geändert: drei Kopf-Controls mit nativen 44-Punkte-Labels/Content Shapes; Rezept- und Folgeknopf-Flächen innerhalb statt außerhalb ihrer Labels; Done 44×44. Kein globaler Button-Fix, keine Änderung an Quellenchip, Museumslink, Speak, Fähigkeitenblatt, Spracheinstellungsinhalt oder AppModel.

Final alle 18 UI-Ausführungen erfolgreich, neun Methoden je Gerät; alle acht vollständigen Auditlisten leer. Tatsächliche Kopf-Rand-Taps öffnen Fähigkeiten/Einstellungen und erreichen ausschließlich die verweigerte Mock-Freigabe ohne reale Authentifizierung/Sprache. Rezept-Rand öffnet die Rezeptansicht ohne den Timerentwurf auszuführen. Quellenrand öffnet, Done-Rand schließt, Folgenrand wählt die Beispielagenda. Synthetischer fertiger Sprachentwurf und Tastaturrotation bleiben grün. Mindestgröße mit unveränderter 1e-6-Punkt-Zahltoleranz, Taps zwei Punkte innerhalb des Randes, kein center-tap-Fallback oder Audit-Ausnahme.

Gesamte Historie 30 UI-Ausführungen: 23 erfolgreich, sieben frühere Fehler; keine Skips oder Runtime-Warnungen in diesen Zusammenfassungen. Fünf aktuelle SDK-Builds bestanden, 206 Quellen/je28 kompilierte Eingaben/installierte Appbytes gebunden, beide 234-Eintrag-Archive vollständig zurückgelesen. 110 PNGs dekodiert, vier Übersichten und zwei weitere eigene Bilder in voller Auflösung gesichtet. AppModel und72 Core-/Testdateien bytegleich; 301 Modelltests historisch, kein neuer Core-/nativer Modelllauf behauptet.

**#73 bleibt OPEN.** Keine Abnahme verborgener Controls, aller Provider/Beispiele, tatsächlicher Bedienungshilfen, Fokus/Ansagen/Dynamic Type/vollen Kontrasts, physischer Geräte oder Original-Parity. Kopfzeile wächst absichtlich; keine Pixelgleichheit. Quellenblatt in vollständigen Screens; der zusätzliche Viewport-Crop ist nur die Hintergrund-Referenzfläche. Museumslink nicht aktiviert. Originalkriterien und F103 ohne Parity unverändert. Keine realen Konten, Aufnahme, Systemalarme oder neuen Live-Activities. Keine Home-Anbindung.


## Weltuhr: native Trefferflächen · 20. Oktober 2026

Veröffentlicht mit `1702a56`, Produkt `5504a02`, korrigierte Test-Scrollhilfe `e6a95a4`. [Messungen und Grenzen](https://github.com/Olli0103/homeview/blob/main/Docs/world-clock-hit-regions.md) · [Prüfbericht mit 20 eigenen Bildern](https://github.com/Olli0103/homeview/blob/main/Docs/verification/world-clock-hit-regions.json).

Vollständige ungefilterte öffentliche Hitflächen-Audits für Städteübersicht, Auswahl und gefilterte Suche: iPad bereits vorher drei leere Listen; iPhone meldete Add mit 43,26 × 13,65, Done mit 26,88 × 13,65 und vier Entfernen-Symbole mit 13,86 × 13,86 Punkte. Der zusätzliche strikte Randtest stoppt auf beiden Geräten vor dem ersten Tap: Add-Höhe 28,52 / 13,65 statt 44. Vorher acht Ausführungen, drei PASS/fünf FAIL. Keine Behauptung fehlgeschlagener bereits gelieferter Rand-Taps.

Weltuhr-Aktionslabels erhalten skalierungsberechnete native Mindestflächen und rechteckige Trefferbereiche. Auswahlzeilen und ein nur dort aktiviertes Close-Sizing erfüllen zusätzlich den strikten 44-Punkte-Randvertrag; sie waren keine öffentlichen Vorher-Auditbefunde. Andere AppHeader-Aufrufer behalten Standard 48, kein globaler RoundButton-/Pill-/Style-Wechsel. Suchfeld, Stadt-/Zeitmodell, Filterung und Persistenzlogik unverändert; Close-Kreis/-Symbol darf am Telefon wachsen. Keine Pixelgleichheit.

Abgenommen sind zwölf Ausführungen über zwei eingefrorene Prüfstände, **kein einzelner grüner Zwölferlauf**: Zehn PASS in der ersten Produktrunde, darunter alle sechs leeren Auditlisten und bestehende Kathmandu-Persistenz-/Zwei-Kalendertage-Regressionen. Zwei Randfälle stoppten dort an einer unerreichbaren acht-Punkte-Testmarge über der ersten bündigen Zeile. Nur diese beiden Fälle nach Testkorrektur erneut ausgeführt und bestanden; Produktbytes unverändert. Gemessene volle Sichtbarkeit, mindestens 44 × 44, reale Zwei-Punkte-Rand-Taps auf Add/Done/London-Auswahl/London-Entfernen/Close und tatsächliche Übergänge. Rechtecke bestätigen bündigen Listenanfang. Kein Mittelpunkt-Fallback oder Modellshortcut.

Gesamthistorie: 22 Ausführungen, 15 PASS / sieben frühere FAIL, keine Skips/Runtime-Warnungen. Fünf aktuelle SDK-Builds. 206 Quellen, je 28 kompilierte Eingaben und installierte Appbytes gebunden; drei Archive vollständig zurückgelesen. 52 PNGs dekodiert, sechs Übersichten und sechs zusätzliche Vollbilder gesichtet. 301 Modelltests/50 AppModel-Assertions bei `2b223b7` sind historisch; 72 Core-/Coretest-Dateien, AppModel und Probe unverändert, kein neuer nativer Modelllauf behauptet.

**#73 bleibt OPEN, F103 partial/parity=false.** Nur die drei sichtbaren Weltuhr-Zustände auditiert, nicht alle offscreen Städte/Plattformen. Tatsächliche VoiceOver-/Voice-Control-/Switch-Control-/AssistiveTouch-, Fokus-, Ansagen-, Dynamic-Type-, volle Kontrast-, Hardware- und Originalabnahme bleiben offen. Keine Systemzeitänderung, echte Daten, Freigaben, Aufnahmen oder neue Systemaktivität. Keine Home-Anbindung.


## Lokale Wecker: native Trefferflächen und AX-Zustand · 20. Oktober 2026

Veröffentlicht mit `ded9715`, Produkt-/Teststand `974c460`: [Korrektur und Grenzen](https://github.com/Olli0103/homeview/blob/main/Docs/alarm-hit-regions.md) · [Prüfbericht mit 16 eigenen Bildern](https://github.com/Olli0103/homeview/blob/main/Docs/verification/alarm-hit-regions.json).

Drei vollständige ungefilterte öffentliche Hitflächen-Audits prüfen einen ausgeschalteten Standardwecker, zwei Einträge und die leere Liste. iPhone-Befunde: Löschen etwa 10,29 × 11,76 Punkte, bei zwei Zeilen beide Controls. Leere iPhone-Liste und alle drei iPad-Listen bereits vorher ohne Befund. Separater strikter Randfall: iPhone stoppt vor erstem Toggle-Tap bei 23,94 Punkten Höhe; iPad erreicht Toggle oben/unten und Add oben, stoppt anschließend vor neuem Delete-Tap bei 24,54 Punkten. Vorher acht Ausführungen, vier PASS/vier FAIL. Nicht gelieferte Rand-Taps werden nicht als fehlgeschlagene App-Ereignisse ausgegeben.

Nur AlarmsView geändert: native Mindestflächen im Toggle-/Delete-/Add-Label, opt-in Close-Größe; keine Änderung an globalem Pill, RoundButton, Style oder AppHeader. Uhrzeit im Toggle-/Delete-Label, expliziter Toggle-Wert On/Off zusätzlich aus Quellenprüfung gehärtet. Keine behauptete frühere VoiceOver-Reproduktion. Stunden-/Minuten-Picker, AppModel, Speichern und Systemplanung unverändert; identische Uhrzeiten können weiterhin gleiche Beschriftungen haben.

Final acht UI-Ausführungen bestanden: sechs komplette Auditlisten leer und 14 tatsächlich gelieferte Randaktionen auf beiden Geräten. Off → On → Off als AX-Wert, konkrete ursprüngliche/neue Eintragsidentitäten, Hinzufügen/Löschen/erneutes Hinzufügen und Rückweg geprüft. Sichtbarkeit, Viewport-Enthaltenheit, mindestens 44 × 44 Punkte und echte Koordinaten zwei Punkte innerhalb des Randes; kein Mittelpunkt-Fallback oder Modellshortcut. Gesamthistorie 16 Ausführungen, zwölf erfolgreich/vier frühere Fehler, keine Skips oder Runtime-Warnungen. Fünf aktuelle SDK-Builds. 206 Quellen und je 28 kompilierte Eingaben mit installierten Appbytes gebunden; zwei Archive mit je 234 Einträgen vollständig zurückgelesen, 42 PNGs dekodiert, vier Übersichten und vier Vollbilder gesichtet. 72 Core-/Coretest-Dateien bytegleich zum historischen 301er-Lauf; kein neuer nativer Modelllauf und keine Umdeutung der Assistentenprobe zur Weckerabnahme.

**Nur synthetische Vordergrundwecker:** jeder Start `--uitesting`, niemals `--system-alarms`; vorhandener AppModel-Guard deaktiviert native Planung. Foreground alarm statt System alert enabled verlangt. Keine AlarmKit-Freigabe, native Systemalarmerstellung, Benachrichtigung, Audio- oder Hintergrundzustellung abgenommen, keine Zeit bis zum Ablauf vorgespult.

**#73 bleibt OPEN, F103 partial/parity=false.** Keine tatsächliche VoiceOver-/Voice-Control-/Switch-Control-/AssistiveTouch-, Fokus-, Ansagen-, Dynamic-Type-, volle Kontrast-, Hardware- oder Originalabnahme. Nicht alle 24/offscreen Einträge oder geöffnete Zeit-Picker geprüft. Keine echten Daten, Konten, Aufnahmen, Berechtigungsänderung oder neue Live-Activity. Keine Home-Anbindung.


## Lokale Erinnerungen: tatsächliche Ziele und Schreibfokus · 20. Oktober 2026

Veröffentlicht mit `896e23f`, aktuelle Produktoberfläche `e04faac`: [Reproduktionen, eigene Bilder und Grenzen](https://github.com/Olli0103/homeview/blob/main/Docs/reminder-hit-regions.md) · [quell-/binärgebundener Bericht](https://github.com/Olli0103/homeview/blob/main/Docs/verification/reminder-hit-regions.json).

Unveränderter Vorherstand: Der öffentliche ungefilterte hitRegion-Audit meldet auf dem iPhone beide Erledigen-Schaltflächen, beide Löschknöpfe und das Eingabefeld (gefüllt/mit Tastatur fünf, leer ein Befund). Die drei iPad-Listen sind bereits vorher leer. Ein zusätzlicher strenger 44-Punkte-Randtest stoppt auf beiden Geräten vor dem ersten Delete-Tap: nur 31,84 bzw. 15,12 Punkte Höhe. Kein tatsächliches Löschen aus diesem fehlgeschlagenen Baseline-Randversuch behauptet.

Der erste Fix macht alle sechs Auditlisten leer. Echte native Randaktionen finden trotzdem einen weiteren Fehler: Nach erfolgreichem gezieltem Löschen, Erledigt→Unerledigt und Leeren setzt der obere Rand des vergrößerten Eingabefeldrechtecks keinen Schreibfokus. Native Texteingabe scheitert auf beiden Geräten mit fehlendem Tastaturfokus. Dieser Produktstand bleibt historisch FAIL; nur große AX-Rechtecke wurden nicht als genügende Bedienbarkeit akzeptiert. Explizite Fokusbindung und gleichzeitige Feld-Tap-Geste korrigieren dies, ohne den Test zu lockern.

**Aktuell acht erfolgreiche UI-Ausführungen**, vier unveränderte Methoden auf beiden Geräten: sechs leere Auditlisten und 16 echte native Zwei-Punkte-Randaktionen mit vollständiger Viewport-Einschließung, mindestens 44 × 44 Punkten, Hittable-Status und tatsächlichen Folgezuständen. Ursprüngliches Delete erhält anderen Eintrag, Toggle liefert Completed/Not completed, zweites Delete leert, Eingaberand fokussiert, Softwaretexteingabe erzeugt zunächst nur Entwurf, separater Add legt exakten eigenen Eintrag an/leert Entwurf, Delete/Close funktionieren auch mit sichtbarer Tastatur. Zusätzliche AX-Erledigtwerte sind Quellcode-Härtung und final beobachtet, keine gesonderte ursprüngliche VoiceOver-Fehlerreproduktion.

Historie: 24 UI-Ausführungen; vorher 3 PASS / 5 FAIL, erster Fix 6 PASS / 2 FAIL, aktuell 8 PASS / 0 FAIL. 17 erfolgreich, sieben dokumentierte Fehler, keine Skips oder strukturierten Runtime-Warnungen. Fünf SDK-Builds mit aktuellem Fokusfix bestanden; die fünf Builds des vorherigen Stands nicht dafür eingesetzt. 206 Quellen, je 28 App-/Test-/Metadaten-/Starteingaben und installierte Appbytes gebunden; drei Archive mit je 234 Einträgen vollständig zurückgelesen. 56 PNGs dekodiert, sechs Übersichten und vier Vollbilder gesichtet, 16 eigene Vorher-/Nachherbilder veröffentlicht. 72 Core-/Coretestdateien bytegleich zum historischen 301-Test-Lauf bei 2b223b7; kein neuer Core-/Modellprozess behauptet.

Nur lokale RemindersView verändert; Speicher-/Profil-/Auth-/Modelldaten-/Add-/Toggle-/Delete-Algorithmen, EventKit und andere Ansichten unverändert. Add/Close dürfen im kleinen Canvas sichtbar wachsen; kein Pixelgleichheits-/Original-Parityanspruch. **#73 bleibt OPEN, F103 partial/parity=false.** Verbundene Geräte-/Read-only-Listen, lange/offscreen Inhalte, DynamicType, tatsächliche Hilfsmittel/Fokusreihenfolge/Ansagen/Kontrast/Hardware bleiben separat offen. Keine echten Daten, Quelle, Berechtigung, Systemalarme, Wiedergabe, Nachricht oder Anruf. Keine Home-Anbindung.


## Lokale Kalender-Tageswahl: native Ziele und Jahreswechsel · 20. Oktober 2026

Veröffentlicht mit `3bb885e`, Produktcode `eb0b65c`: [Reproduktion, eigene Aufnahmen und Grenzen](https://github.com/Olli0103/homeview/blob/main/Docs/calendar-hit-regions.md) · [Quellen-/Binär-/Ergebnisbericht](https://github.com/Olli0103/homeview/blob/main/Docs/verification/calendar-hit-regions.json).

- Vorher zwei vollständige ungefilterte öffentliche Hitflächen-Audits je Gerät: iPad beide leer; iPhone zunächst ein Befund für „2“, nach Auswahl des 27. Dezember zusätzlich „1“, also zwei. Keine sieben automatisch gemeldeten Befunde behauptet. Der strenge native 44-Punkte-Randtest stoppt auf iPhone vor dem ersten Tap bei 24,15 Punkten Breite. Auf iPad gelingen zuerst fünf Tageswechsel; dann stoppt die schmale „1“ bei 20,56 Punkten vor ihrem Tap. Diese tatsächlich gelieferten Teilaktionen bleiben erhalten, ohne den fehlgeschlagenen Gesamtfall umzubenennen.
- Nur CalendarView geändert: native Mindestmaße aus Canvas-Transform und rechteckige Content-Shape auf den wirklichen Tageslabels; Close verwendet vorhandenen Größenparameter. Datum/IANA/Woche, Auswahl- und Agenda-Algorithmen, Schriften/Tageskreise und andere Produktansichten unverändert. Kein globaler Design-/Canvas-Fix oder neuer Kalenderadapter.
- **Sechs finale UI-Ausführungen bestanden**, drei unveränderte Methoden je iPad/iPhone: vier leere Auditlisten und 18 tatsächliche native Zwei-Punkte-Randaktionen. Alle sieben Tage getrennt wählbar, benachbarte Ziele ohne Überlappung, genau eine Auswahl. Demo-Heute-Eintrag nur beim lokalen Heute, erneute Auswahl am unteren Rand des Vorjahrestags und Close erfolgreich. Nach Rückkehr bleibt das Face bei 1 / Today / January 2027. Fixture: 31. Dezember 2026 um 23:30 UTC, Pacific/Kiritimati; keine Systemuhr geändert.

Historie: zwölf UI-Ausführungen, acht erfolgreich, vier dokumentierte Vorherfehler; keine Skips oder strukturierten Runtime-Warnungen. Fünf aktuelle SDK-Builds bestanden. 206 Quellen und je 28 App-/Test-/Metadaten-/Starteingaben samt installierter Appbytes gebunden, beide Archive mit je 234 Einträgen vollständig zurückgelesen. 36 PNGs dekodiert, vier Übersichten und vier zusätzliche Vollbilder gesichtet, 14 eigene Bilder veröffentlicht. 72 Core-/Coretest-Dateien bytegleich zum historischen 301-Test-Lauf bei 2b223b7; kein neuer Core-/nativer Modelllauf behauptet.

**#73 bleibt OPEN, F103 partial/parity=false.** Nur lokale Demoagenda und zwei sichtbare Audit-Zustände, keine verbundenen Kalender/Refresh/Freigaben, alle Sprach-/Schriftgrößen oder Offscreen-Inhalte. Tatsächliche Hilfsmittel, Fokusreihenfolge/Ansagen, Kontrast, Hardware und Originalabnahme bleiben offen. Close ist zusätzliche finale Mindestzielprüfung, kein ursprünglicher automatischer Befund. Keine allgemeine Pixelgleichheit: Tagesabstände und Close dürfen auf kleinen Ansichten wachsen. Keine persönliche Quelle, Berechtigung, Nachricht/Anruf, Systemalarm oder neue Live-Activity. Keine Home-Anbindung.


## Demo-Musik: native Ziele und lesbarer passiver Fortschritt · 20. Oktober 2026

Belegcommit `337aaa6`, Produktcode `13bd448`, reiner Aufnahmehelfer `ef7a639`: [Befunde, eigene Bilder und Grenzen](https://github.com/Olli0103/homeview/blob/main/Docs/demo-music-hit-regions.md) · [Quellen-/Binär-/Ergebnisbericht](https://github.com/Olli0103/homeview/blob/main/Docs/verification/demo-music-hit-regions.json).

Vorher drei vollständige ungefilterte Hitflächen-Audits je Gerät. Bibliothek und Info bereits leer; Player meldet auf iPad die dünne unbenannte Fortschrittsanzeige, auf iPhone zusätzlich Bibliothek, Previous, Play und Next (fünf Befunde). Strenger nativer Randtest stoppt auf beiden Geräten vor dem ersten Next-Tap: 29,19 / 13,65 Punkte Höhe. Keine bereits gelieferten Baseline-Randaktionen oder Audiostörung behauptet.

Nur MusicView verändert: native Mindestflächen und Rectangle auf echten Previous-/Next-/Play-/Bibliothekslabels, vorhandenes optionales Close-Sizing. Die passive Leiste besitzt keine eigene Seek-/Slider-/Gestenaktion; sie bleibt sichtbar und zugänglich als Demo progress / 0 of 180 seconds, wird über die öffentlich belegte SwiftUI-Eigenschaft ausdrücklich nicht als assistives Interaktionsziel angeboten. Kein accessibilityHidden oder Auditfilter. Ein positiver Test verlangt vorhandenen Namen/Wert sowie keine Slider-/Buttonrolle. Wert ist der bestehende simulierte Demo-Zähler, kein echter AVAudioPlayer-Playhead. AudioEngine, AppModel, Fortschritts-/Titelalgorithmen, Katalogspieler, 72-Punkte-Infoknopf und gemeinsames Info-Blatt unverändert.

**Zehn Funktionsausführungen bestanden:** vier bytegleich erhaltene Methoden plus neuer positiver AX-Test je iPad/iPhone. Sechs Auditlisten leer; zehn echte native Zwei-Punkte-Randaktionen mit mindestens 44 Punkten, vollständiger Viewport-Einschließung und tatsächlichen Folgezuständen. Pausiertes Next→A Little Sunshine, Previous→FEVER DREAM; Info→richtige Demoquelle, normales Done→weiterhin Play; Bibliothek→drei eigene Titel, Close→persönliche Appansicht. **Play nur vermessen, nie aktiviert; kein Bibliothekstitel ausgewählt. Keine Wiedergabe-/Seek-/Akustik-/MusicKit-/Accountabnahme.**

Bildsichtung fand zusätzlich zu frühe Blattaufnahmen. Begrenzter Nachlauf ausschließlich desselben positiven AX-/Aufnahmetests: zwei weitere erfolgreiche Ausführungen mit identischen 18 App-/Widgetdateien, keine Produktänderung und keine erneute breite Suite. Sofortiges und zwei Sekunden späteres Ganzdisplaybild zeigen verschiedene Einblendpositionen, obwohl Accessibility bereits dieselben Endrechtecke meldet. Tatsächliche Uptime/Frames aufgezeichnet, spätere vollständige Bilder gesichtet; nicht allein als app.screenshot-Zuschnitt oder Produktionsfehler umgedeutet. Akzeptiert sind zehn Funktionsausführungen plus zwei gesonderte Aufnahmeausführungen, keine einzelne grüne Zwölfer-Suite.

Historie: 20 UI-Ausführungen, 16 erfolgreich und vier dokumentierte Vorherfehler; keine Skips oder strukturierten Runtime-Warnungen. Fünf SDK-Builds des identischen Produktcodes bestanden. 206 aktuelle Quellen, je 28 App-/Widget-/Test-/Metadaten-/Starteingaben und installierte Appbytes gebunden; drei Archive mit je 234 Einträgen vollständig zurückgelesen. 52 PNGs dekodiert, sechs Übersichten und vier zusätzliche Vollbilder gesichtet, 14 eigene Bilder veröffentlicht. 72 Core-/Coretest-Dateien bytegleich zum historischen 301-Test-Lauf bei 2b223b7, kein neuer Core-/Modelllauf.

**#73 bleibt OPEN, F103 partial/parity=false.** Nur Demo-Steuerung; tatsächliche Hilfsmittel/Fokusreihenfolge/Ansagen/große Schrift/Kontrast/Hardware/Originalabnahme fehlen. Keine allgemeine Pixelgleichheit: Zielgeometrie und Close dürfen wachsen. Kein neuer Lyrics-/Animationsumfang und keine Änderung der #58-Grenzen. Keine persönlichen Daten, Konten, Berechtigungen, Wiedergabe, Nachrichten/Anrufe, Systemalarme oder neuen Live Activities. Keine Home-Anbindung.


## Browser: native Trefferflaechen und unterer Gestenstreifen - 20. Oktober 2026

Veroeffentlicht mit `13782ca`: [Befunde, Korrektur und Grenzen](https://github.com/Olli0103/homeview/blob/main/Docs/browser-hit-regions.md) und [Quellen-/Bild-/Ergebnisbericht](https://github.com/Olli0103/homeview/blob/main/Docs/verification/browser-hit-regions.json).

Vorher zwoelf UI-Ausfuehrungen: drei PASS/neun FAIL. Vollstaendige ungefilterte Audits fuer lokales Kochbuch, Seitenhistorie, wartendes Laden und Rezeptauswahl. iPad:0/1/0/0 Befunde, iPhone:3/4/2/1. Native Back-/Adress-/Saved-/Read-Recipe-/Cancel-Flaechen beanstandet; eigene HTML-Links ohne Befund, nicht ausgenommen. Vier strikte Randfaelle stoppen schon vor dem ersten Randereignis: Adressfeldhoehe 30,51 / 14,70 Punkte; Back 12,60 x 21,89 / 5,88 x 10,29 Punkte. Keine Aussage, dass eine noch nicht gelieferte Aktion fehlgeschlagen sei.

NativeBrowserContent bekommt native ceil(44 / canvasScale)-Label-/Textfeldrahmen und rechteckige Trefferflaechen, ausdruecklichen Rand-Eingabefokus sowie vorhandene lokale Load/Stop-/Close-Groessenparameter. Kein globaler Design-/Controller-/Policy-/HTML-/Importalgorithmus-Fix. Erster Kandidat: elf von 14 PASS, drei iPhone-Fehler archiviert. Die tatsaechlichen Fehlerhierarchien platzieren den Slow-page-Linkmittelpunkt y = 610,55 im unsichtbaren unteren Home-Gestenstreifen y = 608,92-619. Die Stop-Faelle zeigen weiterhin die alte Seite; der vorhandene Sicherheitstest landet nach Scrollen tatsaechlich im persoenlichen Home-Screen. RootView nimmt deshalb ausschliesslich die Safari-App-Route vom unteren Streifen aus; Close und Fussnavigation bleiben erhalten. Tests und eigene HTML-Fixtures unveraendert, keine Auditfilter oder Testlockerung.

Abschluss: **14 UI-Ausfuehrungen bestanden**, sieben je Geraet, acht vollstaendige Auditlisten leer. 22 echte native Zwei-Punkte-Randaktionen mit mindestens 44 x 44 Punkten, Hittability und voller rechteckiger Viewport-Enthaltenheit plus konkreten Folgezustaenden: Back/Forward, Stop, Saved, Close, Adressfokus/Tippen, abgewiesene HTTP-Adresse/Load, Read Recipe, Cancel, erneutes Lesen und Auswahl des zweiten lokalen Rezepts. Bestehender Scheme-/HTTP-/Scroll-Sicherheitstest besteht wieder. Fuenf aktuelle SDK-Builds gruen; keine neuen Core-/separaten nativen Modelllaeufe behauptet.

Historie: 40 UI-Ausfuehrungen, 28 PASS / zwoelf fruehere FAIL, keine Skips oder strukturierten Runtime-Warnungen. 206 Quellinputs und je 28 kompilierte Eingaben samt installierten Appbytes gebunden; drei Archive mit je 234 Eintraegen vollstaendig zurueckgelesen. 63 PNGs dekodiert, sechs Uebersichten und vier finale Voll-Viewports gesichtet; 19 eigene Bilder veroeffentlicht. Groessere Leisten lassen weniger Webinhalt gleichzeitig sichtbar; keine allgemeine Pixelgleichheit oder 44-Punkte-/Sichtbarkeitsgarantie fuer alle DOM-Links/Websites.

**#73 bleibt OPEN, F103 partial/parity=false; urspruengliche Kriterien unveraendert.** Tatsaechliche Hilfsmittel, Fokusreihenfolge/Ansagen, grosse Schrift/Kontrast, Hardware und Originalabnahme fehlen weiterhin. Nur gebuendeltes HTML und zweifach testflag-geschuetzte In-Memory-Seiten; unsichere Eingabe vor jedem Request abgewiesen. Keine externen Seiten, persoenlichen Daten/Accounts, Downloads, Berechtigungen, Kamera/Mikrofon/Audio, Systemalarme/neuen Live Activities oder Nachrichten/Anrufe. Keine Home-Anbindung.


## Demo-Kamera: Touchflächen und lesbarer Talkback-Zustand · 20. Oktober 2026

Veröffentlicht mit `d12375a`: [Reproduktion, Korrektur und Grenzen](https://github.com/Olli0103/homeview/blob/main/Docs/camera-hit-regions.md) · [Messbericht und eigene Bilder](https://github.com/Olli0103/homeview/blob/main/Docs/verification/camera-hit-regions.json).

Vorher: 16 UI-Ausführungen, sieben bestanden und neun dokumentierte Fehler. Vier vollständige ungefilterte Hitflächen-Audits je Gerät für Vierer-/Neunerraster, Detailansicht und eingeschalteten Mock-Talkback. Der Umschalter ist im strikten Randfall nur 28,52 Punkte hoch auf dem iPad bzw. 13,65 auf dem iPhone. Das iPhone-Talkback-Control misst 39,06 Punkte. Der rein informative Status „Demo still“ wird auf dem iPhone fälschlich als zu kleines interaktives Ziel erfasst; sein Text bleibt nach der Korrektur lesbar und ist ausdrücklich nicht interaktiv. Der Talkback-AX-Wert fehlt auf beiden Geräten. Fehlgeschlagene Randfälle belegen jeweils die zuerst fehlgeschlagene Vorbedingung, nicht eine noch gar nicht ausgeführte Aktion.

Korrektur nur in CameraAndCommunication.swift: lokale ceil(44/canvasScale)-Mindestflächen für den Rasterumschalter, opt-in Header-Close und Detailcontrols; App-Raster passt seine Reihen an den tatsächlich verbleibenden Platz an. Das Kamera-Face behält seine bisherige Geometrie. Mock-Talkback liefert „On (demo)“/„Off (demo)“ als AX-Wert; bestehende Rücksetzung beim Wechseln bleibt erhalten. Kein globaler Design-/Root-/Capture- oder Home-Fix.

Abschluss: **20 UI-Ausführungen bestanden**, zehn je Gerät, einschließlich derselben acht neuen Fälle und zweier vorhandener Demo-/Nacht-/Offlinefälle. Acht vollständige Auditlisten leer. 14 echte native Zwei-Punkte-Randaktionen für Show 9, letzten Slot, Rückkehr zum Raster, Header-Close, Talkback ein/aus und Detail-Close; Mindestflächen von 44 × 44 Punkten, Hittability, volle rechteckige Viewport-Enthaltenheit sowie konkrete Zielzustände geprüft. Neun Rasterflächen überschneiden sich nicht. Talkback-Wert/Reset nach Rasterwechsel und Schließen/erneutem Öffnen beobachtet. Fünf SDK-Builds bestanden. Keine neuen Core-/separaten nativen Modellläufe behauptet.

Das gesamte eingefrorene Kamera-Face ist auf beiden Geräten ohne Maske oder Toleranz exakt RGBA-unverändert: null veränderte Pixel/Kanäle. Der erste Kandidat besteht 18 von 20 Ausführungen; zwei Restfehler stoppen an überlappenden AX-Rechtecken des Neunerrasters. Zwei zusätzliche reine Messausführungen mit unveränderten Produktbytes zeigen je sechs überlappende Rechteckpaare. Das sichtbare Raster ist getrennt, die AX-Rechtecke sind quadratisch und höher als die Zeilen. Explizite Höhe, Clipping und rechteckige Trefferform im Button-Label korrigieren dies; ursprüngliche Tests und ungefilterte Audits werden nicht gelockert. Der vorübergehende zusätzliche Messfall ist nach Archivierung entfernt; ursprüngliche neue Testbytes sind im Abschluss wieder exakt identisch.

Vollständige Historie: 56 funktionale UI-Ausführungen, 45 bestanden / elf frühere Fehler, plus zwei erfolgreiche reine Messausführungen (58 insgesamt). 206 Quellinputs und je 28 kompilierte Eingaben samt installierten Appbytes gebunden; vier Archive mit je 234 Einträgen vollständig zurückgelesen. Eigene Bilder und Bildauswertung im Bericht. Keine allgemeine Pixelgleichheit der bewusst angepassten App-/Detailansichten behauptet.

**#73 bleibt OPEN, F103 partial/parity=false; ursprüngliche Kriterien unverändert.** Tatsächliche Hilfsmittel, Fokusreihenfolge/Ansagen, Dynamic Type/Zoom/Kontrast, physische Geräte und Originalabnahme bleiben offen. Vier generierte lokale Standbilder wiederholen sich in neun Demo-Slots; keine neun echten Kameras oder Streams. Mock-Talkback verändert nur lokalen Zustand/Toast, kein Mikrofon oder Audio. Keine Home-Anbindung, echte Kamera, Berechtigungsabfrage, Konten, Nachrichten/Anrufe oder Systemkonfiguration.

## Einstellungen: native Touchflächen und Werte · 20. Oktober 2026

[Begrenzter Fix und getrennte Prüfstände](https://github.com/Olli0103/homeview/blob/main/Docs/settings-hit-regions.md), Commit `72d1b118a7664a47ef82e3fdc72d665e29a19e45`. Lokale Einstellungs-Tasten/Close und beide Mock-Regler berücksichtigen die tatsächliche Canvas-Skalierung; Boolean-Zeilen liefern On/Off. Standard-UIKit-Slider behalten native Bedienung, der sichtbare Modellwert wird gegen AX-Wert und echte Verstellung geprüft. Vorherbefunde bleiben vollständig erhalten, einschließlich zweier früherer Slider-Fehler und eines getrennten ungültigen Test-Prädikats. Letzter betroffener Lauf: acht UI-Ausführungen, zehn leere ungefilterte Auditlisten und fünf SDK-Builds bestanden. Frühere 18/20 UI-Ergebnisse bleiben an ihrem älteren Checkpoint gebunden; kein neuer grüner 20er-Gesamtlauf behauptet. Wetterfeld/Einheitenwähler, echte Hilfsmittel, Dynamic Type und Hardware bleiben offen. Kein Fotopicker, Systemalarm oder externer Link aktiviert; Connect/Disconnect nur synthetischer Fixture-Provider. Keine Home-Anbindung. **#73 bleibt OPEN, Originalkriterien und F103-Parity=false unverändert.**

## Control Center: native Touchflächen · 20. Oktober 2026

[Begrenzter Fix und vollständige getrennte Prüfstände](https://github.com/Olli0103/homeview/blob/main/Docs/control-center-hit-regions.md), Commit `05ce77a3ba23d4ab87210200181a78d29118c0bd`. Close, Plus/Minus, Slider und beide Pill-Tasten berücksichtigen die Canvas-Skalierung; Inhalt ist scrollbar, Header bleibt fest. Zehn UI-Ausführungen, vier leere ungefilterte Auditlisten und 24 tatsächliche native Rand-Taps bestanden, zusätzlich acht Slider-Verstellungen gegen sichtbare Modellwerte. Fünf SDKs bestehen bei exakt gleichen Produktinputs; danach nur Testhelfer korrigiert. Zwei bewusst unterbrochene Testhelfer-Fehlläufe und ein separater Audit-Diagnoselauf bleiben vollständig getrennt erhalten; nicht ausgeführte Fälle zählen nicht als PASS. Keine neuen Coretests, keine Original-/Hardware-/echte Hilfsmittelabnahme. Ausschließlich lokale App-Dimmung und Demo-Audio, keine Systemhelligkeit/-lautstärke oder WLAN-Konfiguration, kein Mirror-/Kamera-/Medienstart und keine Home-Anbindung. **#73 bleibt OPEN; ursprüngliche Anforderungen und F103-Parity=false unverändert.**

## Face-Editor: tatsächliche Touchflächen und Auswahl · 20. Oktober 2026

[Begrenzter Fix, getrennte Prüfstände und Grenzen](https://github.com/Olli0103/homeview/blob/main/Docs/editor-hit-regions.md), Commit `8f00b9e1c67b2ca34ae69fb2c86452411d70af15`. Lokale Label-Mindestflächen für Done/Face/Farbe/Typeface/Slotliste, volle Flow-Labelaktion bei erhaltenem nativen Switch und geschützte Inline-Datum-Trefferfläche ohne Verschieben der gemalten Slotrechtecke. 28 UI-Ausführungen in zwei getrennten Auswahlen mit identischen Quellen/Tests und 23 identischen kompilierten App-/Testdateien, 14 leere ungefilterte Auditlisten, 38 tatsächliche native Rand-Taps und fünf SDKs bestanden. Normaler Switch-Tap, Auswahlfamilien, Inline-Off/Clock/Neustart und richtige Navigation bestehen ebenfalls. Frühere echte Flow-Rand- und Sheet-Skalierungsfehler bleiben dokumentiert. Kein neuer Core-Gesamtlauf, kein pauschaler Vollsuite-/Pixel-/Original-/Hardware-/Hilfsmittel-PASS. Andere kleine Previewflächen und sehr schmale Fenster bleiben explizit offen; Listenalternativen sind vergrößert. Keine AX-Aktionen versteckt, keine echten Quellen oder Home-Anbindung. **#73 bleibt OPEN, F103 partial/parity=false; #7 und ursprüngliche Kriterien unverändert.**

## Wetter-Einstellungen: reale Trefferflächen und fokussierte Sichtbarkeit · 29. Oktober 2026

[Quellengebundener Fix dbbab82](https://github.com/Olli0103/homeview/blob/dbbab8239827313b20d43ee550071b48e53eb8c9/Docs/weather-settings-hit-regions.md).

Zwei neue Methoden auf unverändertem Produkt je iPad/iPhone zunächst rot: Segmenthöhe nur 42,45/20,16 native Punkte; Stadtfeld meldete hittable, echter oberer Rand brachte jedoch weder Tastatur noch Fokus. Öffentlicher UISegmentedControl in echter Mindesthöhe, SwiftUI-Texteingabe mit gebundenem Fokus und realem Rechteck-Trefferbereich korrigieren das. Unskalierte Wetter-Sheets behalten ihre bisherigen Picker.

Nach zunächst zehn erfolgreichen UI-Ausführungen/fünf SDKs zeigt die Bildkontrolle zusätzlich die iPad-Fokuslücke. Vor weiterer Produktänderung verschärfter Sichtbereich besteht auf iPhone, scheitert auf iPad bei beiden Rändern (nur ca. 1,25 pt Abstand zur Viewportunterkante). Settings scrollt das Feld nun bei Fokus/Größenwechsel in die Mitte; final vollständig im bereits zuvor verwendeten sicheren Scrollbereich.

**Final: zehn erfolgreiche UI-Ausführungen, fünf eindeutige Methoden je Größe, vier echte Rand-Fokussierungen mit Eingabe, sechs Einheiten-Randänderungen, zwei leere ungefilterte Hitflächen-Audits und fünf SDKs.** 225 Quellen, kompilierte/Launch-/Steuereingaben archiviert und vollständig zurückgelesen; installierte Apps geprüft. 30 native PNGs dekodiert, vier Übersichten/zwei volle fokussierte Aufnahmen gesichtet, acht eigene Bilder veröffentlicht. 88 Core-/Package-/Testdateien unverändert: kein neuer Core-PASS. Elf erfolgreiche/fünf fehlgeschlagene frühere Ausführungen bleiben separat erhalten, nicht zu einem finalen Gesamtlauf umetikettiert. Reiner Testneubau änderte einen Assets.car-Hash; keine unzutreffende 19/19-Bytegleichheit behauptet.

**#73 bleibt offen; F103 partial/parity=false.** Keine neue tatsächliche Hilfsmittel-, Dynamic-Type-/Kontrast-/Zoom-, Hardware- oder Originalabnahme, keine Home-Anbindung oder realen persönlichen Daten/Accounts, Aufnahmen, Wiedergabe, Alarme, Nachrichten oder Anrufe.

## Wetter-App und Stadtdialog: native Mindestflächen · 29. Oktober 2026

[Quellengebundener Folgestand 88b068e](https://github.com/Olli0103/homeview/blob/88b068e/Docs/weather-surface-hit-regions.md).

Ich habe die separat verbliebenen Wetter-App-/Dialog-Controls vermessen und korrigiert: Quellenlink zuvor nur 8,40/17,91 native Punkte hoch, iPhone-Städte-/Modustasten 32,76×32,76 bzw. 32,76×23,94. Im unskalierten Dialog lagen Feld/Segmente bei 34/32, Done/Update bei etwa 20 Punkten. Die modalen Auditlisten waren dabei bereits leer; eine leere Liste wurde ausdrücklich nicht als 44-Punkte-Nachweis akzeptiert. Bestehende Auswahl-/Update-/Eingabe-/Abbruchaktionen funktionierten schon vor der Größenkorrektur.

Nur die transparente Link-Trefferfläche wächst, nicht die Quellenzeile. Fünf iPad-Städte-/Modus-Rechteckmessungen sind zum unangetasteten Vorherstand exakt gleich; kein Ganzbild-/Original-Pixel-PASS. Dialog- und Settings-Picker teilen den öffentlichen nativen Baustein mit getrennten Kennungen, im unskalierten Dialog ohne Canvas-Umrechnung. Keine Daten-/Provider-/Generationslogik geändert.

**Final: zwölf erfolgreiche UI-Ausführungen, sechs eindeutige Methoden je Größe, 26 neue echte Randaktionen, vier bearbeitete Dialogfelder und vier leere ungefilterte App-/Dialog-Auditlisten.** Bisherige Settings-Einheiten, Forecast/Ortswahl, verspäteter Antwortabschluss und zentriertes Demo-Layout bestehen mit. 225 gleiche Quellen vor/nach Prüfung und gegen Commit verifiziert; kompilierte App-/Test-/Launch-/Steuereingaben archiviert/vollständig zurückgelesen und installierte Apps geprüft. 32 native PNGs dekodiert, vier Übersichten/zwei ganze fokussierte Bilder gesichtet, zehn eigene Bilder veröffentlicht. Fünf SDKs bestanden; 88 Core-/Package-/Testdateien unverändert, kein neuer Core-Lauf.

Drei frühere erfolgreiche/fünf fehlgeschlagene UI-Ausführungen bleiben separat erhalten. Vier ursprüngliche sowie ein späterer Header-Scrollhelferfehler sind zusätzlich zu den echten Größen-/Auditbefunden klar getrennt; korrigierte natürliche Header-Navigation lockert weder Mindestgröße, Audit noch Randaktion. Der zu hohe erste Quellenzeilen-Kandidat wird nicht als akzeptierter Stand ausgegeben.

**#73 bleibt offen, F103 partial/parity=false.** Attribution-Link nur vermessen/auditiert, URL nicht geöffnet. Keine vollständige Hilfsmittel-, Dynamic-Type-/Kontrast-/Zoom-, Hardware- oder Originalabnahme; keine reale Wetterverbindung, persönlichen Accounts, Home-Anbindung, Aufnahme, Wiedergabe, Systemalarme, Nachrichten oder Anrufe.


## Wetter-Quellenlink: tatsächliches OS-Ziel · 29. Oktober 2026

[449a3ea · getrennter Nachweis](https://github.com/Olli0103/homeview/blob/449a3ead340a7a0d4a6191194924b9fedf3a513b/Docs/weather-attribution-os-route.md). Ich habe auf iPad/iPhone je den oberen und unteren Rand tatsächlich berührt: vier Wechsel von HomeView zu vorher nicht im Vordergrund befindlichem Safari, jeweils exakter Host `open-meteo.com` in der nativen Adressanzeige. Zwei finale UI-Ausführungen bestanden. Alle 19 Produktdateien bytegleich zu `88b068e`; nur der UI-Test ergänzt. Keine neuen Core-/SDK-Läufe; die vorherigen zwölf UI-Ausführungen/fünf SDKs bleiben ein eigener Quellenstand.

Zwei erste Selektorfehler bleiben erhalten: obere Berührung öffnete Safari schon dort, aber der Test suchte ein nicht vorhandenes natives Feld namens URL. Tatsächliche iOS-27-Feldkennungen und Richtungsmarker beobachtet, nur Test korrigiert, exakter Hostvergleich erhalten. Untere Ränder in diesen Fehlversuchen nicht ausgeführt. Alle vier Eingabearchive vollständig zurückgelesen, installierte Apps und 225 finale Quellen vor/nach Test sowie gegen Commit/Remote geprüft. Vier native Bilder dekodiert, zwei Übersichten gesichtet; Websitebilder privat.

**#73 bleibt offen, F103 partial/parity=false.** Frühere Aussage „URL nicht geöffnet“ gilt für `88b068e`, nicht für diesen getrennten Nachweis. Untere Safari-Aufnahmen beim Nachweis noch weiß; korrektes OS-Ziel ist kein vollständiger Lade-/Verfügbarkeits- oder Webseiten-Netzwerkbeleg. HomeViews Wetterprovider bleibt synthetisch. Keine Anmeldung, Standortfreigabe, Home-Anbindung oder neue Hilfsmittel-/Original-/Hardwareabnahme.


<!-- homeview-update:assistant-system-text-size-20261029 -->
## Assistenten-Systemschrift und Done-Rechteck · 29. Oktober 2026

[b3da92c](https://github.com/Olli0103/homeview/commit/b3da92c) · [Native Vorher-/Nachhermatrix und Grenzen](https://github.com/Olli0103/homeview/blob/b3da92c/Docs/assistant-dynamic-type.md) · [Quellen-/Kategorien-/Pixel-/Archivbindung](https://github.com/Olli0103/homeview/blob/b3da92c/Docs/verification/assistant-dynamic-type.json).

Tatsächliche eigene Simulator-Kategorie large gegen accessibility-extra-extra-extra-large, Befehle vor/nach zurückgelesen und beide Originalwerte in finally wiederhergestellt. Vor Produktänderung 165 Produktinputs exakt 8457538. Vorhandener semantischer Caption-Kontrolltext wächst; lokale Antwort sowie synthetische On-device-Frage/-Antwort bleiben dagegen auf beiden Geräten exakt gleich hoch. Vorab definierte Messvergleiche für sechs Textrollen-/Gerätekombinationen scheitern. Normal-Done-AX-Rechteck nur etwa 40×20 Punkte, mittiger Tap bereits funktionsfähig; größte Schrift dort schon größer als44×44. Zwei Test-only-Baselines (8 und12 Ausführungen) mit je zwei historischen Done-Methodenfehlern erhalten, keine zusätzlichen erfundenen Font-UI-Methodenfehler.

Nur zwei Produktdateien: öffentliche ScaledMetric-Werte für drei Textrollen (einschließlich derselben ausstehenden Fragenrolle), ursprüngliche Normalgrößen erhalten; Done-Minimum44×44 und ContentShape innerhalb des Labels. Keine Face-/Modell-/Aktions-/Sprachfreigabe geändert. Danach alle sechs Textvergleiche mit positiver Kontrolle grün; Texthöhen inklusive Umbruch wachsen, keine reinen Fontgrößenfaktoren behauptet. Alle vier normalen Antwort-Viewports strikt RGBA-pixelgleich, null abweichende Kanäle; normale Wiederholungsbilder schon vor Produktänderung ebenfalls identisch. Normales Einstellungsblatt darf wegen vergrößerter Done-Zeile anders liegen.

**18 aktuelle UI-Ausführungen bestanden**: zwölf Größenmatrix-Ausführungen (3Methoden×2Kategorien×2Geräte), sechs vorhandene Read-/On-device-/echte OS-Sheet-Snapshot-Regressionen. Null aktuelle Fehler/Skips/strukturierte Runtimewarnungen. Fünf frische SDKs und sechs Tooling-Tests grün;233 Quellen, aktuelle kompilierte Eingaben/installierte Apps,14 UI-Eingabearchive und73 SDK-Dateien einschließlich vollständiger iOS-Metadaten geprüft/zurückgelesen.89 Core-/Package-/Testinputs bytegleich zum405-Test-Stand, kein neuer Core-Lauf.38 historische UI-Ausführungen insgesamt,34 erfolgreich/vier alte Done-Methodenfehler, keine38er-Erfolgssuite.118 PNGs dekodiert,18 Übersichten/sechs volle Bilder tatsächlich gesichtet,16 eigene Bildkopien bytegeprüft; rohe OS-/Fremdkarten privat.

Erster zu strenger Analyseguard für unveränderte intrinsische AX-Textbreite scheitert am iPhone (307,3→310 Punkte, Container unverändert378, Seitenabstand34). Fehler erhalten; qualifiziert gegen unveränderten Container/Seitenabstand und darin liegende Textrechtecke, weil AX umbrochene Zeilen statt Layoutwrapper umschließt. Höhenziel mindestens1,25 und strikte Normalpixel bleiben unverändert; keine Produkt-/UI-Teständerung für diese Auswertung. Bei größter Schrift liegt Text teils außerhalb des Scrollclips, iPhone-On-device-Bild am bisherigen automatischen Antwortende; keine Vollsicht/Durchscroll-/VoiceOver-Garantie.

**#73 bleibt OPEN, F103 partial/parity=false.** Nur diese drei Rollen, zwei Kategorien und das gemessene Done-Rechteck abgenommen. Andere Header-/Eingabe-/App-Flows, Zoom, tatsächliche VoiceOver/Voice-Control/Switch-Control/AssistiveTouch-, Kontrast-/Fokus-/Geräte- und Originalabnahmen bleiben getrennt. Keine gesonderten Done-Außenrand-Taps behauptet. Geräte-/Signing-Hold und Home-Sperre unverändert; keine realen Konten, Modellinferenz, Aufnahme, Wiedergabe oder Nachrichten/Anrufe. Gesamtbacklog läuft weiter.


## Fortsetzung 29. Oktober · Done/Cancel und native Toolbar-Gegenkontrollen

[Veröffentlicht: bc8d419](https://github.com/Olli0103/homeview/commit/bc8d4199f4c620a2c8eb1b3a2eef232c642e82ab) · [Bericht und Geometrien](https://github.com/Olli0103/homeview/blob/main/Docs/secondary-hit-regions.md).

- Sieben app-eigene Label-Rechtecke jetzt mindestens44 native Punkte; Handoff berücksichtigt Canvas-Skalierung. Beide Ecken je Ziel auf iPhone/iPad tatsächlich ausgeführt; Entwürfe und Rückkehrzustände erhalten.
- Musik-/Timer-System-Toolbars unverändert: gemeldete AX-Höhe36 ist kein Beweis einer nur36 Punkte hohen Touchfläche. Acht echte Gegenprüfungen an Ecken eines44 Punkte hohen Proberechtecks, jeweils zwei Punkte außerhalb der AX-Höhe, bestehen. Keine pauschale flächige Hit-Test-Abnahme.
- 36 aktuelle UI-Ausführungen/18 Methoden und fünf aktuelle SDK-Builds vollständig bestanden, sechs Tooling-Tests;233 gelieferte Testeingaben exakt zum Commit, zehn UI-Archive/installierte Apps und SDK-Artefakte nach Bytes geprüft.89 Core-/Package-Eingaben unverändert zum früheren405-Test-Stand, kein neuer Core-Lauf.
- 112 historische+aktuelle Ausführungen64PASS/48FAIL, nicht112 aktuellePASS. Vier ursprüngliche Sprach-AX-Vorbehalte, native AX-Bounds-Fehler und der verworfene Toolbar-Label-Kandidat bleiben getrennt erhalten.232 PNGs dekodiert,24 Kontaktübersichten/acht volle Bilder tatsächlich geprüft; sechs eigene Bilder veröffentlicht.
- Kein Reset, Handoff-Angebot, echter Mikrofonzugriff, Abspielen, Konto, Nachricht, Anruf oder Home. Profil-Editor-Kontrast wird als separater Softwarebefund weiterbearbeitet; keine vollständige Hilfsmittel-/Kontrast-/Original-/Geräteabnahme. Issue/F103 bleiben offen/partial, parity=false; Geräte-/Signing-Pause unverändert.


## Fortsetzung 29. Oktober · Profil-Editor-Kontrast

[Veröffentlicht: 3aa94a6](https://github.com/Olli0103/homeview/commit/3aa94a6ba65ac7e09083e9ba97e6ab998b5a30a7) · [Bericht/Regionen/Bilder](https://github.com/Olli0103/homeview/blob/main/Docs/personal-editor-contrast.md).

- Vier eigene statische Textrollen, zwei ruhende Öffnungen je iPhone/iPad:16 Vorhermessungen selbst maximal<1,31:1. Nach lokaler Color.primary-/Dark-Schema-Korrektur alle16 über der unveränderten4,5:1-Grenze; Haupttexte17–18:1, sekundärer Hinweis etwa6:1. Zwei native helle Kontrollen21:1. Kein nachträglich angepasstes ROI-/Masken-/Schwellenkriterium.
- Acht aktuelle UI-Ausführungen/vier Methoden und fünf aktuelle SDKs vollständig bestanden; sechs Tooling-Tests. Gemessene Texte/Geometrien exakt erhalten, Root-Viewports innerhalb der Läufe und zwischen Vorher/Aktuell0veränderteRGBA-Kanäle. Done-Ränder, tatsächliche OS-Karten-Abdeckung, Konfiguration und Rückkehr geprüft.
- Nur HomeScreens.swift geändert,164 Produktdateien unverändert;233 getestete Commit-Eingaben exakt, acht UI-Archive/installierte Apps und SDK-Produkte nach Bytes geprüft.89 Core-/Package-Eingaben unverändert zum früheren405-Test-Stand, kein neuer Core-Lauf.46 PNGs dekodiert, acht Kontaktübersichten/vier volle Bilder tatsächlich geprüft; vier eigene Bilder veröffentlicht.
- Zwei ursprüngliche abschließende Test-Routenfehler bleiben erhalten; Weg vor Produktänderung am tatsächlichen Home-Raster korrigiert. Compiler-only-Zwischenstand mit nur Color.primary hatte0UI-Läufe, nicht als Farb-PASS behauptet. Gesamt12UI historisch/aktuell10PASS/2alteFAIL, nicht12aktuellePASS.
- Begrenzte statische Screenshotkontrastprüfung, kein vollständiger WCAG-/Hilfsmittel-/Original-/Geräte-PASS. Keine Home-Anbindung, Accounts, Aufnahme, Wiedergabe, Nachricht oder Anruf. F103/Issue bleiben partial/offen, parity=false; Geräte-/Signing-Pause unverändert.


<!-- homeview-update:timer-dynamic-type-20261029 -->
## Timer-Systemschrift und erreichbare große Anordnung · 29. Oktober 2026

[8601338](https://github.com/Olli0103/homeview/commit/8601338d8ef0df63558cf0a1c5d30e9a0fbc9d13) · [Umfang, Messwerte und Fehlergeschichte](https://github.com/Olli0103/homeview/blob/8601338/Docs/timer-dynamic-type.md) · [Testpins, Zeitbelege, Quellen/Archive/Bilder](https://github.com/Olli0103/homeview/blob/8601338/Docs/verification/timer-dynamic-type.json).

Sechs Vorhermessungen blieben bei größter Accessibility-Systemschrift 1,00-fach hoch, obwohl semantischer Kontrolltext etwa fünfmal in der Höhe wuchs. Ich habe nur TimerView geändert: drei öffentliche ScaledMetric-Rollen, passende Auswahlhöhe, scrollbar geordnete Accessibility-Ansicht mit expliziten Controls. Titel etwa 2,81, Status 3,14 und Auswahl-Control einschließlich Padding 1,94-fach hoch; keine isolierten Glyphen-/Fontfaktoren behauptet. Pausierter 10:56-Wert unverändert; echter Pointer wählt Tea mit 03:00, dessen Löschen erhält Bread mit 10:00. Vier normale Viewports exakt RGBA-pixelgleich, null geänderte Kanäle; wiederholte Vorherkontrolle ebenfalls gleich.

**20 akzeptierte aktuelle UI-Ausführungen über zwei Testpins**, sieben eindeutige Methoden: zwölf Normal-/XXXL-Fälle, sechs andere Timerregressionen, zwei korrigierte Idle-Fälle. Die alte iPhone-Idle-Abfrage lag laut Log etwa 3,88–4,19 Sekunden nach der Eingabesynthese und garantierte kein Vor-Vier-Sekunden-Fenster. Genauer Ereigniszeitpunkt unbekannt, kein behaupteter Produkt-Regressionsbeweis. Nur Testzeitsteuerung danach monoton/budgetgebunden: Kontrolle 5,201/2,710 Sekunden beziehungsweise 5,210/2,736 Sekunden nach erster Eingaberückkehr/zweitem Eingabebeginn. Beide vollständigen Idle-/Rücksetz-/erneuten Ausblend-/Löschfälle bestanden. Alle 19 App-Bundledateien über diese Testkorrektur bytegleich; der ältere grüne iPad-Idle-Lauf wird nicht doppelt zu den 20 addiert. Produkt-Vier-Sekunden-Regel unverändert.

Fünf SDKs/73 Produktdateien und sechs Tooling-Tests am identischen Produktcode bestanden; danach ausschließlich die genannte UITest-Zeitsteuerung geändert. 233 finale Quellen, 164 andere Produktinputs unverändert, 89 Core-/Package-Inputs bytegleich zum bisherigen 405-Test-Stand; kein neuer Core-Lauf. 28 UI-Archive vollständig zurückgelesen; 210 PNGs dekodiert, 32 Übersichten/sieben volle Bilder gesichtet, 14 eigene PNGs bytegeprüft. Gesamte UI-Geschichte: 76 Ausführungen, 65 erfolgreich/elf frühere Fehler; keine 76er-Erfolgssuite. Frühere CGRect-Rundungs-, Text-Hittability-/Scroll- und AX-tap-Verweigerungen getrennt erhalten. Echte Pointerwirkung nach sichtbaren aktivierten Bounds belegt; keine Randpunktabnahme daraus.

Die zusätzliche Assetprüfung fand bereits im veröffentlichten 478f536 einen veralteten HomeScreens-Whole-Source-Hash. Gegen eb81e22 war ausschließlich PersonalHomeEditor geändert; DemoAlbumCover/übrige Abschnitte bytegleich. Qualifizierter Quellen-Refresh, Ressourcen/Rechte/historische Deklaration unverändert. Inventar und Backlog danach grün; kein pauschales Rechteurteil.

**#73 bleibt OPEN, F103 partial/parity=false.** Nur Default/größte Accessibility-Kategorie auf diesen Simulatoren geprüft; kein universeller Sprach-/Zwischenkategorien-/Titelumfang und keine echte VoiceOver-/Zoom-/Voice-Control-/Switch-Control-/AssistiveTouch-Abnahme. Timer-Einrichtung/Header und übrige Flows weiter offen. Kein neuer Alarm, Live Activity, Ton, Aufnahme, Konto, Anruf oder Home. Geräte-/Signing-Pause unverändert; Gesamtbacklog wird fortgesetzt.


<!-- homeview-update:timer-setup-dynamic-type-20261029 -->
## Timer-Einrichtung: skalierende Schrift, normale Ansicht unverändert · 29. Oktober 2026

[2b2c822](https://github.com/Olli0103/homeview/commit/2b2c82296543d562fc47077ee71a8100e3f4854d) · [Umfang und Gegenkontrollen](https://github.com/Olli0103/homeview/blob/2b2c822/Docs/timer-setup-dynamic-type.md) · [gebundene Ergebnisse/Bilder](https://github.com/Olli0103/homeview/blob/2b2c822/Docs/verification/timer-setup-dynamic-type.json).

Ich habe die sechs fehlenden Vergrößerungsbedingungen für Titel, Dauer und Start-Control korrigiert: vorher praktisch 1,00, jetzt etwa 2,8/1,7/1,76-fache native Rechteckhöhe (Start einschließlich Padding, keine reinen Fontfaktoren). Semantischer Kontrolltext wächst positiv. Header/Pill erhalten ausschließlich opt-in-Schriftgrößen mit unveränderten Defaults; große Timer-Einrichtung ist scrollbar mit expliziten Minus-/Plus-/Start-Controls und zweispaltigen Presets.

Acht echte Randaktionen waren bereits vorher erfolgreich und bleiben es: zwei gegenüberliegende inset-Punkte eines zentrierten nativen 44×44-Quadrats je Gerät/Kategorie, tatsächlicher 15-Minuten-Start/Pause/Löschen. Auch iPhone-AX-Höhe 37,38 erlaubt diese außerhalb des gemeldeten Rechtecks liegenden Taps. Daher kein erfundener physischer Trefferflächenfehler oder unnötiger Mindesthöhenumbau. AX-Geometrie bleibt getrennt; keine flächendeckende oder Voice-Control-Abnahme daraus.

20 aktuelle UI-Ausführungen/sechs eindeutige Methoden, fünf SDKs/73 Produktdateien und sechs Tooling-Tests am selben 233-Dateien-Quellpin 3f0db1c… bestanden, identische aktuelle kompilierte UI-Eingaben und installierte Appbytes geprüft. Keine Fehler/Skips/strukturierten Warnungen. Sechs normale Aufnahmen derselben Einrichtung (drei Fälle×zwei Geräte) exakt RGBA-pixelgleich; nicht sechs verschiedene Produktansichten. Zwei weitere normale Countdown-Aufnahmen stimmen mit 8601338 exakt überein. Vorhandene Rezept-/Timerregressionen durchlaufen gemeinsame Defaults und tatsächliche Aktionen.

Zwei Produktdateien geändert, 163 andere Produktinputs unverändert. 89 Core-/Package-Inputs bytegleich zum bisherigen 405-Test-Stand, kein neuer Core-Lauf. Zehn UI-Archive und SDK-Archiv vollständig zurückgelesen. 100 PNGs dekodiert, zwölf Übersichten/zwei volle Bilder gesichtet, sechs eigene PNGs bytegeprüft. Gesamte Paketgeschichte 36 erfolgreiche UI-Ausführungen: 16 Vorher/20 aktuell; sechs negative Vorher-Größenbedingungen sind keine zusätzlich erfundenen fehlgeschlagenen UI-Methoden. Schriftpräferenzen wieder large.

**#73 bleibt OPEN, F103 partial/parity=false.** Nur Default/größte Accessibility-Kategorie, benannter Ablauf und diese Simulatoren. Keine vollständige Sprach-/Zwischenkategorien-/Dauer-/Preset-Abnahme, keine echten Hilfsmittelsitzungen oder pauschale gemeinsame Komponenten-Parity. Kein Home, Konto, Aufnahme, Ton, neuer Systemalarm oder Live Activity. Geräte-/Signing-Pause unverändert. Weitere zentrale Flows werden fortgesetzt.

## Face-Editor: skalierende UI-Rollen und getrennte Glyphenmessung · 29. Oktober 2026

[Bericht](https://github.com/Olli0103/homeview/blob/main/Docs/face-editor-dynamic-type.md) · [Quellen und vollständige Prüfungen](https://github.com/Olli0103/homeview/blob/main/Docs/verification/face-editor-dynamic-type.json).

Fünf lokale UI-Schriftrollen skalieren; normale Ausgangsgrößen und Zifferblattgrafik unverändert. Vier Textrollen wachsen auf iPhone/iPad etwa2,6–3,2-fach. Der tatsächlich gerenderte Modular-Schriftzug wächst unter zwei separat deklarierten Schwarz-Kern-Masken etwa2,7-fach. Die ursprüngliche iPhone-Controlhöhen-Bedingung bleibt rot (1,24 statt1,3): gemeldetes Control inklusive Padding/44-Punkte-Floor ist keine isolierte Fontmetrik. Keine zusätzliche Polsterung nur für den Messwert.

Zehn aktuelle UI-Ausführungen/vier Methoden, fünf SDKs/73 Produktdateien, sechs Tooling-Tests am selben233-Dateien-Pin2c7b738… grün; identische kompilierte UI-Eingaben, installierte Appbytes,14 UI-Archive und SDK-Archiv zurückgelesen. Vier normale Pixelpaare exakt gleich (iPad-Top/Listenpose sind dasselbe ungescrollte Bild). Eine Produktdatei geändert,164 andere Produktinputs/89 Core-Inputs unverändert, kein neuer Core-Lauf.96 native PNGs dekodiert,16 Übersichten/zwei volle Bilder und eine Chipausschnittübersicht gesichtet; acht eigene PNGs veröffentlicht.

Vier frühere Testselektorfehler erhalten (Off ist kombinierter AX-Button, kein StaticText-Kind), vier korrigierte Vorherfälle bestanden mit zehn negativen Schriftbedingungen. Gesamthistorie18 UI-Ausführungen,14 bestanden/vier frühere Fehler, nicht18 aktuelle. Schriftpräferenzen wieder large.

Zwei Picker-Öffnungen ohne Auswahländerung, normaler Auswahl-/Inline- und echter OS-Snapshot-Read-back erhalten, Demo-Home68°. Kein Farbfix: gleicher Profil-Editor-Dunkelschriftfehler nicht reproduziert; heterogenes natives Glas qualifiziert die uniforme Kontrastmessung nicht. Keine pauschale Kontrast-,XXXL-Auswahl-,Flow-Options-,Original- oder echte Hilfsmittelabnahme. **#73 OPEN, F103 partial/parity=false.** Home-/Geräte-/Signing-Pausen bleiben. Weitere zentrale Flows werden fortgesetzt.
