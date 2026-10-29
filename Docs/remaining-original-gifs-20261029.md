# Alle vier vorhandenen S07-GIFs eingeordnet

29. Oktober 2026 · Quellenarbeit für [#6](https://github.com/Olli0103/homeview/issues/6), [#19](https://github.com/Olli0103/homeview/issues/19) und [#36](https://github.com/Olli0103/homeview/issues/36). Kein neuer Produkt-/Original-Parity-/Geräte-PASS.

Nach der [ersten vollständigen Zweierprüfung](transition-reference-review-20261029.md) sind auch die zwei übrigen Original-GIFs des [archivierten TechRadar-Hands-on vom 14. Oktober](https://www.techradar.com/home/smart-home-hubs/ive-tried-apples-homeview-and-it-could-bring-my-smart-home-together-with-less-iphone-time) vollständig dekodiert und gegen das eingefrorene Datei-/Byte-/SHA-Manifest geprüft.

| Vorhandene Folge | Frames / kodierte Dauer | Sichtbarer Befund |
|---|---|---|
| `ZrX5EXJ3cpN3jSaC7GjMdX` | 110 / 7.700 ms | Rosa Numerals-artige Uhr mit weißen Zeigern; ab Frame81 Überblendung, ab87 Textantwort mit kleiner Nachrichtenkarte |
| `gzDpuc57ze2wh9jKhdFaRN` | 31 / 2.170 ms | Vollflächiges Vierer-Kameraraster ohne App-Kopf; aufwärtsgezogener Home-/Wetter-Vordergrund bei weiter sichtbarer Kamera-Hintergrundansicht; anschließend Scroll zu unteren Apps |

141 neue vollständige Frame-PNGs, acht tatsächlich gesichtete Kontaktbögen und vier zusätzlich groß gesichtete Frames. Zusammen mit den früheren158 ergeben sich **299 Frames / 20.930 ms über alle vier vorhandenen S07-GIFs**. Das sind weiterhin vier animierte Dateien, nicht vier Gestentraces. Quellenzahl24 und Referenzzustände51 bleiben unverändert. Originale und sämtliche abgeleiteten Referenzbilder bleiben privat; öffentlich nur [Hash-/Frame-/Zeit-/Kontextmetadaten](verification/remaining-original-gifs-20261029.json).

## Artikelkontext ist nicht der sichtbare Auslöser

Die gespeicherte Markdown-Extraktion enthält keinen ausreichenden Artikelhaupttext. Deshalb wurden zusätzlich die vorhandenen Rohtext-/HTML-Dateien gegen ihr eingefrorenes Manifest geprüft und der zugehörige Haupttext gelesen. Im HTML steht die Numerals-/Antwortfolge direkt nach dem Absatz zur Siri-Demonstration über Ankunftszeiten und Informationen aus Messages. Das stützt die **Einordnung als gezeigte Assistentenantwort**, nicht die Behauptung einer automatisch eingeblendeten Benachrichtigung. Der Artikel beschreibt an anderer Stelle ausdrücklich ein Gerät ohne Notifications. Der GIF selbst enthält weder Audio noch einen sichtbaren Aktivierungsvorgang; Wakeword, Eingabe, Wartezeit und automatisches Auslösen sind daraus nicht messbar. Die damalige journalistische Demo-Beschreibung ist zudem kein eigener aktueller API-Funktionsnachweis.

## Kamerahintergrund gegen aktuelle Struktur geprüft

Das Original beginnt ohne Kameras-App-Kopf. Das passt zum Kamera-**Face**, nicht zwingend zum Verlassen der normalen Kamera-App. In der Replik wählt `FaceView` für `.cameras` bereits `CameraGrid(isFace: true)`; `PersonalView` zeichnet das ausgewählte `FaceView` hinter dem Home-Raster. **Kein allgemeiner Fehler „vorherige App als Hintergrund verloren“ belegt.** Deshalb kein zusätzlicher Routen-/Snapshotcache und keine Produktänderung aus dieser Hypothese. Die genaue Unschärfe, Perspektive und Bewegungskennlinie sind mit Spiegelungen/Fingerverdeckung und70-ms-GIF-Intervallen nicht als native Originalparameter kalibriert.

## Verbleibend

Keine vollständigen Langsam-/Schnell-/Abbruchtraces, kein exakter Touchschwellwert oder Federverlauf, keine vollständige Numerals-Ziffernfamilie/Editoroptionen und kein echter Siri-/Messages-Zugriff. #6/#7/#19/#36 bleiben für ihre übrigen Kriterien offen. Snoopy bleibt [ausdrücklicher Rechte-Ausschluss](scope-exclusions.md); seine historische Medienklassifikation nimmt die Funktion nicht wieder in den aktiven Umfang auf. Unabhängige Softwarearbeit läuft weiter, Home-/Geräte-/Signing-Grenzen unverändert.
