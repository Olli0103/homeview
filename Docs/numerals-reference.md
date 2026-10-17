# Numerals: Runtime-Typografie und Zeiger

17. Oktober 2026 · #19 bleibt offen.

Der Einzelzustand nach UI10 verwendet jetzt die öffentliche gerundete
Systemschrift statt der bisherigen kantigen Systemvariante. Die „12“ ist schmaler
und leicht versetzt; 9/3 sitzen höher, die 6 ist größer, Datum und Randabstände sind
korrigiert. Es wird keine eigene Schriftdatei oder extrahierte OS-Kontur gebündelt.
Das ist eine Kalibrierung öffentlicher Runtime-Typografie, keine Behauptung, die
exakte Originalschrift identifiziert zu haben.

Die weißen Zeiger erhalten schmale Ansätze, eigenes Canvas-Relief und eine offene
farbige Nabe. Der Minutenzeiger reicht weiter nach außen. Die angenäherte
Ansichtsmessung auf 600 Einheiten lag beim Original bei etwa 267 und beim vorherigen
eigenen Stand bei etwa 239; die neue Länge gleicht diesen sichtbaren Unterschied
an. Der Stundenzeiger und die Standardparameter anderer Uhren bleiben unverändert.
Zeitwerte stammen weiterhin aus derselben Uhr-/Zeitzonenberechnung, nicht aus
festen gemalten Zeigerwinkeln.

## Medien-Folgeschritt

Die tatsächliche Sichtprüfung des vorherigen Layoutstands hatte eine angeschnittene
Artist-Zeile gezeigt. Die redundante „Demo music“-Zeile entfällt deshalb im eigenen
Demo-Musikwidget. Cover mit „DEMO“ und „Demo Artist“ kennzeichnen es weiterhin
sichtbar; verbundene Musik und Demo-Podcast behalten ihre Quellenzeile. Die neue
UI-Prüfung verlangt den vollständigen Artist-Text innerhalb des Scrollfensters;
das tatsächliche Bild wird zusätzlich gesichtet. Keine privaten Trackdaten eines
anderen Profils werden übernommen.

## Grenze

Exakte Originalschrift, sämtliche Uhrzeiten/Stilvarianten, Licht und physische
Darstellung bleiben offen. Ein Vergleich des einzelnen belegten Zustands beendet
weder #19 noch den Gesamtauftrag. Der vorangegangene gemeinsame 22er-UI-Lauf bleibt
an seinen früheren Quellstand gebunden und wird nicht als frischer Test dieses
geänderten Renders ausgegeben.

## Integrierter Nachweis

Numerals `35fc888` und Medienkorrektur `5cc126a`, integriert in `45383b5`:
104 Modelltests, vier gezielte UI-Fälle je iPad/iPhone (acht Ausführungen) und fünf
SDK-Builds bestanden. 116 Quellen vor/nach Prüfung und gegen den Mergecommit
identisch. Null UI-Fehler/Skips oder von XCTest gemeldete Runtime-Warnungen.
Die Auswahl umfasst Numerals-Referenzdatum und Fade-Sichtzustand, alternative
Home-Uhr/Thermostat, profilgetrennte Medienlayouts mit Neustart sowie explizite
Demo-Podcastwiedergabe/Navigation. Keine neue vollständige UI-Suite.

Die Bilder beider Größen zeigen die vollständige Artist-Zeile innerhalb des
Scrollfensters. Die ursprüngliche abgeschnittene Fassung bleibt als älterer
Prüfstand dokumentiert; sie ist nicht die akzeptierte Medienkorrektur.

[Quellen und Ergebnisse](verification/numerals-media-integrated.json) ·
[eigene Bilder und Digests](screenshots/goal-20261017/numerals-media-manifest.json).
