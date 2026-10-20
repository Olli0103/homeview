# Eigene Antwortkarten für den lokalen Assistenten

20. Oktober 2026 · Teilumsetzung von [#36](https://github.com/Olli0103/homeview/issues/36). **Kein Siri-Anschluss, keine vollständigen dynamischen API-Karten und keine Original-Parity-Abnahme.**

## Referenz und bewusste Grenze

Die vorhandenen Originalzustände UI17, UI18 und UI24 zeigen eine weiße Antwortfläche mit gruppierten Kalenderzeilen, eine Wissensantwort mit Quellenchips und Bild sowie eine Rezeptvorschau. Sie belegen diese sichtbaren Typen, nicht alle Zwischenzustände, Quellen-/Aktionsregeln oder eine öffentliche Schnittstelle zu Siri. Die Originalbilder und -grafiken werden nicht mitgeliefert.

Die Umsetzung verwendet bestehende SwiftUI-, Canvas-, Menu- und Link-APIs, ohne zusätzliche Abhängigkeit oder Dienst. Eigene Vektorgrafiken zeigen eine blaue botanische Illustration und eine Suppenschüssel. Keine kopierten Original- oder Museumsbilder. Die Agenda enthält erfundene Namen und feste Beispieldaten. Die Rezeptkarte öffnet ausschließlich das bereits gebündelte Suppenrezept.

## Bedienung und Zustände

Im lokalen Modus öffnet **Answer examples** sechs klar gekennzeichnete Beispiele: Wissen/Bild/Quelle, Agenda, Rezept, Lade-Vorschau, kein Ergebnis und nicht verfügbares Ergebnis. Lade-Vorschau bedeutet ausdrücklich keinen laufenden Abruf. Die Folgeaktionen wählen nur ein anderes Beispiel; es gibt keine automatische Wiederholung oder angebliche Websuche.

Die Kartenauswahl erhält den ungesendeten Tipp- oder fertigen Sprachentwurf. Ein laufender Sprachvorgang kann keine Beispiele auswählen. Das Rezept öffnet erst nach **Open bundled recipe**; weder die Auswahl noch angezeigte Texte starten Timer, Home-Aktionen oder persönliche Abfragen. Ein danach ausdrücklich gesendeter lokaler Befehl behält seine bisherige Funktion.

Quellenchips öffnen zunächst ein lokales Erklärungsblatt. Der einzige externe Link ist ein fest definierter HTTPS-Museumsbeleg; erst ein zusätzlicher Link-Tap würde die Website öffnen. Die App lädt keine externen Kartenbilder oder Quellen beim Anzeigen. Der UI-Test öffnet diesen Link nicht.

Die Wissensaussage über Herschels Cyanotypie-Verfahren von 1842 wurde gegen den [Science-Museum-Gruppen-Katalog](https://collection.sciencemuseumgroup.org.uk/objects/co416960/album-of-cyanotypes-of-british-and-foreign-ferns) geprüft. Sie ist ein gespeichertes Beispiel, keine frisch recherchierte Modellantwort. Die Zeichnung ist als eigene Illustration, nicht als historischer Abzug bezeichnet.

## Trennung von Darstellung und Befehlen

Ein geschlossener Typ enthält nur bekannte Beispielarten, Quellen und Folgebeispiele. User-/Providertext wird nicht als Kartenformat, Markdown-Aktion, URL-Kommando oder Funktionsaufruf dekodiert. Der normale On-device-Modus bleibt reiner Text und bekommt keine Kalender-/Nachrichten-/Appdaten. Nur der feste Rezeptbutton darf den Rezeptpfad öffnen; das Modell prüft dabei aktive Assistentenoberfläche, lokalen Modus und tatsächliche Rezeptkarte erneut.

Karten bleiben im Arbeitsspeicher. Neue Antwort, Send, Navigation und persönliche Sperre verwerfen sie. Kein Speichern oder Wiederaufnehmen einer Karte über Prozessstart. Die vorhandenen Grenzen für Gespräche, Sprachfreigabe und persönliche Daten bleiben erhalten.

## Prüfung

Produkt-/Teststand `80ad73b`. **301 Coretests** bestanden bei `add551c`; die 72 Core-/Coretest-Dateien sind seitdem bytegleich. Dazu **44 Assertions gegen das tatsächliche AppModel**, ohne ersetzte Produktionsmethode, und fünf aktuelle SDK-Builds. Die Projekterzeugung liefert im externen Kontrollverzeichnis bytegleiche Projekt-, Scheme- und Info-Dateien.

Der erste UI-Pilot hatte sechs erfolgreiche Ausführungen und zwei Fehler am Quellenblatt. Die Bilder zeigten schwarzen Text auf dunklem Hintergrund; der sichtbare Done-Button war nicht unter seiner eigenen Kennung erreichbar. Die Korrektur gibt dem Blatt einen weißen Hintergrund und eigene Controls ohne übergeordnet vererbte Kennung. Eine zusätzliche Codeprüfung fand die mögliche Wiederherstellung des älteren Tippentwurfs statt des fertigen Sprachentwurfs: Die Kartenauswahl beendet jetzt die fertige Sprachsitzung ohne diese Wiederherstellung. Der neue synthetische Sprachfall verlangt Erhalt der Vorschau und unveränderten Mock-Wert vor Send.

Ein erster nativer Vorbereitungsbuild wollte einen privaten Modus-Setter verwenden und erreichte null App-Assertions. Der korrigierte Treiber benutzt die öffentliche Auswahlmethode; Produktionszugriffsschutz wurde nicht gelockert. Fehlerstände bleiben separat aufbewahrt.

**14 Abschluss-UI-Ausführungen bestanden**, sieben Methoden auf iPad und iPhone: Quellenblatt samt Done und Agenda-Folgekarte, explizite Rezeptaktion ohne Ausführung des Entwurfs, drei Statusbeispiele, neue Antwort/Navigation/Hintergrund, fertiger Sprachentwurf sowie bestehende Tastaturrotation und Gesten-/Scroll-Abgrenzung. Gesamtgeschichte getrennt: 22 Ausführungen, 20 erfolgreich und zwei historische Fehler. Keine Skips oder Runtime-Warnungen in diesen Ergebniszusammenfassungen; keine vollständige UI-Suite behauptet.

206 Quellen und 28 kompilierte Eingaben pro UI-Checkpoint unverändert; installierte Appbytes zurückgelesen. Fünf Archive vollständig geprüft. 136 PNGs dekodiert, vier Übersichten und zusätzlich acht eigene Bilder in voller Auflösung gesichtet. 22 ausgewählte eigene Bilder und sämtliche Grenzen im [Messbericht](verification/assistant-response-cards.json). Das finale Quellenblatt ist auf beiden Geräten weiß und lesbar. Wissens-/Rezeptbilder und Agenda sind sichtbar; früherer Text kann durch die bewusst gewählte Scrollposition oberhalb liegen. Keine Pixelgleichheit oder formale Kontrastabnahme behauptet.

## Weiter offen

Tatsächliche VoiceOver-/Switch-Control-Sitzungen, vollständiger Fokus-/Ansagen-/Dynamic-Type-/Kontrasttest, physische Geräte und Originalgeometrie/-animation. Keine produktive persönliche Kalenderantwort, Nachrichtensuche, dynamische Webantwort oder Quellenprüfung eines Live-Modells implementiert. Readout erhält den Antworttext, nicht automatisch die vollständigen Kartenzeilen. F046 bleibt teilweise und `parity_accepted=false`; #36 bleibt offen.

Nur eigene synthetische Beispiele und Mock-Befehle, keine realen Konten, Mikrofon-/Kameraaufnahme, Systemalarme oder neuen Live-Activities. **Keine Home-Anbindung.**

## Nachtrag: richtiges Rezeptziel

Der historische Kartenstand öffnete die allgemeine Rezeptansicht und konnte dadurch ein anderes ausgewähltes Rezept zeigen. [Der nachfolgende Teilfix](assistant-recipe-target.md) verwendet eine eigene schreibgeschützte Suppenansicht; die oben dokumentierten alten Messungen werden dadurch nicht nachträglich geändert.
