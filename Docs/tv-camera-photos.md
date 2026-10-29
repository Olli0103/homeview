# Native TV-Kameras und fokussierbare Demo-Galerie

29. Oktober 2026 · Teilumfang [#79](https://github.com/Olli0103/homeview/issues/79). Offizielle tvOS27.0/24J360-Laufzeit, eigener Apple-TV-4K-Simulator. Keine echten Kameras, Fotos, Mikrofone, Konten oder Home-Anbindung.

## Konkrete Bedienlücke

Die Demo-Galerie zeigte auf Apple TV zwei Bilder, hatte aber keine fokussierbare Weiter-Aktion. Der Flächen-Tap ist kein nachgewiesener Remote-Pfad. **Nur tvOS** erhält deshalb einen expliziten **Next photo**-Button bei mehr als einem Bild. Eine volle native Fokuszeile macht ihn aus der Footer-Navigation erreichbar. Jeder Select wechselt genau einmal1→2→1; kein zusätzlicher übergeordneter TV-Tap-Handler. Der bisherige Touch-Handler auf anderen Plattformen bleibt unverändert.

Die TV-Einstellungen erklären die tatsächliche App-Grenze: keine System-Fotoauswahl in dieser App auf Apple TV; Demo-Bilder öffnen keine Fotomediathek. Das schließt nicht jede denkbare OS-/Geräte-Kamerafunktion aus. Die Prüfungen verbinden keine persönlichen Alben.

## Kamera-Gegenkontrolle und Fehlerstände

Vierer-/Neunerraster, gezielte Remote-Auswahl bis Kachel9, Detail, Demo-Talkback an/aus über Rasterrückkehr und Schließen funktionieren bereits **vor** der Produktkorrektur. Die Kamera-Produktdatei wurde nicht geändert.

Zwei frühe neue Testannahmen waren falsch: TV-AX-Aktivierungsflächen wurden vollständig auf die sichtbaren Bildgrenzen beschränkt, und ein Status-Label als `staticText` statt generischem AX-Element gesucht. Tatsächliche Bilder zeigen alle neun Kacheln innerhalb des Viewports; größere native Aktivierungsflächen sind nicht ihre sichtbaren Bildgrenzen. Beide Testkorrekturen erfolgten vor dem Produktfix. Der danach eingefrorene Zweier-Funktionsstand liefert **vorher1 Kamera-PASS /1 fehlender Galerie-Weiter-Pfad**, nachher beide PASS. Diese TV-Testdatei blieb durch alle Produktkandidaten unverändert.

Der erste Produktkandidat zeigte den Button rechts, verlor beim Remote-Fokusweg aber vorher das Face. Der zweite bestand alle zehn UI-Ausführungen, wurde dennoch nach Bildprüfung verworfen: Der native Fokusrahmen überlappte die Bildnummer um2,9Punkte. Der angenommene dritte Stand hat bei tatsächlich fokussiertem Button in beiden Bildzuständen **50,8Punkte Abstand**; die Bilder wurden zusätzlich groß gesichtet. Keine Original-TV-Geometrie oder Pixelparität behauptet.

## Aktueller Nachweis

**Zehn aktuelle UI-Ausführungen bestanden**, null Fehler/Skips/strukturierte Runtime-Warnungen:

- Sechs native TV-Methoden: neue Kamera-/Foto-Fälle sowie bestehende Fokus-Discovery, Home/All-Apps/Timer-Navigation, Timer Start/Pause/Löschen und lokale Browser-/Menügrenze.
- Je zwei bestehende iPhone-/iPad-Fotofälle: automatische gebündelte Galerie und tatsächlicher Demo-Portrait-/Schutzlayoutpfad, ohne Fotomediathek zu öffnen.

**Fünf aktuelle SDK-Builds** im frischen Ausgabeverzeichnis bestanden.231 Quellinputs vor/nach unverändert und mit den Ausführungen gebunden; zwölf UI-Archive vollständig gelesen, installierte Appbytes geprüft.163 von165 Produktquell-/Ressourcendateien unverändert zum veröffentlichten `833579f`; nur TV-Photofallback und Hinweis geändert.88Core-/Paket-/Testinputs exakt zum vorherigen398-Test-Stand, kein neuer Core-Lauf.

Asset-Prüfung:58 unveränderte Ressourcen/17Herkunftsinputs. Der veraltete Ganzdatei-Hash von `Faces.swift` wurde erst nach exaktem Rückrechnen des TV-Control-Blocks auf die vorherige Datei aktualisiert; keine neue Grafik-/Fontquelle oder historische Rechtefreigabe. [Herkunftsnachweis](verification/tv-photo-source-provenance.json).

161PNG dekodiert,18Kontaktbögen und acht zusätzliche volle Bilder tatsächlich gesichtet; zehn eigene Bilder veröffentlicht. Gesamthistorie36Ausführungen/30PASS/6alteFehler ist **nicht** die aktuelle Zehnerabnahme. Ein historischer iPad-Lauf enthält eine interne QoS-/Prioritätsinversionswarnung; sie bleibt erhalten, ohne bewiesene Ursache oder Behebung. [Quellen-, Archiv-, Geometrie-, Ergebnis- und Bildbindung](verification/tv-camera-photos.json); Rohbelege extern unter `research/homeview-tv-camera-photos-20261029`.

## Zusätzliche Build-Grenze

Ein inkrementelles iOS-Compiler-PASS hinterließ nur zwei statt fünf generierte App-Intent-Metadatendateien: Die SSU-YAML-/NLU-Dreiergruppe fehlte. Das70-Dateien-SDK-Archiv und Logs bleiben erhalten. Ein frischer iOS-Build **desselben** zweiten Quellenstands stellte sie wieder her. Die abschließenden fünf SDKs des dritten Stands wurden deshalb in einem frischen Verzeichnis erzeugt; alle73Produktdateien einschließlich der fünf iOS-Metadatendateien archiviert/zurückgelesen. Kein bewiesener Root Cause, keine neue OS-Shortcut-Ausführung und kein Beleg zuverlässiger inkrementeller Verpackung. Diese separate Softwaregrenze bleibt bei #74 nachzuprüfen.

## Offen

#79 bleibt offen für übrige Plattform-/API-/Gerätekriterien. Kameras sind generierte Standbilder, Talkback nur Mock-Zustand, Galerie eigene Demo-Bilder; TV-WebKit bleibt der separat bezeichnete lokale Fallback. Keine Live-Streams, persönliche Fotofreigabe, echte Remote-/Hardware- oder vollständige Original-Abnahme. Geräte-/Signing-Hold und Home-Sperre unverändert; übrige Softwarearbeit wird fortgesetzt.
