# Browser: native Bedienflächen und unterer Gestenstreifen

20. Oktober 2026 · Teilfix von [#73 / SYS-10](https://github.com/Olli0103/homeview/issues/73) · [Prüfbericht, Quellen und Bilder](verification/browser-hit-regions.json)

## Vorher: vollständige Befunde

Vier öffentliche XCTest-`.hitRegion`-Audits erfassen Startseite, Seitenhistorie, wartenden Ladeversuch und Rezeptauswahl. Jede Liste wird ungefiltert gespeichert, einschließlich Webinhalt; kein Element wird aus der Prüfung ausgeschlossen.

| Zustand | iPad-Befunde | iPhone-Befunde |
| --- | --- | --- |
| Lokales Kochbuch | 0 | 3: Adressfeld, Saved, Read Recipe |
| Zweite lokale Seite | 1: Back | 4: Adressfeld, Back, Saved, Read Recipe |
| Wartendes Laden | 0 | 2: Adressfeld, Saved |
| Zwei Rezeptkandidaten | 0 | 1: Cancel |

Die eigenen HTML-Links werden nicht beanstandet. Das beweist weder 44 Punkte für alle Weblinks noch barrierefreie externe Websites. Zwei zusätzliche strikte native Randfälle je Gerät stoppen vor ihrer ersten Randaktion: Adressfeldhöhe 30,51 Punkte auf iPad/14,70 auf iPhone; Back nur 12,60 × 21,89 beziehungsweise 5,88 × 10,29 Punkte. Ein tatsächlich gelieferter fehlgeschlagener Rand-Tap wird daraus nicht behauptet. Normale Fixture-Aufbauaktionen wurden ausgeführt.

Vorher zwölf UI-Ausführungen: drei PASS, neun FAIL. Auch eine leere öffentliche Liste ist kein strikter 44-Punkte-Nachweis.

## Begrenzte Korrektur

Nur NativeBrowserContent verwendet `ceil(44 / nativeCanvasScale)` für die tatsächlichen Label-/Textfeldrahmen. Back, Forward, Saved, Read Recipe und Cancel erhalten rechteckige Trefferflächen. Das vergrößerte Adressfeld setzt seinen Fokus ausdrücklich auch bei einem Rand-Tap. Load/Stop und Close verwenden die vorhandenen lokalen Größenparameter; andere Aufrufer und das globale Design bleiben unverändert. Symbole dieser runden Controls wachsen mit ihrer Größe. Keine allgemeine Pixelgleichheit behauptet; größere Leisten lassen weniger Platz für den scrollbaren Webinhalt.

Der erste Kandidat besteht elf von 14 Ausführungen: iPad vollständig, iPhone vier PASS/drei FAIL. Auf dem iPhone erreichen zwei Fälle den wartenden Ladezustand nicht; der bestehende Sicherheitstest verliert nach einem Scrollversuch die Webansicht. Diese Fehlläufe wurden vor einer weiteren Änderung archiviert.

Die tatsächlichen Fehlerhierarchien zeigen den Slow-page-Link bei y=601,1–620,0, Mittelpunkt 610,55. Der Viewport endet bei y=619; der unsichtbare globale Home-Gestenstreifen belegt mit 16 Referenzpunkten bei Skalierung 0,63 den Bereich y=608,92–619. Der Linkmittelpunkt liegt darin. Beide fehlgeschlagenen Stop-Fälle zeigen weiter die ursprüngliche lokale Seite statt Loading; die Hierarchie des Scrollfehlers zeigt tatsächlich den persönlichen Home-Screen. Das ist eine konkrete Touch-/Gestenkollision, kein nachgewiesener WebKit-Transport- oder Berechtigungsfehler.

RootView nimmt deshalb ausschließlich die Safari-App-Route vom unteren Home-Gestenstreifen aus. Browser-Close und die native Fußnavigation bleiben verfügbar. Tests, HTML-Fixtures, BrowserController, Navigation-/Transportpolicy, Rezeptimport und dessen Abbruchlogik sind bytegleich; kein DOM-Link oder Audit wurde versteckt oder vergrößert, um einen PASS zu erzeugen.

## Abschluss

- Derselbe eingefrorene Testbestand: 14 UI-Ausführungen bestanden, sieben je Gerät. Alle acht vollständigen Abschluss-Auditlisten leer.
- 22 tatsächliche native Zwei-Punkte-Randaktionen: je Gerät Back → erste Seite, Forward → zweite Seite, Stop → Loading stopped, Saved → Recent & Pinned, Close → persönliche Oberfläche sowie Adressfokus/Tippen, Load einer abgewiesenen HTTP-Adresse, Read Recipe, Cancel, erneutes Read Recipe und Auswahl des zweiten eigenen Rezeptes. Vor jedem Ereignis mindestens 44 × 44 Punkte, Hittability und vollständige rechteckige Viewport-Enthaltenheit geprüft; konkrete Folgezustände bestätigt.
- Der bestehende Sicherheitstest scrollt wieder innerhalb des Browsers und prüft abgewiesenes externes Scheme sowie HTTP-Adresse. Nur gebündeltes HTML und zweifach testflag-geschützte In-Memory-Seiten. Kein externer Request aus diesen Fällen.
- Fünf aktuelle SDK-Builds bestanden. Keine neuen Core- oder separaten nativen Modellläufe beansprucht. Historie insgesamt 40 UI-Ausführungen: 28 PASS und zwölf dokumentierte frühere FAIL; keine Skips oder strukturierten XCTest-Runtime-Warnungen.
- Drei Prüfstände mit je 206 Quellinputs und 28 App-/Widget-/Test-/Metadaten-/Launch-Eingaben gebunden, installierte Appbytes zurückgelesen. Drei Archive mit je 234 Einträgen vollständig zurückgelesen. 63 PNGs dekodiert, sechs Übersichten und vier finale Voll-Viewports gesichtet; 19 eigene Belegbilder veröffentlicht.

## Grenzen

#73 bleibt OPEN; F103 partial/parity=false, ursprüngliche Kriterien unverändert. Der Nachweis betrifft diese sichtbaren nativen Browserzustände, nicht jedes Webdokument, Hilfsmittel oder jede Plattform. Tatsächliches VoiceOver, Fokusreihenfolge/Ansagen, große Schrift, Kontrast, Zoom, Voice Control, Switch Control, AssistiveTouch sowie physische Geräte-/Originalabnahme bleiben offen. HTML darf weiterhin im Browser scrollen; ein leerer Audit beweist keine überall vollständig sichtbaren oder 44 Punkte großen Weblinks.

Keine persönlichen Daten/Accounts, Downloads oder externen Seiten, Kamera/Mikrofon/Audio, neuen Berechtigungen, Systemalarme, neuen Live Activities, Nachrichten/Anrufe oder Systemkonfiguration. **Keine Home-Anbindung.**
