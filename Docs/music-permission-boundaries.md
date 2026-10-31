# Musik: Widerruf, Quellenwahl und überholte Audiostarts

31. Oktober 2026 · gemeinsames Medienpaket für [#57](https://github.com/Olli0103/homeview/issues/57) und die ergänzende Datenschutzgrenze [#67](https://github.com/Olli0103/homeview/issues/67).

## Quellenberechtigung und alte Metadaten

Die Musikverbindung prüft ihre Berechtigung jetzt auch nach einer wartenden
Autorisierung sowie an Bibliotheks-, Play-/Resume- und Abbruch-/Fehlergrenzen.
Widerruf leert Titel, Queue, Auswahl, Fortschritt und Gastfreigabe, fordert eine
Pause des eigenen Providers an und entfernt den Verbindungserfolg. Die gewählte
Quelle bleibt sichtbar. Zurückkehrende Rechte allein reaktivieren die betroffene
laufende Sitzung nicht; der Benutzer verbindet ausdrücklich erneut. Die bestehende
separate Wiederherstellung zuvor genehmigter Quellen beim App-Neustart wird nicht
durch eine neue dauerhafte Widerrufsliste ersetzt.

Generationen und Aktionskennungen schützen weiterhin neuere Suchen und Sitzungen:
Ein alter Callback darf keine neue Anfrage beenden oder deren Status ersetzen.
Es gibt keine neuen Permission-Prompts, Reads oder automatischen Playback-Retries
auf einem überholten Abschlussweg.

Sechs neue Coremethoden mit 18 kontrollierten Unterfällen scheiterten vor der
Korrektur mit 69 verletzten Assertions. Danach bestehen **85 relevante Coretests**,
einschließlich der vorherigen Kalender-/Reminder-, Abbruch-, Lock-, Quellen- und
Gastfreigabeverträge. Die Core-/Coretest-Dateien sind bis zum finalen Gate bytegleich;
spätere Änderungen betreffen App-Routing, Audiostart und die native Testinstrumentierung.

## Gewählte Quelle ist nicht gleich Verbindungserfolg

Mehrere AppModel-Projektionen, die App-Auswahl und das persönliche Medienwidget
benutzten bisher den Verbindungserfolg als Entscheidung zwischen Apple Music und
Demo. Damit konnte eine bewusst ausgewählte, aber nicht verfügbare Quelle wieder
zum Demotitel und zu einem Demo-Start führen. Diese Entscheidung folgt jetzt der
expliziten Quellenwahl: Unverfügbare Quellen zeigen Wiederverbinden, gesperrte
Quellen verlangen Geräteauthentifizierung. Der Assistent meldet dieselbe Grenze.
Erst ausdrückliches Trennen erlaubt wieder die getrennte Demoansicht.

Die gespeicherte Wahl einer Musikverbindung beendet außerdem das vorherige lokale
Demo-Start-/Playing-Modell und fordert Stop für dessen Audioweg an. Eine fehlgeschlagene
Speicherung wird nicht als Quellenwechsel ausgegeben.

Ein tatsächlicher AppModel-Host mit dem regulären FixtureDeviceDataProvider prüft
positive Bibliothek, abgewiesene Autorisierung und gesperrte Quelle. Derselbe
25-Assertions-Vertrag zeigte vorher zwei fehlgeschlagene Szenarien/14 verletzte
Bedingungen, nach der Routingkorrektur drei bestandene Szenarien. Keine Plattform-
Conditionals oder realen MusicKit-/Audiovorgänge in diesem Host. Der erste Versuch
wurde verworfen: Der vorhandene allgemeine Denial-Schalter verweigerte zuvor noch
keine Music-Autorisierung. Erst die korrigierte synthetische Freigabemethode und
deren qualifizierter Vorher-/Nachherlauf werden als Produktgegenprobe verwendet.

## Noch nicht angelaufene Demo-Tasks

Eine zweite gemeinsame Startgrenze war unabhängig vom Provider vorhanden:
Musik-/Podcast-Tasks prüften ihre Generation erst nach dem Audioaufruf. War vorher
bereits Stop, ein zweites Toggle oder ein Quellenwechsel erfolgt, konnte der
überholte Task trotzdem den Backend-Aufruf ausführen. Beide Tasks prüfen jetzt
zusätzlich vor dem Aufruf Abbruch und aktuelle Generation.

Eine eigenständige native Probe verwendet den tatsächlichen AppModel-Code mit
einem ausdrücklich symbolischen Audio-Backend und zählt zusätzlich den Eintritt
in den originalen Task. Vorher scheiterten fünf von sieben Szenarien allein an der
Startzulassung; beide positiven Startfälle bestanden bereits. Das ist ein
Admission-Nachweis, keine Messung von AVAudioPlayer, realem Queue-Laufzeitverhalten
oder hörbarer Unterbrechung. Ein erster Harness-Compile ohne den mit auszutauschenden
Fehlerenum erzeugte null ausgeführte Szenarien und bleibt als Vorbereitung erhalten.
Nach der Korrektur bestehen dieselben sieben Szenarien mit allen 49 Bedingungen;
der tatsächliche Task-Eintritt ist in jedem Prozess genau einmal beobachtet.

## Gate und Grenzen

[Exakte Checkpoints, Ergebnisse, Quellen-/Installationsbindung und Archive](verification/music-permission-completion-20261031.json).

Der sichtbare Ablehnungs-/Assistenten-/explizite-Trennen-Vertrag und der bestehende
Bibliothek-/Queue-/Katalogfluss bestehen auf beiden mobilen Simulatoren: vier
Ausführungen an diesem Zwischencheckpoint. Nach dem zusätzlichen Audioguard bestehen
vier gezielte aktuelle Ablehnungs- und erlaubte Demo-Playback-Ausführungen. Die früheren
Bibliotheksfälle bleiben als eigener Checkpoint erhalten, nicht als unverändert neu
ausgeführte finale Suite. Beide finalen xcresult-Summaries melden je zwei bestandene
Fälle und keine Fehler, Skips oder Runtime-Warnungen. 30 native PNGs aus beiden
Checkpoints sind dekodiert, vollständige Übersichten und zusätzliche Originale gesichtet.
Fünf SDKs bestehen am abschließenden Quellstand gemeinsam. Kein Originalpixel-PASS
aus diesen Funktionsprüfungen.

Das inkrementelle UI-Testpaket hatte die bekannte separate SSU-Metadatenlücke.
Seine tatsächlichen 26 App-/Test-/Startdateien werden separat gebunden; der erste
feste 29-Dateien-Vorbehalt stoppte vor einer UI-Ausführung. Diese ausgewählten
Routen rufen keinen OS-Shortcut auf. Das normale finale SDK-Paket muss weiterhin
den vorhandenen vollständigen Shortcut-Metadaten-Gate bestehen; es wird nicht mit
dem anderen installierten UI-Paket gleichgesetzt. Die erste zweizeilige iPhone-
Kontaktübersicht schnitt die dritte Reihe ab; die vollständige neue Übersicht und
Originalbilder wurden getrennt geprüft, das alte Bild bleibt erhalten.

**#57/#67 bleiben OPEN.** Echtes Signing, Abonnement, Region, Offline-/OS-Widerruf,
MusicKit-/AirPlay-/Empfängerhardware, vollständige Medien-/Unterbrechungspolicy und
physische Privatsphäre bleiben gesondert offen. Keine persönlichen Musikdaten,
Nachrichten, Anrufe oder Home-Zugriffe. Nur eigene lokale Demoaudio-Assets im
ausdrücklichen positiven UI-Playback-Fall; keine akustische Qualitätsabnahme.
Home-/Geräte-/Signing-Holds unverändert.
