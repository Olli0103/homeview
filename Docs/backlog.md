# Vollständiges Parity-Backlog

Aktueller Bearbeitungsstand: [Fortschritt und abgeschlossene Pakete](progress.md). Die ursprünglichen Restbeschreibungen unten sind der Ausgangskatalog.

Stand 17. Oktober 2026. 82 konkrete Arbeitspakete decken alle 105 Referenzfunktionen ab. Manche Pakete bündeln eng zusammengehörige Funktionen, andere betreffen Renderer, Datenschutz, Veröffentlichung oder Abnahme.

## Was Parity hier bedeutet

Kernziel ist die belegte HomeView-Oberfläche und Funktion auf dem iPad. iPhone und weitere Apple-Ziele haben getrennte Anpassungs- und Abnahmeziele. Zusätzliche Watch-inspirierte Faces sind ausdrücklich optional.

Vorhandene Implementierung, visuelle Gleichheit und echte Geräte-/Dienstabnahme sind unterschiedliche Zustände. Ein offenes Abnahme-Issue bedeutet nicht, dass der Code dafür fehlt. Blockierte Systemfunktionen bleiben unerfüllte Originalanforderungen. Ein Mock oder Ersatzdienst macht sie nicht gleichwertig.

## Prioritäten

| Priorität | Pakete | Bedeutung |
|---|---:|---|
| P0 | 6 | Grundlage, Datenisolation, überprüfbarer Abschluss |
| P1 | 57 | Kern-Parity und zugehörige Blockaden |
| P2 | 18 | Weitere Originaldetails und getrennte Plattformabnahme |
| P3 | 1 | Optionale Erweiterungen außerhalb der Kern-Parity |

Typen: implementation = fehlende Umsetzung, validation = vorhandene Umsetzung noch abnehmen, research = offene Quellen-/Machbarkeitsfrage, blocked = fehlende öffentliche Fähigkeit, Hardware, Assets oder ausdrückliche Home-Freigabe, decision = Eigentümerentscheidung, optional = Erweiterung. Priorität ist keine Zusage technischer Machbarkeit.

## Arbeitspakete

| ID | Priorität | Typ | Arbeit | Referenz |
|---|---|---|---|---|
| BASE-01 | P0 | research | [Verbindlichen Parity-Vertrag und API-Grenzen festschreiben](https://github.com/Olli0103/homeview/issues/1) | technisch/Abnahme |
| BASE-02 | P0 | research | [Vollständigen Referenzsatz für Zustände und Bewegungen sichern](https://github.com/Olli0103/homeview/issues/2) | technisch/Abnahme |
| PUB-01 | P0 | implementation | [Redistribuierbare Grafik- und Typografiegrundlage herstellen](https://github.com/Olli0103/homeview/issues/3) | technisch/Abnahme |
| PUB-02 | P1 | decision | [Quelllizenz und Veröffentlichungsunterlagen festlegen](https://github.com/Olli0103/homeview/issues/4) | technisch/Abnahme |
| FACE-01 | P1 | validation | [Face-Katalog und Varianten vollständig gegen Referenz abnehmen](https://github.com/Olli0103/homeview/issues/5) | F001 |
| FACE-02 | P1 | implementation | [Face-Wechsel und App-Raster-Übergänge vermessen](https://github.com/Olli0103/homeview/issues/6) | F002, F009 |
| FACE-03 | P1 | validation | [Räumlichen Face-Editor vollständig kalibrieren](https://github.com/Olli0103/homeview/issues/7) | F003, F004, F005 |
| FACE-04 | P1 | implementation | [Geteilte Modular-Inhalte mit echten Freigaben trennen](https://github.com/Olli0103/homeview/issues/8) | F006, F007 |
| FACE-05 | P1 | implementation | [Persönlichen Home Screen und App-Anordnung abnehmen](https://github.com/Olli0103/homeview/issues/9) | F008 |
| FACE-06 | P1 | research | [Entfernung und Bewegung durch nachgewiesene Präsenzquelle steuern](https://github.com/Olli0103/homeview/issues/10) | F010, F016 |
| PHOTO-01 | P1 | implementation | [Foto-Galerie und geteilte Alben vervollständigen](https://github.com/Olli0103/homeview/issues/11) | F011, F012 |
| PHOTO-02 | P1 | implementation | [Motivgeschützte Uhrplatzierung und Bildausschnitt berechnen](https://github.com/Olli0103/homeview/issues/12) | F013 |
| FACE-07 | P1 | implementation | [Tageszeit-, Nacht- und reduzierte Face-Zustände vervollständigen](https://github.com/Olli0103/homeview/issues/13) | F014, F021 |
| FACE-08 | P1 | blocked | [Snoopy-Szenen, Atlanten und Timelines klären](https://github.com/Olli0103/homeview/issues/14) | F015 |
| FLOW-01 | P1 | implementation | [Variable Flow-Ziffern mit korrekten Metriken entwickeln](https://github.com/Olli0103/homeview/issues/15) | technisch/Abnahme |
| FLOW-02 | P1 | implementation | [Flow-Glas, Fluidparameter und Originalbewegung kalibrieren](https://github.com/Olli0103/homeview/issues/16) | technisch/Abnahme |
| FLOW-03 | P1 | implementation | [CPU-Fluid schrittweise auf Metal-Texturen portieren](https://github.com/Olli0103/homeview/issues/17) | technisch/Abnahme |
| FACE-09 | P1 | implementation | [Fade-Verlauf und zeitabhängige Ziffern abgleichen](https://github.com/Olli0103/homeview/issues/18) | F017 |
| FACE-10 | P1 | implementation | [Numerals-Typografie und analoge Uhrvarianten kalibrieren](https://github.com/Olli0103/homeview/issues/19) | F018 |
| FACE-11 | P1 | implementation | [Prismen-Hintergrund und analoge Materialschichten angleichen](https://github.com/Olli0103/homeview/issues/20) | technisch/Abnahme |
| FACE-12 | P1 | implementation | [Wetterdaten, Wolken, Regen und Frost vollständig abnehmen](https://github.com/Olli0103/homeview/issues/21) | F019 |
| FACE-13 | P2 | validation | [Monatskalender-Face vollständig abnehmen](https://github.com/Olli0103/homeview/issues/22) | F020 |
| HOME-01 | P1 | blocked | [HomeKit-Einrichtung und Adapter nach ausdrücklichem Fortsetzen implementieren](https://github.com/Olli0103/homeview/issues/23) | F022, F023, F100 |
| HOME-02 | P1 | blocked | [Thermostat, Licht, Lüfter und Beschattung echt anbinden](https://github.com/Olli0103/homeview/issues/24) | F024, F025, F026, F027, F031 |
| HOME-03 | P1 | blocked | [Türschloss mit echter Autorisierung und Zustandsbestätigung absichern](https://github.com/Olli0103/homeview/issues/25) | F028 |
| HOME-04 | P1 | blocked | [Szenen und Routinen mit nachgewiesenem Umfang bedienen](https://github.com/Olli0103/homeview/issues/26) | F029, F030 |
| CAM-01 | P1 | blocked | [Echte Kamera-Streams bis neun Feeds und Detailaktionen anbinden](https://github.com/Olli0103/homeview/issues/27) | F032, F033 |
| CAM-02 | P1 | blocked | [Türklingel-Ereignis und Unterbrechungsregeln umsetzen](https://github.com/Olli0103/homeview/issues/28) | F034 |
| CAM-03 | P1 | blocked | [Gegensprechen mit Audio-Lifecycle und Freigaben ergänzen](https://github.com/Olli0103/homeview/issues/29) | F035 |
| HOME-05 | P1 | blocked | [HKSV-Erkennung und Archivsuche als API-Lücke entscheiden](https://github.com/Olli0103/homeview/issues/30) | F036, F037 |
| HOME-06 | P2 | implementation | [Hausereignisse in einer gruppierten Mitteilungsansicht darstellen](https://github.com/Olli0103/homeview/issues/31) | F038 |
| HOME-07 | P2 | blocked | [Rauch-/CO-Geräuscherkennung und eigene Sensoren auf Machbarkeit prüfen](https://github.com/Olli0103/homeview/issues/32) | F039, F040 |
| AI-01 | P1 | implementation | [Allgemeinwissen und fortgesetzten Dialog durch echten Assistenten ersetzen](https://github.com/Olli0103/homeview/issues/33) | F041, F044 |
| AI-02 | P1 | blocked | [Persönlichen Kontext und Onscreen Awareness sicher begrenzen](https://github.com/Olli0103/homeview/issues/34) | F042, F045 |
| AI-03 | P1 | implementation | [Mehrschrittige Aktionen mit Bestätigung und Teilfehlern ausführen](https://github.com/Olli0103/homeview/issues/35) | F043 |
| AI-04 | P1 | implementation | [Antwortansicht mit Text, Bildern und Karten vervollständigen](https://github.com/Olli0103/homeview/issues/36) | F046 |
| AI-05 | P2 | blocked | [Wakeword und Siri-Aktivierung als getrennte Systemgrenze behandeln](https://github.com/Olli0103/homeview/issues/37) | F047 |
| AI-06 | P2 | validation | [Assistenten-Geste, Texteingabe und Entwurfserhalt abnehmen](https://github.com/Olli0103/homeview/issues/38) | F048, F049 |
| AI-07 | P2 | blocked | [Dialogverlauf und geräteübergreifende Fortsetzung klären](https://github.com/Olli0103/homeview/issues/39) | F050 |
| AI-08 | P2 | implementation | [Antwortstimme, Tempo und Medienunterbrechungen ergänzen](https://github.com/Olli0103/homeview/issues/40) | F051 |
| AI-09 | P2 | research | [Dienstverfügbarkeit, Sprachen und Limits sichtbar machen](https://github.com/Olli0103/homeview/issues/41) | F052 |
| COM-01 | P1 | blocked | [FaceTime-Annahme und aktive Anrufsteuerung als API-Lücke bilanzieren](https://github.com/Olli0103/homeview/issues/42) | F053, F054 |
| COM-02 | P2 | research | [Center Stage auf geeigneter Kamera-Hardware prüfen](https://github.com/Olli0103/homeview/issues/43) | F055 |
| COM-03 | P1 | validation | [Explizite Nachrichten- und Anruf-Systemübergaben abnehmen](https://github.com/Olli0103/homeview/issues/44) | F056, F057 |
| COM-04 | P1 | blocked | [Intercom zu HomePods und persönlichen Geräten auf Machbarkeit prüfen](https://github.com/Olli0103/homeview/issues/45) | F058 |
| COM-05 | P1 | blocked | [Find-My-Geräte, AirTags und Personen ehrlich abgrenzen](https://github.com/Olli0103/homeview/issues/46) | F059 |
| DAY-01 | P1 | validation | [Kalenderverbindung und Agenda auf echter Hardware abnehmen](https://github.com/Olli0103/homeview/issues/47) | F060, F061 |
| DAY-02 | P1 | validation | [Erinnerungen mit Listenrechten und Read-back abnehmen](https://github.com/Olli0103/homeview/issues/48) | F062 |
| DAY-03 | P1 | validation | [Mehrere Timer und große Countdown-Ansicht vollständig abnehmen](https://github.com/Olli0103/homeview/issues/49) | F063, F064 |
| DAY-04 | P1 | implementation | [Sprachbefehle für Timer und Kochschritte vervollständigen](https://github.com/Olli0103/homeview/issues/50) | F065, F075 |
| DAY-05 | P1 | implementation | [Live Activities für Timer und zulässige Aktivitäten implementieren](https://github.com/Olli0103/homeview/issues/51) | F066 |
| DAY-06 | P1 | validation | [Eigene Wecker über Neustart und Gerätebetrieb abnehmen](https://github.com/Olli0103/homeview/issues/52) | F067 |
| DAY-07 | P2 | implementation | [Weltuhr um Zonenwahl und Tag-/Nachtanzeige ergänzen](https://github.com/Olli0103/homeview/issues/53) | F068 |
| DAY-08 | P1 | validation | [Browser-Navigation und sichere externe Inhalte abnehmen](https://github.com/Olli0103/homeview/issues/54) | F069 |
| DAY-09 | P1 | implementation | [Rezeptimport, Kochansicht und Bibliothek an Randfällen vervollständigen](https://github.com/Olli0103/homeview/issues/55) | F070, F071, F072, F073, F074, F076 |
| DAY-10 | P2 | implementation | [Rezept-Handoff über öffentliche Continuity-Technik implementieren](https://github.com/Olli0103/homeview/issues/56) | F077 |
| MEDIA-01 | P1 | implementation | [MusicKit-Suche, Bibliothek und Player produktiv abnehmen](https://github.com/Olli0103/homeview/issues/57) | F078, F080, F081, F082 |
| MEDIA-02 | P2 | blocked | [Animiertes Artwork und Lyrics pro öffentlicher Fähigkeit entscheiden](https://github.com/Olli0103/homeview/issues/58) | F079 |
| MEDIA-03 | P1 | implementation | [Podcasts durch echte frei zugängliche Feedwiedergabe ergänzen](https://github.com/Olli0103/homeview/issues/59) | F083 |
| MEDIA-04 | P2 | research | [Weitere Medien und Drittanbieter-Angebote auf Zugriffsmöglichkeiten prüfen](https://github.com/Olli0103/homeview/issues/60) | F084, F085 |
| MEDIA-05 | P1 | research | [AirPlay-Routenauswahl und Mehrraumwiedergabe abnehmen](https://github.com/Olli0103/homeview/issues/61) | F086 |
| MEDIA-06 | P2 | blocked | [Gast- und Peer-to-peer-AirPlay separat klären](https://github.com/Olli0103/homeview/issues/62) | F087 |
| MEDIA-07 | P2 | blocked | [Medien- und Anruf-Handoff pro Inhaltstyp abgrenzen](https://github.com/Olli0103/homeview/issues/63) | F088 |
| SYS-01 | P1 | validation | [Live-Spiegel, Zoom und Ringlicht auf iPad-Hardware abnehmen](https://github.com/Olli0103/homeview/issues/64) | F089, F090 |
| SYS-02 | P1 | implementation | [Control Center und Settings mit echten Zuständen abgleichen](https://github.com/Olli0103/homeview/issues/65) | F091, F092 |
| SYS-03 | P0 | blocked | [Sechs Nutzer, Gerätebindung und persönliche Freigabe sicher vervollständigen](https://github.com/Olli0103/homeview/issues/66) | F093, F094, F096 |
| SYS-04 | P0 | implementation | [Persönliche Inhalte bei Weggehen und Unterbrechungen zuverlässig verbergen](https://github.com/Olli0103/homeview/issues/67) | F095 |
| SYS-05 | P1 | implementation | [Gastberechtigungen für Haus, Wetter, Timer und Musik definieren](https://github.com/Olli0103/homeview/issues/68) | F097 |
| SYS-06 | P1 | blocked | [Secure-Exclaves-Identitätsverarbeitung als Hardwaregrenze dokumentieren](https://github.com/Olli0103/homeview/issues/69) | F098 |
| SYS-07 | P1 | blocked | [Private Cloud Compute als externe Systemfähigkeit bilanzieren](https://github.com/Olli0103/homeview/issues/70) | F099 |
| SYS-08 | P1 | implementation | [Ersteinrichtung, Capability-Erklärung und verbundene Angebote ausarbeiten](https://github.com/Olli0103/homeview/issues/71) | F101 |
| SYS-09 | P2 | blocked | [Unzureichenden Stromadapter auf unterstützter Hardware erkennen oder ausweisen](https://github.com/Olli0103/homeview/issues/72) | F102 |
| SYS-10 | P1 | validation | [Accessibility über alle zentralen Flows abnehmen](https://github.com/Olli0103/homeview/issues/73) | F103 |
| SYS-11 | P2 | research | [Live Speech, Captions, RTT und Shortcuts pro Plattform klären](https://github.com/Olli0103/homeview/issues/74) | F104, F105 |
| SYS-12 | P1 | validation | [On-device-Spracherkennung auf echter Hardware abnehmen](https://github.com/Olli0103/homeview/issues/75) | technisch/Abnahme |
| QA-01 | P0 | validation | [Finalen öffentlichen Stand mit vollständiger iPad-/iPhone-Regression einfrieren](https://github.com/Olli0103/homeview/issues/76) | technisch/Abnahme |
| QA-02 | P1 | validation | [Physisches iPad signieren, installieren und dauerhaft betreiben](https://github.com/Olli0103/homeview/issues/77) | technisch/Abnahme |
| QA-03 | P1 | validation | [Visuelle Parity aller belegten Zustände und Animationen abnehmen](https://github.com/Olli0103/homeview/issues/78) | technisch/Abnahme |
| QA-04 | P2 | validation | [macOS, tvOS, visionOS und Watch als eigene Plattformabnahmen führen](https://github.com/Olli0103/homeview/issues/79) | technisch/Abnahme |
| QA-05 | P1 | validation | [Persistenz, Migration, Offline und späte Antworten systematisch prüfen](https://github.com/Olli0103/homeview/issues/80) | technisch/Abnahme |
| QA-06 | P1 | validation | [Dauerleistung, Energie und Animation-Lifecycle vermessen](https://github.com/Olli0103/homeview/issues/81) | technisch/Abnahme |
| EXTRA-01 | P3 | optional | [Palette, Bounce-Gitter und Flux als optionale Watch-inspirierte Erweiterungen bewerten](https://github.com/Olli0103/homeview/issues/82) | technisch/Abnahme |

## Konkreter Restumfang

<a id="base-01"></a>
### BASE-01: Verbindlichen Parity-Vertrag und API-Grenzen festschreiben

Die Referenzmatrix enthält 105 Funktionen mit sehr unterschiedlicher Belegstärke. Keine vollständige Gleichheit ist abgenommen.

Offen:

- Für jede Referenzfunktion beobachtet, berichtet oder unbekannt unterscheiden
- Kernziel ist die gemeinsame iPad-Oberfläche; Universalziele separat kennzeichnen
- Für systemexklusive Funktionen entweder nachgewiesene öffentliche Umsetzung oder explizite unerfüllte Anforderung festhalten; Simulation ist kein PASS
- Visuelle, funktionale und Hardware-Abnahme getrennt definieren

Abnahme: Jede F001–F105-Zeile hat einen verlinkten Arbeitspunkt, Status, Zielplattform und einen überprüfbaren Abschluss. Keine blockierte Funktion verschwindet aus der Bilanz.

<a id="base-02"></a>
### BASE-02: Vollständigen Referenzsatz für Zustände und Bewegungen sichern

Vorhanden sind einzelne Bilder, Produktaufnahmen und ausgewählte Bewegungssequenzen. Nicht jede Variante hat einen unverzerrten Originalzustand.

Offen:

- Fehlende Face-, Editor-, Fehler-, Nacht-, Nah-/Fern- und Unterbrechungszustände benennen
- Zeitgestempelte Originalsequenzen für Übergänge und Animationen sammeln, soweit rechtmäßig zugänglich
- Perspektivische Produktfotos nicht zu vermeintlichen Originalscreens erklären
- Öffentliche Quellenlinks und private Referenzdateien getrennt halten

Abnahme: Ein Zustandskatalog verlinkt für jedes Abnahmeszenario Quelle, Datum, Geometrie und Unsicherheit. Fehlende Originale bleiben als Lücke erkennbar.

<a id="pub-01"></a>
### PUB-01: Redistribuierbare Grafik- und Typografiegrundlage herstellen

Die öffentliche Kopie ersetzt 17 Referenzgrafiken und abgeleitete OS-Ziffernkonturen durch eigene geometrische Platzhalter.

Offen:

- Eigenständige App-Icons, Rezeptbilder, Demo-Fotos und Cover mit dokumentierter Herkunft erstellen oder geeignet lizenzieren
- Flow- und Numerals-Typografie ohne extrahierte Schriftkonturen entwickeln
- Assetmanifest mit Digest, Urheber und Nutzungsbedingungen pflegen
- Screenshots nach Austausch neu aufnehmen

Abnahme: Keine Referenz-Crops, Original-App-Icons, OS-Fonts oder daraus extrahierte Konturen im gesamten öffentlichen Git-Verlauf. Alle sichtbaren Ersatzassets sind nachvollziehbar.

Abhängigkeiten: BASE-01.

<a id="pub-02"></a>
### PUB-02: Quelllizenz und Veröffentlichungsunterlagen festlegen

Das Repo ist öffentlich, eine allgemeine Quelllizenz wurde noch nicht gewählt.

Offen:

- Mit dem Eigentümer die gewünschte Quelllizenz festlegen
- Herkunft eigener Quellen und zukünftiger Drittkomponenten dokumentieren
- Projektname, unabhängigen Status und Rechtehinweise vor einer Verteilung prüfen
- Keine pauschale Lizenz über fremdes Referenzmaterial legen

Abnahme: Die beschlossene Lizenz und erforderliche Notices sind im Repo, oder der bewusst lizenzlose Status bleibt ausdrücklich dokumentiert.

<a id="face-01"></a>
### FACE-01: Face-Katalog und Varianten vollständig gegen Referenz abnehmen

Mehrere native Faces sind vorhanden, Snoopy fehlt. Watch-abgeleitete zusätzliche Modular-Layouts sind keine belegten HomeView-Originalvarianten.

Offen:

- Alle tatsächlich belegten HomeView-Faces samt Reihenfolge und Varianten inventarisieren
- Vorhandene Styles gegen den Katalog prüfen
- Nicht belegte Watch-Erweiterungen getrennt vom Kernziel führen
- Leere, entfernte und neu hinzugefügte Varianten reproduzierbar behandeln

Abnahme: Für jeden Referenz-Face existiert ein geprüfter Zustand oder eine benannte Lücke. Zusatzfaces zählen nicht als Beleg fehlender Originalfaces.

Abhängigkeiten: BASE-02.

<a id="face-02"></a>
### FACE-02: Face-Wechsel und App-Raster-Übergänge vermessen

Richtungsabhängige Übergänge und Raster über unscharfem Face sind implementiert. Federkurven und vollständige Gestenregeln sind eigene Näherungen.

Offen:

- Geschwindigkeit, Beschleunigung, Wischschwellen und Abbruch vermessen
- Face-Inhalt während ausgehender Transition stabil halten
- Konflikte mit vertikalem Scrollen, Langdruck und Randgesten prüfen
- Reduce Motion und zugängliche Navigation erhalten

Abnahme: Framefolgen bei langsamer/schneller/abgebrochener Geste mit Referenz vergleichen; keine Sprünge, falschen Faces oder blockierten Inhalte.

Abhängigkeiten: BASE-02.

<a id="face-03"></a>
### FACE-03: Räumlichen Face-Editor vollständig kalibrieren

Direktwahl von Slots, Größenfamilien und unabhängige Speicherung je Face sind umgesetzt. Exakte Originalgeometrie und vollständiger Optionsumfang sind nicht bewiesen.

Offen:

- Langdruck, Auswahlrahmen, Farb-/Stilseiten und leere Slots gegen Referenzen abnehmen
- Pro Layout erlaubte Familien, Anbieter und Defaults prüfen
- Veraltete gespeicherte Slots migrieren und unbekannte Werte behandeln
- Touchflächen, Fokus, Abbruch und Neustart prüfen

Abnahme: Alle belegten Editoroptionen sind erreichbar und persistent. Inkompatible Inhalte werden nicht angeboten, andere Faces bleiben unverändert.

Abhängigkeiten: BASE-02.

<a id="face-04"></a>
### FACE-04: Geteilte Modular-Inhalte mit echten Freigaben trennen

Vier gemeinsame Panels und weitere eigene Modular-Layouts funktionieren mit lokalen Daten. Mehrere echte Haushaltsidentitäten sind nicht angebunden.

Offen:

- Gemeinsame und persönliche Panelinhalte ausdrücklich unterscheiden
- Opt-in für haushaltsweit sichtbare Kalender-/Medieninhalte definieren
- Quellenkennzeichnung und widerrufbare Freigabe hinzufügen
- Nach Widerruf persönliche Inhalte aus Panels und Vorschauen entfernen

Abnahme: Zwei synthetische Nutzer können nur bewusst freigegebene Inhalte gemeinsam sehen. Profilwechsel und Sperren legen keine privaten Reste offen.

Abhängigkeiten: SYS-03.

<a id="face-05"></a>
### FACE-05: Persönlichen Home Screen und App-Anordnung abnehmen

Profilgetrennte eigene Layouts, vier Favoriten, Medien-/Wetterraster und lokale Speicherung sind synthetisch geprüft. Foto-Vorschau und explizit freigegebenes Album sind ergänzt. Vollständige Originalvarianten, echte Mehrnutzeridentität, Accounts und genaue Licht-/Rasterdetails bleiben offen.

Offen:

- Widgets, App-Reihenfolge, Beschriftungen und Zustände je Profil gegen Referenz erfassen
- Änderungen profilgetrennt speichern
- Leere/gesperrte Inhalte und Rückkehr zum Face ausarbeiten

Abnahme: Ansicht und Auswahl überstehen Neustart; zweites Profil übernimmt keine persönlichen Einstellungen oder Daten.

Abhängigkeiten: SYS-03, BASE-02.

<a id="face-06"></a>
### FACE-06: Entfernung und Bewegung durch nachgewiesene Präsenzquelle steuern

Far/Near ist ein manueller Schalter. Flow bewegt sich und reagiert auf Touch, aber nicht auf echte Raumbewegung.

Offen:

- Öffentliche Sensor-/Kameraoptionen auf der Zielhardware prüfen, vor Eigenbau vorhandene Lösungen bewerten
- Entfernung und Bewegung ohne Identitätsbehauptung modellieren
- Hysterese, Mehrpersonenfälle und Verlust der Quelle definieren
- Bei fehlender Hardware manuellen Modus ehrlich beibehalten

Abnahme: Ein dokumentierter synthetischer Bewegungs-/Distanzverlauf schaltet stabil. Echte Sensorabnahme erfolgt separat und nur nach bewusster Freigabe; kein dauerhafter Kamerazugriff als stiller Default.

<a id="photo-01"></a>
### PHOTO-01: Foto-Galerie und geteilte Alben vervollständigen

Bis zehn bewusst gewählte Bilder, lokale Rotation und ein ausdrücklich freigegebenes, begrenzt aktualisiertes Shared Album sind implementiert. Updates nur bei aktiver App; privater Katalog nur nach Geräteauthentifizierung. Originale Galerie-/Wechselregeln und reale PhotoKit-Abnahme offen.

Offen:

- Originale Galerieauswahl und Wechselregeln klären
- Begrenzte, widerrufbare Albumaktualisierung implementieren, soweit PhotoKit sie unterstützt
- Entfernte/ungültige Bilder, Speichergrenzen und Offlinezustand behandeln
- Import/Trennen ohne unnötige Bibliotheksfreigabe gestalten

Abnahme: Synthetische Alben zeigen Hinzufügen/Entfernen und Neustart korrekt. Persönliche Fotobibliotheken bleiben außerhalb automatischer Tests.

<a id="photo-02"></a>
### PHOTO-02: Motivgeschützte Uhrplatzierung und Bildausschnitt berechnen

Vision-Maske kann das Motiv vor die Uhr legen. Automatische Optimierung von Uhrposition und Crop fehlt.

Offen:

- Summenbildtabelle der Maske aufbauen
- Mehrere Uhrpositionen und Ausschnitte nach Überdeckung bewerten
- Laufzeiten, Randfälle, fehlendes Motiv und mehrere Motive berücksichtigen
- Manuelle Korrektur und stabile Auswahl bei ähnlichen Scores erhalten

Abnahme: Analytische Maskenfälle und eigene synthetische Bilder ergeben vorhersehbare Platzierungen; kein Beschnitt wichtiger Motive, keine NaN-Scores.

Abhängigkeiten: PUB-01.

<a id="face-07"></a>
### FACE-07: Tageszeit-, Nacht- und reduzierte Face-Zustände vervollständigen

Rote Monochromdarstellung und Reduce Motion sind vorhanden. Automatische Tageszeitregeln sind unvollständig.

Offen:

- Belegte Übergänge und pro Face erlaubte Nachtvarianten erfassen
- Zeitzone, Sommerzeit und Tagwechsel berücksichtigen
- Hintergründe, Komplikationen und Kontrast gemeinsam umschalten
- Manuelle Übersteuerung und fehlende Umgebungsdaten definieren

Abnahme: Deterministische Zeit-/Zeitzonenszenarien und Pixelprüfungen belegen lesbare Zustände ohne Farblecks; unbekannte Originalregeln bleiben markiert.

Abhängigkeiten: BASE-02.

<a id="face-08"></a>
### FACE-08: Snoopy-Szenen, Atlanten und Timelines klären

Snoopy ist nicht implementiert. Statisch bekannte Engine-Struktur und Szenenbeschreibungen ersetzen keine vollständigen Atlanten oder Timelines.

Offen:

- Rechtmäßig nutzbare vollständige Szenen, Timing, Wetter-/Datumsauswahl und Übergänge beschaffen oder eine ausdrücklich akzeptierte eigene Alternative definieren
- Keine extrahierten proprietären Assets öffentlich einchecken
- Speicher-/Animationsbudget und reduzierte Zustände festlegen

Abnahme: Erst mit dokumentierter Assetgrundlage und geprüften Szenen für Wetter, Datum und Tageszeit abschließen. Ein statisches Bild oder ähnliche Figur ist kein Parity-PASS.

Abhängigkeiten: PUB-01, BASE-02.

<a id="flow-01"></a>
### FLOW-01: Variable Flow-Ziffern mit korrekten Metriken entwickeln

Privater Stand hat feste extrahierte Konturen. Öffentliche Kopie verwendet eigene Siebensegment-Ziffern. Variable Breite/Stärke und Laufweiten fehlen.

Offen:

- Eigenständige nutzbare Solid-/Stencil-Formen ohne extrahierte OS-Konturen erstellen
- Breite, Stärke, Laufweite und Randabstände konsistent parametrisieren
- Alle Ziffernpaare und 12-/24-Stunden-Zeiten prüfen

Abnahme: Achsengrenzen erzeugen keine Selbstüberschneidung oder abgeschnittene Ziffern. Kalibrierte Vergleichsaufnahmen aller Ziffern und relevanter Zeiten.

Abhängigkeiten: PUB-01, BASE-02.

<a id="flow-02"></a>
### FLOW-02: Flow-Glas, Fluidparameter und Originalbewegung kalibrieren

Öffentliche SwiftUI-Glaslinse auf eigenen Ziffern bei sichtbarem Fluid; vorhandener Metal-Fallback für Hintergrund aus, visionOS und ältere Macs. 139 Modelltests, zehn gezielte iPad-/iPhone-Ausführungen und fünf SDKs; feste Glyphenkörper nach 30 Sekunden, Reduce Motion, beide Schriftstile und Nachtfilter geprüft. CPU-Fluid bleibt unverändert. Exakte Originaloptik, Langzeit-/Hardware- und GPU-Abnahmen offen. Details: Docs/flow-native-glass.md.

Offen:

- Hintergrund, Schatten, Brechung, Bevel, Licht und Deckung anhand Zeitsequenzen abstimmen
- Hintergrund an/aus und beide Schriftstile getrennt behandeln
- Langzeit-Farbverteilung, Impulse und Randverhalten prüfen
- Eigene Parameter und belegte Originalbeobachtungen getrennt dokumentieren

Abnahme: Vergleichsvideos mit kontrollierter Zeit, Bewegung und Palette; nach längerem Betrieb weder einfarbiger Kollaps noch weiße/fehlende Ziffern. Kein internes Apple-Material laden.

Abhängigkeiten: FLOW-01, BASE-02.

<a id="flow-03"></a>
### FLOW-03: CPU-Fluid schrittweise auf Metal-Texturen portieren

Nur das Glyphenmaterial läuft auf Metal. Fluidrechnung läuft weiter auf CPU und wird als CGImage hochgeladen.

Offen:

- Vorhandene maintained GPU-/Metal-Ansätze leichtgewichtig prüfen
- Eigenen Textur-/Ping-Pong-Pfad für die Rechenschritte hinzufügen
- CPU-Referenz für Divergenz, Druck, Curl, Ränder und Farbstoff erhalten
- Fallback und Ressourcenfreigabe bei Hintergrund/Geräteverlust vorsehen

Abnahme: Numerische Toleranzen gegen CPU und echte Framezeit-/Energie-Messung auf iPad dokumentieren. Beschleunigung erst nach Messung behaupten.

Abhängigkeiten: FLOW-02.

<a id="face-09"></a>
### FACE-09: Fade-Verlauf und zeitabhängige Ziffern abgleichen

Eigener konischer Fade-Verlauf und Reduce Motion sind pixelbasiert geprüft; Zeigerlängen, schmaler Ansatz, Relief und Ziffernanordnung wurden getrennt nach UI12 kalibriert. Exakte Originalzeitkurve, weitere Übergänge, Licht und Schrift bleiben offen.

Offen:

- Konischen Verlauf mit definiertem Nullwinkel und Farbstops implementieren
- Ziffernrelief, Zeiger, Schatten und Ausblendfenster abstimmen
- Minuten-/Stundenwechsel und reduzierte Bewegung kalibrieren

Abnahme: Standbilder und Zeitsequenzen über vollständige belegte Phasen vergleichen. Unbekannte Originalkurven nicht durch Einzelbild-PASS ersetzen.

Abhängigkeiten: BASE-02.

<a id="face-10"></a>
### FACE-10: Numerals-Typografie und analoge Uhrvarianten kalibrieren

Numerals verwendet kalibrierte öffentliche gerundete Runtime-Typografie, längeren Minutenzeiger, Relief und offene Nabe; die alternative Home-Rasteruhr wurde getrennt angepasst. Exakte Originalschrift, alle Uhrzeiten/Stile und Lichtdetails bleiben offen.

Offen:

- Nutzbare Schriftgrundlage und Metriken auswählen
- Zifferngewicht, Breite, Randanschnitt, Zeigerlängen und Drehpunkte abstimmen
- Zeitzonen, 12-/24-Stunden-Ansicht und relevante Stilvarianten prüfen

Abnahme: Alle referenzierten Uhrzeiten und Ziffernformen sind dokumentiert visuell verglichen; keine extrahierten Fontdaten im Repo.

Abhängigkeiten: PUB-01, BASE-02.

<a id="face-11"></a>
### FACE-11: Prismen-Hintergrund und analoge Materialschichten angleichen

Eigene analytische Prismen mit Kantenrelief und Reflexionsbändern sowie öffentliche Glaskacheln auf unterstützten Plattformen sind geprüft. Touch, Nacht und Reduce Motion wurden begrenzt validiert. Exakte Originalkonturen/-phasen/-schatten, andere Materialfallbacks und physische Leistung bleiben offen.

Offen:

- Prismenflächen, Bewegung und Licht anhand sichtbarer Referenzsequenzen abstimmen
- Separate Reflexions-/Zeigerschatten-Schichten hinzufügen, wo tatsächlich im HomeView-Ziel belegt
- Clipping und Licht bei Face-Wechsel, Nacht und Reduce Motion prüfen

Abnahme: Kontrollierte Vorher-/Nachher-Videos mit nachvollziehbaren Abweichungen. Ähnliche Shadernamen allein sind kein Rendererbeleg.

Abhängigkeiten: BASE-02.

<a id="face-12"></a>
### FACE-12: Wetterdaten, Wolken, Regen und Frost vollständig abnehmen

Open-Meteo, unbekannte statt erfundener Werte und getrennte Wetter-App sind geprüft. Eigene Metal-Wolken, Glasziffern und UI05-Geometrie mit öffentlichen Symbolen sind getrennt kalibriert; Demo/Celsius/unbekannte Face-Werte bleiben vollständig sichtbar. Exakte Originalformen, Schrift, Brechung, Übergänge, Regen/Frost und physische Leistung bleiben offen.

Offen:

- Wetterzustände, Wind, Feuchte, Luftqualität und Sonnenzeiten mit Quelle und Zeitstempel darstellen
- Fehlende Werte nicht erfinden
- Wettereffekte und Tageszeitvarianten entwickeln
- Offline/veraltet/Ort geändert und Einheiten prüfen

Abnahme: Fixtures für alle Zustände plus gesonderter öffentlicher Datenabruf. Effekte überlagern keine wichtigen Daten; kein erfundener AQI.

Abhängigkeiten: BASE-02.

<a id="face-13"></a>
### FACE-13: Monatskalender-Face vollständig abnehmen

Kritische Kalenderdaten synthetisch nativ geprüft; Kalender-Eins, Kopfzeilenabstand, Heute-Kreis und lokale Farben näher an UI08 kalibriert. Modular-Form unverändert. Exakte Typografie, weitere Locales und vollständige Original-Auswahlregeln bleiben offen.

Offen:

- Geometrie, Schrift, Auswahl und Locale gegen alle verfügbaren Referenzzustände prüfen
- Monats-/Jahreswechsel, Schaltjahre und Zeitzonenübergang prüfen
- Unterschiedliche Auswahl in Kalender-App und Face konsistent führen

Abnahme: Visuelle Prüffälle für kritische Monate und verschiedene Sprachen, keine verdeckten Tageszahlen oder falschen Daten.

Abhängigkeiten: BASE-02.

<a id="home-01"></a>
### HOME-01: HomeKit-Einrichtung und Adapter nach ausdrücklichem Fortsetzen implementieren

NativeHomeKitService wirft immer. Es gibt keine reale Hauserkennung; Oberflächen arbeiten mit MockHome.

Offen:

- Sperre bis zur ausdrücklichen Einrichtung zu Hause erhalten
- Danach Capabilities, Owner-Freigabe, Geräte-/Rauminventar und Verbindungszustände hinzufügen
- Mock, Testheim und echtes Heim strikt trennen
- Kein Home-Assistant-Ausweichpfad ohne neuen Auftrag

Abnahme: Zuerst synthetische Adaptertests. Später gesondert genehmigte Testumgebung mit Read-back und verweigerter Freigabe. Nicht allein durch erfolgreiche Initialisierung schließen.

<a id="home-02"></a>
### HOME-02: Thermostat, Licht, Lüfter und Beschattung echt anbinden

Bedienflächen und lokale Zustandsänderungen existieren. Keine realen Charakteristiken oder Geräte werden angesprochen.

Offen:

- Unterstützte Charakteristiken, Einheiten, Min/Max/Step und Schreibrechte je Gerät abbilden
- Ausstehende/fehlgeschlagene Befehle und Fremdänderungen darstellen
- Erfolg erst nach bestätigtem Read-back
- Thermostatmodi, Helligkeit, Lüfter und Beschattung gesondert abnehmen

Abnahme: Synthetische Geräte mit Erfolg, Timeout, Ablehnung und asynchroner Fremdänderung. Spätere reale Testheim-Abnahme separat.

Abhängigkeiten: HOME-01.

<a id="home-03"></a>
### HOME-03: Türschloss mit echter Autorisierung und Zustandsbestätigung absichern

Demo-Profil schützt ein Mock-Schloss. Das ist keine Autorisierung für ein echtes Schloss.

Offen:

- Geräteauthentifizierung und explizite Bestätigung für Sicherheitsaktionen vorsehen
- Schlosszustand, unbekannt, blockiert und Batteriefehler behandeln
- Autorisierung bei Hintergrund/Profilwechsel verwerfen
- Keine erfolgreiche Öffnung vor Zustandsbestätigung anzeigen

Abnahme: Nur Mock-/Testheim-Sicherheitsfälle, kein echtes Schloss in automatischen Tests. Abgebrochene oder abgelaufene Autorisierung sendet keinen Befehl.

Abhängigkeiten: HOME-01, SYS-03.

<a id="home-04"></a>
### HOME-04: Szenen und Routinen mit nachgewiesenem Umfang bedienen

Drei lokale Szenen sind vorhanden, kein eigenständiger Dauerautomationsdienst.

Offen:

- Vorhandene HomeKit-Szenen lesen und bewusst starten, sobald freigegeben
- Teilfehler und heterogene Gerätelaufzeiten anzeigen
- Originaloberfläche für Routinen erst belegen
- Lokale Rezept-/Timeraktionen nicht als Home-Automation ausgeben

Abnahme: Szenen mit teilweise verweigerten Geräten liefern korrekten Endstatus. Keine unbeauftragte neue Zeitsteuerung.

Abhängigkeiten: HOME-01, BASE-02.

<a id="cam-01"></a>
### CAM-01: Echte Kamera-Streams bis neun Feeds und Detailaktionen anbinden

Vier-/Neunerraster und Detailansicht zeigen synthetische Kamerabilder.

Offen:

- Öffentlich unterstützte HomeKit-Stream- und Snapshotpfade prüfen
- Streams bedarfsabhängig starten/stoppen und Ressourcen begrenzen
- Berechtigungen, Ausfälle und benachbarte Geräteaktionen abbilden
- Gleichzeitige Feedgrenze auf echter Hardware messen

Abnahme: Synthetische Streamausfälle und später freigegebene Testkameras. Hintergrund/Verlassen beendet Streams, ein Offlinefeed blockiert nicht das Raster.

Abhängigkeiten: HOME-01.

<a id="cam-02"></a>
### CAM-02: Türklingel-Ereignis und Unterbrechungsregeln umsetzen

Synthetische Türklingel als begrenztes Overlay ohne Navigationsersatz implementiert und geprüft: Wiederholung, Ablauf, Timer/Kochschritt, Offline/Anruf und Hintergrundsperre. Keine echte Eventquelle oder Kameraanbindung; Originalprioritäten und Hardware offen.

Offen:

- Verfügbare öffentliche Eventquelle nachweisen
- Overlay über Face/Timer/Rezept definieren
- Doppelte Ereignisse, Abweisen und Rückkehr zur vorigen Ansicht behandeln
- Persönliche Daten in gesperrten Zuständen schützen

Abnahme: Synthetische Klingelsequenzen einschließlich Wiederholung und gleichzeitigem Timer; Kamera wird nur mit geltender Freigabe geöffnet.

Abhängigkeiten: CAM-01.

<a id="cam-03"></a>
### CAM-03: Gegensprechen mit Audio-Lifecycle und Freigaben ergänzen

Gelbe Mikrofontaste schaltet ausschließlich einen Mockzustand und verwendet kein Mikrofon.

Offen:

- Öffentliche Talkbackfähigkeit pro Kamera nachweisen
- Push-to-talk, Freigabe, Audiounterbrechungen und Echobehandlung definieren
- Aufnahme/Stream bei Loslassen, Hintergrund und Verlassen stoppen

Abnahme: Zuerst synthetischer Audiovertrag. Echte Testkamera und Mikrofon nur bewusst; kein dauerhaft offenes Mikrofon nach Navigation.

Abhängigkeiten: CAM-01.

<a id="home-05"></a>
### HOME-05: HKSV-Erkennung und Archivsuche als API-Lücke entscheiden

Keine gleichwertige öffentliche Integration für HKSV-Metadaten, bekannte Gesichter oder natürliche Archivsuche nachgewiesen.

Offen:

- Aktuelle öffentliche APIs und erforderliche Cloud-/Accountrechte je Unterfunktion belegen
- Falls unzugänglich, Anforderung ausdrücklich unerfüllt lassen
- Etwaige eigene Kamera-/Archivlösung als separate Alternative mit eigener Freigabe behandeln

Abnahme: Fähigkeitsbericht mit konkreten Dokumentationslinks und Testgrenzen. Mock-Suche, fremde Daten oder UI-Nachbau sind kein HKSV-PASS.

Abhängigkeiten: BASE-01, HOME-01.

<a id="home-06"></a>
### HOME-06: Hausereignisse in einer gruppierten Mitteilungsansicht darstellen

Keine vollständige produktive Hausmitteilungs-Pipeline oder gruppierte Ereignisabnahme vorhanden.

Offen:

- Synthetische Ereignisse mit Quelle, Zeit und Haushalt modellieren
- Zugehörige Tür-/Ankunft-/Alarmereignisse gruppieren und deduplizieren
- Berechtigung, Veraltung, Offenlegen persönlicher Daten und Aktionsziele prüfen

Abnahme: Deterministische Ereignisfolgen zeigen keine verlorenen oder falsch zusammengefassten Meldungen. Echtquelle erst nach HOME-01.

Abhängigkeiten: HOME-01, SYS-03.

<a id="home-07"></a>
### HOME-07: Rauch-/CO-Geräuscherkennung und eigene Sensoren auf Machbarkeit prüfen

Kein Sicherheitsalarm-Detektor und keine eigenen physischen Temperatur-/Feuchtesensoren vorhanden.

Offen:

- Erforderliche Hardware und zugängliche Systemdienste getrennt prüfen
- Keine verlässliche Rauch-/CO-Schutzfunktion durch Mikrofon-Demo behaupten
- Eigene Sensorwerte nur von nachgewiesener Hardware beziehen
- Nicht verfügbare Fähigkeiten in Plattformmatrix ausweisen

Abnahme: Dokumentierte Machbarkeitsentscheidung pro Funktion; keine erfundenen Messwerte oder Sicherheitsversprechen.

Abhängigkeiten: BASE-01.

<a id="ai-01"></a>
### AI-01: Allgemeinwissen und fortgesetzten Dialog durch echten Assistenten ersetzen

Lokaler Parser versteht wenige Befehle. Kein allgemeiner Wissensdienst oder natürlicher Mehrturn-Dialog.

Offen:

- Vorhandene freie/lokale oder bereits verfügbare Dienste vor Eigenbau prüfen
- Explizite Anbieter-/Datenschutzwahl, Offline-/Fehlerzustände und Kontextgrenzen entwickeln
- Mehrturn-Dialog und Abbruch hinzufügen
- Kostenpflichtige Dienste nicht ohne Freigabe voraussetzen

Abnahme: Kuratiertes Fragen-/Dialogset mit Quellen- und Fehlerprüfung; synthetische Daten, kein behauptetes Siri oder Private Cloud Compute.

Abhängigkeiten: BASE-01.

<a id="ai-02"></a>
### AI-02: Persönlichen Kontext und Onscreen Awareness sicher begrenzen

Kein Zugriff auf Nachrichtenhistorie oder systemweiten Siri-Kontext. Eigene Kalenderdaten sind bewusst anschließbar.

Offen:

- Öffentlich zugängliche Datenquellen und eigenen Ansichtsstatus getrennt erfassen
- Vor Kontextzugriff tatsächliche Geräteauthentifizierung und Zweckfreigabe erzwingen
- Keine Rechte aus Demo-Profil ableiten
- Fehlende systemweite Fähigkeiten explizit benennen

Abnahme: Synthetische Anfragen dürfen nur freigegebene Daten und app-eigenen Zustand verwenden. Gesperrte Daten erscheinen weder in Antworten noch Verlauf.

Abhängigkeiten: SYS-03, AI-01.

<a id="ai-03"></a>
### AI-03: Mehrschrittige Aktionen mit Bestätigung und Teilfehlern ausführen

Parser führt einzelne lokale Szenen-, Timer- oder Navigationsbefehle aus.

Offen:

- Plan mit abhängigen Schritten, Autorisierung und nutzerlesbarer Vorschau modellieren
- Nachrichten, Anrufe und Sicherheitsaktionen niemals automatisch ausführen
- Read-back je Schritt und Teilfehler/Abbruch definieren
- Mehrfachausführung bei wiederholter Antwort verhindern

Abnahme: Synthetische Aktionsketten mit Fehler im mittleren Schritt zeigen echte Dispositionen. Kein erfundener Gesamterfolg.

Abhängigkeiten: AI-01, HOME-01.

<a id="ai-04"></a>
### AI-04: Antwortansicht mit Text, Bildern und Karten vervollständigen

Eigene gebündelte Wissens-/Bild-, Quellen-, Agenda- und Rezeptkarten sowie Lade-/Leer-/Fehlerbeispiele vorhanden. Entwürfe bleiben ungesendet; nur expliziter Rezeptbutton navigiert. Keine persönlichen oder dynamischen API-Ergebnisse. Tatsächliche VoiceOver-/Hardware- und Originalabnahme bleiben offen. Die Rezeptkarte öffnet ihr unabhängiges schreibgeschütztes Suppenbeispiel, ohne ausgewähltes Importrezept oder aktiven Kochfortschritt zu ersetzen.

[Lokale Karten und Grenzen](assistant-response-cards.md) · [Unabhängiges Rezeptziel](assistant-recipe-target.md).

Offen:

- Referenztypen für Text, Bilder, Quellen und Aktionskarten erfassen
- Lade-, Leer-, Fehler- und Folgefragenzustände umsetzen
- Rich Content zugänglich machen und untrusted Inhalte von Befehlen trennen

Abnahme: Deterministische Antwortfixtures für jede belegte Kartenart mit visueller und VoiceOver-Prüfung.

Abhängigkeiten: AI-01, BASE-02.

<a id="ai-05"></a>
### AI-05: Wakeword und Siri-Aktivierung als getrennte Systemgrenze behandeln

Spracheingabe startet nur durch bewussten Knopf. Keine Siri-Wakeword-Übernahme oder Hintergrundaufnahme.

Offen:

- Öffentliche App-Intent-/Shortcut-Einstiegspunkte prüfen
- Keine Übernahme von Siri/Hey Siri behaupten
- Eigenes Wakeword nur als gesonderte ausdrücklich gewählte Funktion untersuchen, nicht still aktivieren

Abnahme: Dokumentierter unterstützter Aufruf oder weiter blockierter Zustand. App nimmt ohne ausdrückliche Aktivierung kein Audio auf.

Abhängigkeiten: BASE-01.

<a id="ai-06"></a>
### AI-06: Assistenten-Geste, Texteingabe und Entwurfserhalt abnehmen

Obere Randgeste und Texteingabe sind implementiert. Nicht alle Referenzzustände oder Unterbrechungen sind vermessen.

Offen:

- Randgeste, Tastatur, Entwurf, Abbruch und Rückkehr bei Navigation abnehmen
- Konflikte mit Control Center, Scrollen und systemweiten Gesten prüfen
- Touch-, Tastatur- und zugänglichen Einstieg gleichwertig halten

Abnahme: Auf iPad Hoch-/Querformat keine verdeckten Eingabefelder und kein versehentlicher Sendeschritt.

Abhängigkeiten: BASE-02.

<a id="ai-07"></a>
### AI-07: Dialogverlauf und geräteübergreifende Fortsetzung klären

Kein Zugriff auf Siri-App-/iCloud-Dialoghistorie und keine geräteübergreifende Dialogfortsetzung.

Offen:

- Zugang zum Originaldienst nachweisen oder als unerfüllt markieren
- Eigene lokale Historie nur mit klarer Trennung und Löschmöglichkeit entwerfen
- Eigenen Sync als Alternative benennen, nicht als Siri-Sync

Abnahme: Kein vermeintlicher Apple-Verlauf aus lokalen Demos. Falls eigener Verlauf freigegeben wird, Isolation, Löschung und Konfliktfälle prüfen.

Abhängigkeiten: AI-01, SYS-03.

<a id="ai-08"></a>
### AI-08: Antwortstimme, Tempo und Medienunterbrechungen ergänzen

On-device Speech verarbeitet Eingabe, eine expressive anpassbare Antwortstimme ist nicht gleichwertig umgesetzt.

Offen:

- Öffentliche Sprachsynthese mit wählbarer Sprache, Stimme und Sprechtempo anbinden
- Unterbrechen, Stummschalten und Audiofokus behandeln
- Keine Original-Siri-Stimme oder Identitätsgleichheit versprechen

Abnahme: Sprachausgabe mit langen Antworten, Abbruch und gleichzeitigen Timern/Musik abnehmen. Keine Ausgabe privater Inhalte im gesperrten Zustand.

Abhängigkeiten: AI-01.

<a id="ai-09"></a>
### AI-09: Dienstverfügbarkeit, Sprachen und Limits sichtbar machen

Abgeschlossen am19.Oktober2026 im Informationsumfang: Eigene Informationsansicht für lokalen Befehlsumfang, ausgewählte deutsche/englische Befehle, englische Antworten und tatsächlich erzwungene Aufnahme-/Transkript-/Timergrenzen. Kein konfigurierter Cloud-/Siri-Dienst oder KI-Abo.

[Anzeige, datierter Referenzabgleich und Grenzen](assistant-capabilities.md) · [Quellgebundene Tests](verification/assistant-capabilities.json). F052 bleibt Original-Dienstabhängigkeit; kein tatsächlicher Siri-/Cloud-Anschluss aus #33 behauptet.

<a id="com-01"></a>
### COM-01: FaceTime-Annahme und aktive Anrufsteuerung als API-Lücke bilanzieren

Abgeschlossen am 19. Oktober 2026 im API-Abgrenzungs- und Produkttrennungsumfang. Aktionsweiser [Fähigkeitsbericht](facetime-control-boundary.md), eigene CallKit-/LiveCommunicationKit-Typen und tatsächliche Systemübergabe bleiben getrennt. Die lokale Vorschau ist standardmäßig geschlossen; eingehende/aktive Demo und Mikrofon-/Videowerte nennen die Simulation ausdrücklich.

Sechs iPad-/iPhone-Ausführungen, fünf SDK-Builds und zehn einzeln bilanzierte API-Typprüfungen. Keine echten Anrufe, Kamera, Mikrofon oder Systemtransaktionen. Die Existenz von Aktionstypen beweist keine FaceTime-Steuerrechte. F053/F054 bleiben blocked/parity=false; dies ist keine Original- oder Live-Abnahme.

Abhängigkeiten: BASE-01.

<a id="com-02"></a>
### COM-02: Center Stage auf geeigneter Kamera-Hardware prüfen

Kein physischer Center-Stage-/Mehrpersonen-Test.

Offen:

- Öffentliche AVFoundation-Unterstützung und tatsächliche Zielkamera erfassen
- Verfügbarkeit, automatische Bildführung und Nutzerkontrolle prüfen
- Von Kontrolle einer FaceTime-Sitzung unterscheiden

Abnahme: Bewusst gestartete Aufnahme auf unterstütztem Testgerät oder dokumentierter nicht verfügbarer Zustand. Keine Hardwarefähigkeit aus dem SDK-Build ableiten.

<a id="com-03"></a>
### COM-03: Explizite Nachrichten- und Anruf-Systemübergaben abnehmen

Messages-Composer und FaceTime-URL werden nach Knopf angeboten. Nachrichtenhistorie bleibt Mock; kein automatischer Versand.

Offen:

- Empfänger, Abbrechen, nicht installierte Apps und Einschränkungen behandeln
- Sprache nur in editierbaren Nachrichtenentwurf übergeben
- Mock-Historie deutlich von echtem System-Composer trennen
- Ausgehenden Übergang auf echten Geräten bewusst prüfen

Abnahme: Ohne bestätigten Benutzerknopf weder Versand noch Anruf. Keine Behauptung empfangener Nachrichten oder erfolgreicher Zustellung aus einem URL-Aufruf.

<a id="com-04"></a>
### COM-04: Intercom zu HomePods und persönlichen Geräten auf Machbarkeit prüfen

Machbarkeitsprüfung abgeschlossen: In den geprüften öffentlichen Apple-Dokumenten und SDK-Schnittstellen ist kein unterstützter Drittanbieter-Sendepfad zu Apple Home Intercom belegt. Lokale Ansicht bleibt Simulation; Originalzustellung F058 blockiert, keine Zielbestätigung. Keine Home-Einrichtung oder eigene Audioalternative.

[Öffentliche API-Nachweise und Blockade](intercom-public-feasibility.md).

Offen:

- Öffentliche Sendeschnittstellen, Zielauswahl und Berechtigungen belegen
- Wenn nicht zugänglich, Originalanforderung unerfüllt lassen
- Eigene Audiozustellung nur als separate Alternative und nach expliziter Freigabe planen

Abnahme: Dokumentierter API-Nachweis und tatsächlicher Ziel-Read-back oder blockierter Status. Lokales Abspielen zählt nicht als Zustellung.

Abhängigkeiten: BASE-01.

<a id="com-05"></a>
### COM-05: Find-My-Geräte, AirTags und Personen ehrlich abgrenzen

Abgeschlossen am 19. Oktober 2026 im Daten-/Systemübergabe-Abgrenzungsumfang. [Fähigkeitsmatrix und getrennte Nachweise](findmy-data-boundary.md). Lokale Karte und Demoobjekt sind dauerhaft als nicht live gekennzeichnet; lokaler Ton meldet keine AirTag-Fernaktion. Die ausdrückliche Apple-Geräte-Webübergabe importiert keine Standorte oder Konten.

14 UI-Ausführungen, 13 erfolgreich, ein historischer Sichtbarkeitsfehler; zwei finale Übergabefälle bestanden. Fünf finale SDK-Builds, zehn einzeln bilanzierte API-Typprüfungen ohne Ausführung. Keine realen Standorte, Peers, Accounts oder Hardware. F059 bleibt blocked/parity=false; keine originale Ortungs-/Fernsteuerfunktion wird als geliefert ausgegeben.

Abhängigkeiten: BASE-01.

<a id="day-01"></a>
### DAY-01: Kalenderverbindung und Agenda auf echter Hardware abnehmen

EventKit-Tagesdaten, Wochenleiste, Farbcodes und Geräteauthentifizierung sind angebunden. Reale Accounts wurden nicht abgenommen.

Offen:

- Freigabe/Ablehnung/Widerruf, leere Kalender und Kontowechsel prüfen
- Wiederholungen, ganztägige/abgesagte Termine, Zeitzonen und begrenzte Ergebnismengen korrekt behandeln
- Fremdänderungen aktualisieren und Quelle kennzeichnen

Abnahme: Zuerst synthetischer Vertrag, anschließend bewusst eingerichteter Testkalender auf Hardware. Keine privaten Daten im automatischen E2E.

Abhängigkeiten: SYS-03.

<a id="day-02"></a>
### DAY-02: Erinnerungen mit Listenrechten und Read-back abnehmen

Anzeigen, Anlegen, Erledigen und Löschen über EventKit samt Read-back sind vorhanden, mit synthetischem Anbieter getestet.

Offen:

- Eigene Liste, gemeinsame Listen und nicht schreibbare Listen unterscheiden
- Verweigerte Freigaben und konkurrierende Änderungen behandeln
- Geräteauthentifizierung, Abmelden und Cachelöschung prüfen

Abnahme: Bewusst verwendete Testliste auf Hardware mit exaktem Provider-Read-back. Keine Schreiboperation in persönlichen Listen durch automatisierte Tests.

Abhängigkeiten: SYS-03.

<a id="day-03"></a>
### DAY-03: Mehrere Timer und große Countdown-Ansicht vollständig abnehmen

UI14, Inaktivität und Mehrtimer-Anordnung begrenzt geprüft. Zusätzlich eigene Zwölf-Timer-Grenze, horizontales Auswählen/Löschen und Ablehnung von Nummer13 ohne Auswahlverlust nativ validiert. Bestehende Drei-Timerbilder exakt erhalten. Timer-/Grenz-/Sortierlogik unverändert; Originalmaximum/-layout, gleichzeitiger Ablauf, Hintergrund/Neustart/Zeitwechsel, Systemabgleich und Hardware offen.

Offen:

- Gleichzeitige Timer, Ablauf, Neusortierung und Rückkehr aus Hintergrund testen
- Große Randstriche, Steuerungsverbergen und Überlauf kalibrieren
- App-Neustart, Systemzeitänderung und gestoppte/abgelaufene Systemalarme abgleichen

Abnahme: Eigene Testtimer stimmen nach Unterbrechung mit dem Systemzustand überein. Kein doppelter Alarm oder stehengebliebener Countdown.

Abhängigkeiten: BASE-02.

<a id="day-04"></a>
### DAY-04: Sprachbefehle für Timer und Kochschritte vervollständigen

On-device-Sprache mit Vorschau kann den lokalen Parser bedienen. Rezeptschritte werden bisher per Taste gesteuert.

Offen:

- Timerdauer/Titel und nächster/voriger/Wiederholen-Schritt in Deutsch/Englisch ergänzen
- Mehrdeutigkeit und Erkennungsfehler vor folgenreichen Aktionen klären
- Vorschau-/Senden-Grenze erhalten und Aufnahme begrenzen

Abnahme: Synthetische Transkripte ändern ausschließlich den erwarteten Timer/Schritt. Physische Erkennung gesondert in ruhiger/lauter Umgebung abnehmen.

Abhängigkeiten: SYS-12.

<a id="day-05"></a>
### DAY-05: Live Activities für Timer und zulässige Aktivitäten implementieren

Eigene opt-in Timer-Live-Activity mit WidgetKit-Erweiterung ergänzt. Tatsächlicher System-Read-back auf iPad/iPhone, kompakte iPhone-Anzeige außerhalb der App gesichtet. iPad-Lock-Screen, Hardware und suspendierte Ablaufmatrix bleiben offen. [Quellengebundene Teilumsetzung und historische Fehler](timer-live-activity.md).

Offen:

- Öffentliche ActivityKit-Unterstützung pro Ziel prüfen
- Eigene Timeraktivität mit Statuswechsel, Ablauf und Cleanup implementieren
- Fremde Intercom-/Systemaktivitäten nicht als eigene steuern
- Sichtbarkeit privater Inhalte im Sperrzustand begrenzen

Abnahme: Auf unterstütztem Simulator und Hardware außerhalb der App sichtbar, Pause/Ende konsistent und keine verwaisten Aktivitäten.

Abhängigkeiten: DAY-03.

<a id="day-06"></a>
### DAY-06: Eigene Wecker über Neustart und Gerätebetrieb abnehmen

Eigene AlarmKit-Wecker sind im Simulator geprüft. Andere Plattformen haben nur Vordergrundwecker.

Offen:

- Wiederholung, DST, Zeitzone, Ein/Aus und Löschen gegen Originalumfang klären
- Neustart und entzogene Systemfreigabe abgleichen
- Vordergrund-only-Ziele ausdrücklich kennzeichnen

Abnahme: Bewusst gesetzter Testalarm auf iPad löst auch außerhalb der App aus und lässt sich entfernen; keine Garantie für ungetestete Plattformen.

<a id="day-07"></a>
### DAY-07: Weltuhr um Zonenwahl und Tag-/Nachtanzeige ergänzen

Bis zwölf gespeicherte IANA-Städte, DST-/Datums-/Offsetanzeige und offline Sonnenstandsschätzung vorhanden. Mehrtägiger Kalenderabstand jetzt korrekt beschriftet; 293 Modelltests und begrenzte UI-Gegenprüfung. Originalgeometrie/Sonnenzeitverlauf bleiben offen.

[Datumsgrenzen-Korrektur](world-clock-date-distance.md).

Offen:

- Zusätzliche Zeitzonen auswählen und persistent speichern
- Sommerzeit und Datumsunterschied sichtbar behandeln
- Belegten Tag-/Nachtverlauf und Beschriftungen abgleichen

Abnahme: Zonen mit verschiedenen DST-Regeln und Tageswechsel zeigen richtige Zeit/Datum. Offlinebetrieb ohne feste UTC-Offsets.

<a id="day-08"></a>
### DAY-08: Browser-Navigation und sichere externe Inhalte abnehmen

WKWebView mit URL/Vor/Zurück und lokaler Rezeptfixture vorhanden. Keine vollständige Safari-App.

Offen:

- HTTPS, ungültige URLs, Ladeabbruch, Offline und externe Schemes behandeln
- Website-Inhalte nie als privilegierte App-Befehle interpretieren
- Web-Transportausnahmen prüfen und auf tatsächlich benötigten Umfang begrenzen
- Unverfügbare WebKit-Ziele kenntlich machen

Abnahme: Lokale Testseiten decken Navigation, Fehler und unerwünschte Scheme-Aufrufe ab. Keine Behauptung gemeinsamer Safari-Historie/Passwörter.

<a id="day-09"></a>
### DAY-09: Rezeptimport, Kochansicht und Bibliothek an Randfällen vervollständigen

JSON-LD-Import, Zutaten, große Schritte, Inline-Timer und lokale angeheftete Rezepte sind vorhanden.

Offen:

- Mehrere Recipe-Objekte, fehlende Felder, HowToSections, Einheiten und Portionen behandeln
- Herkunft, Cover, Dauer und Originalschrittfolge kalibrieren
- Timertexte mehrsprachig und eindeutig erkennen
- Anheften, Entfernen, Neustart und fehlerhafte Datensätze prüfen

Abnahme: Eigene Rezeptfixtures prüfen DOM bis Kochschritt und Timer. Import erfindet keine Zutaten/Zeiten, entfernte Rezepte hinterlassen keine falschen Timer.

Abhängigkeiten: DAY-08, BASE-02, PUB-01.

<a id="day-10"></a>
### DAY-10: Rezept-Handoff über öffentliche Continuity-Technik implementieren

Rezepte sind nur lokal gespeichert. Kein nachgewiesenes geräteübergreifendes Handoff.

Offen:

- NSUserActivity-/Universal-Link-Unterstützung und benötigte Entitlements prüfen
- Quelle und aktuellen Rezeptzustand ohne private Datenexfiltration übertragen
- Nicht verfügbare Ziel-App und ungültige Rezeptversionen behandeln

Abnahme: Zwei bewusst eingerichtete Testgeräte übernehmen Rezept/Schritt oder zeigen einen klaren Nichtverfügbarkeitszustand.

<a id="media-01"></a>
### MEDIA-01: MusicKit-Suche, Bibliothek und Player produktiv abnehmen

Katalogsuche, Artwork, ApplicationMusicPlayer und kompakte Leiste sind angebunden, reale Signierung/Abo-/Hardwareabnahme fehlt. Persönliche Bibliothek ist unvollständig.

Offen:

- App-Service-Provisioning und Freigaben mit eigenem Signing korrekt einrichten
- Bibliothek/Katalog, Queue, vor/zurück, Fortschritt und Fremdunterbrechungen behandeln
- Abo fehlt, Region gesperrt, offline und Widerruf darstellen
- Leiste über Navigation und Sperre konsistent halten

Abnahme: Synthetischer Vertrag plus separat bewusster Playback-Test auf Hardware; tatsächliche native Playerzustände statt erfolgreicher Buttonaktion prüfen.

<a id="media-02"></a>
### MEDIA-02: Animiertes Artwork und Lyrics pro öffentlicher Fähigkeit entscheiden

Statische Cover werden angezeigt. Keine allgemeine Original-Lyrics- oder animierte-Artwork-Integration.

Offen:

- Offiziell verfügbare Felder/Rechte und Animationstransporte prüfen
- Nicht verfügbare Lyrics ehrlich ausweisen
- Keine fremden Lyrics scrapen oder Demo-Text als echte Lyrics darstellen
- Reduce Motion und Cachegrenzen für Animationen vorsehen

Abnahme: Fähigkeitsnachweis und tatsächliche Wiedergabe je unterstütztem Inhalt; statische Cover allein schließen F079 nicht.

Abhängigkeiten: MEDIA-01, PUB-01.

<a id="media-03"></a>
### MEDIA-03: Podcasts durch echte frei zugängliche Feedwiedergabe ergänzen

Abgeschlossen am 19. Oktober 2026 im eigenen öffentlichen RSS-Umfang: Explizite öffentliche HTTPS-RSS-Feeds mit FeedKit10.9.4 und AVPlayer, gespeicherter Position, Seek/Pause/Resume, Fehlerpfaden und Aktivitätsrückkehr. Keine Apple-Podcasts-Abos oder Accountsync.

[Umsetzung und Grenzen](public-podcast-feeds.md) · [Quellgebundene Tests](verification/podcast-rss.json). Apple-Podcasts-Originalparität und physische Audio-/AirPlay-Abnahme sind nicht damit behauptet.

<a id="media-04"></a>
### MEDIA-04: Weitere Medien und Drittanbieter-Angebote auf Zugriffsmöglichkeiten prüfen

Recherche abgeschlossen am19.Oktober2026: Fünf Angebote mit öffentlichen Teilpfaden, Rechtevoraussetzungen und Systemhostgrenzen bilanziert.7aktuelle Apple-Dokumentationen und erfolgreicher iOS-Compile-only-Probe. Keine neue Medienintegration; unimplementierte öffentliche Adapter bleiben Softwarearbeit.

[Angebote, APIs, Rechte und aktueller Implementierungsstand](media-service-boundaries.md). Kein Original-App-, Account- oder Hardware-PASS für F084/F085.

<a id="media-05"></a>
### MEDIA-05: AirPlay-Routenauswahl und Mehrraumwiedergabe abnehmen

Keine bewiesene AirPlay-Mehrraumsteuerung in dieser App.

Offen:

- Öffentliche Route-Picker-/AVAudioSession- und MusicKit-Fähigkeiten je Ziel prüfen
- Tatsächliche Route, Verbindungsabbruch und Lautstärke darstellen
- Sender-/Empfängerrolle unterscheiden
- Mehrere Räume nur als unterstützt ausweisen, wenn tatsächlich getestet

Abnahme: Bewusst gewählte Testempfänger liefern hörbare Wiedergabe und korrekten Routenstatus. Eine sichtbare Route-Picker-Schaltfläche ist kein Mehrraum-PASS.

Abhängigkeiten: MEDIA-01.

<a id="media-06"></a>
### MEDIA-06: Gast- und Peer-to-peer-AirPlay separat klären

Keine eigene AirPlay-Empfänger- oder Gast-Discovery-Funktion nachgewiesen.

Offen:

- Hardware-/OS-Voraussetzungen für Gast- und Peer-to-peer-Betrieb dokumentieren
- Keine private Empfängerimplementierung als offizielle Fähigkeit darstellen
- Unterstützten OS-Übergang oder bewusst akzeptierte Alternative definieren

Abnahme: Echte Gast-Testsequenz auf geeigneten Geräten oder weiter explizit blockiert. Normales WLAN-Streaming erfüllt diese Anforderung nicht.

Abhängigkeiten: MEDIA-05.

<a id="media-07"></a>
### MEDIA-07: Medien- und Anruf-Handoff pro Inhaltstyp abgrenzen

Song, Podcast, aktiver Anruf und Video jeweils mit öffentlichen Verträgen und konkreter Lücke abgegrenzt. Eigene Rezept-/Podcastzustände, AirPlay, Apple-System-Handoff und Deep Links getrennt. Geräte-Abnahmeplan einschließlich Abbruch und fehlendem Ziel dokumentiert, nicht ausgeführt. Keine tatsächliche Zwei-Geräte-Sitzungsübernahme; F088 bleibt blockiert.

[Vier Verträge, Lücken und nicht ausgeführter Abnahmeplan](media-handoff-boundaries.md).

Offen:

- Öffentliche Übergabefähigkeit je Inhaltstyp untersuchen
- Eigenen Podcast-/Rezeptzustand von fremden aktiven Sitzungen unterscheiden
- Zwei-Geräte-Abnahme mit Abbruch und nicht verfügbarem Ziel planen

Abnahme: Für jeden Inhaltstyp tatsächlicher unterstützter Übergang oder dokumentierte Lücke. Ein Deep Link ohne Sitzungsübernahme zählt nicht.

Abhängigkeiten: MEDIA-01, MEDIA-03, COM-01.

<a id="sys-01"></a>
### SYS-01: Live-Spiegel, Zoom und Ringlicht auf iPad-Hardware abnehmen

AVFoundation-Vorschau startet bewusst und stoppt beim Verlassen. Zoom/Ringlicht sind UI-Effekte; Hardwarewirkung nicht geprüft.

Offen:

- Frontkamera, Orientierung, Spiegelung, Freigabe/Ablehnung und Unterbrechung prüfen
- Digitalen Bildausschnitt von echtem Hardwarezoom unterscheiden
- Bildschirm-Ringlicht und Bildschirmhelligkeit klar trennen
- Kamera nach Hintergrund und Navigation sicher freigeben

Abnahme: Bewusster physischer Test mit Vorher-/Nachher-Bild und Capture-Lifecycle-Nachweis; keine Kameranutzung im Mock-E2E.

<a id="sys-02"></a>
### SYS-02: Control Center und Settings mit echten Zuständen abgleichen

Control Center steuert Mock-Netzstatus, Nacht/Fernansicht, lokale Displayabdunklung und App-Audiolautstärke. Kein systemweites WLAN-/Helligkeits-Panel.

Offen:

- Originalumfang und öffentlich steuerbare Einstellungen separat erfassen
- Simulationen, App-Werte und OS-Zustände sprachlich unterscheiden
- Keep-awake, Dimming, Audio und Verbindungswiderruf robust persistieren
- Fehlende Originaloptionen einzeln bilanzieren

Abnahme: Jeder Schalter liest den tatsächlich gesteuerten Zustand zurück. Kein Mock-Online-Schalter als System-WLAN und keine Overlayabdunklung als gemessene Hardwarehelligkeit.

Abhängigkeiten: BASE-02.

<a id="sys-03"></a>
### SYS-03: Sechs Nutzer, Gerätebindung und persönliche Freigabe sicher vervollständigen

Sechs bewusst gewählte Demo-Profile und lokale Trennung sind vorhanden. Keine biometrische Identifikation oder Partnergerätebindung.

Offen:

- Öffentliche Authentifizierung und tatsächlich mögliche Partnergerätebindung prüfen
- Demo-Auswahl niemals als Berechtigung auf echte Daten akzeptieren
- Identitätswechsel, Ausweg, Abmelden und Eigentümerwechsel definieren
- Nicht öffentlich verfügbare Gesichtserkennung als Originalgrenze behalten

Abnahme: Synthetische Mehrnutzer-Szenarien belegen Isolation. Gerätedaten bleiben gesperrt, bis echte Authentifizierung erfolgreich ist; keine erfundene Gesichtserkennung.

Abhängigkeiten: BASE-01.

<a id="sys-04"></a>
### SYS-04: Persönliche Inhalte bei Weggehen und Unterbrechungen zuverlässig verbergen

Abmelden, Hintergrund und Inaktivitäts-Timeout sperren verbundene Daten. Entfernen der aktiven RootView widerruft jetzt ebenfalls die persönliche Sitzung; vorübergehende Scene-Inaktivität allein erhält sie. [Begrenzte Reproduktion und Gegenprüfung](root-disappearance-privacy.md). Tatsächliches Weggehen und physische Snapshots bleiben ungeprüft.

Offen:

- Sperre an bewiesene Präsenzquelle koppeln, falls verfügbar
- Vorschauen, Kalender, Reminder, Assistentenverlauf und Medienkontext beim Sperren bereinigen
- Timer/Klingel/Appwechsel dürfen Schutz nicht aufheben
- App-Switcher-Snapshot auf private Reste prüfen

Abnahme: Deterministische Präsenz-/Timeout-Tests sowie Profilwechsel während laufender Requests. Späte Antworten können gesperrte Daten nicht erneut anzeigen.

Abhängigkeiten: SYS-03, FACE-06.

<a id="sys-05"></a>
### SYS-05: Gastberechtigungen für Haus, Wetter, Timer und Musik definieren

Gastpfad und einzelne persönliche Gates existieren, vollständige Policy für verbundene Quellen fehlt.

Offen:

- Explizite Gast-Policy je Aktion und Datenquelle festlegen
- Sicherheitsaktionen, persönliche Listen und Kommunikationsdaten sperren
- Für gemeinsam freigegebene Medien Quellen und Widerruf beachten
- Alle Einstiegspfade einschließlich Widgets und Assistent prüfen

Abnahme: Eine Aktionsmatrix mit Gast, Nutzer und Eigentümer wird durch synthetische E2E abgedeckt. Versteckte Knöpfe allein ersetzen keine Modellautorisierung.

Abhängigkeiten: SYS-03, HOME-01.

<a id="sys-06"></a>
### SYS-06: Secure-Exclaves-Identitätsverarbeitung als Hardwaregrenze dokumentieren

Keine eigene Gesicht-/Stimmidentifikation in Secure Exclaves und keine belegte öffentliche Gleichwertigkeit.

Offen:

- Öffentliche Geräteauthentifizierung von eigener biometrischer Datenverarbeitung unterscheiden
- Keine Gesicht-/Stimmtemplates aus Demos erzeugen
- Hardware- und API-Voraussetzungen mit Quellen belegen

Abnahme: Anforderung bleibt unerfüllt, sofern kein nachgewiesener öffentlicher Weg existiert. LocalAuthentication wird nicht als eigener Secure-Exclaves-Port ausgegeben.

Abhängigkeiten: BASE-01.

<a id="sys-07"></a>
### SYS-07: Private Cloud Compute als externe Systemfähigkeit bilanzieren

Keine nachgewiesene allgemeine PCC-Anbindung der App.

Offen:

- Aktuelle öffentliche Apple-Intelligence-Schnittstellen prüfen
- Lokale Modelle, eigener Cloudanbieter und PCC strikt unterscheiden
- Datenweitergabe nur gemäß bewusst gewähltem eigenen Anbieter zulassen

Abnahme: Dokumentierter unterstützter API-Pfad oder sichtbare offene Originalgrenze. Ein externer LLM-Aufruf gilt niemals als PCC.

Abhängigkeiten: BASE-01, AI-01.

<a id="sys-08"></a>
### SYS-08: Ersteinrichtung, Capability-Erklärung und verbundene Angebote ausarbeiten

Einzelne Verbindungsknöpfe sind vorhanden. Kein vollständiger Setup-Assistent und keine klar abgenommene Angebotsverwaltung.

Offen:

- Gerät, Eigentümer, Datenverbindungen, Mockmodus und fehlende Fähigkeiten verständlich einführen
- Berechtigungen erst am erforderlichen Schritt anfragen
- Verbindung trennen und lokale Daten zurücksetzen anbieten
- Keine beliebige Fremd-App-Installation oder eigenen Store vortäuschen

Abnahme: Neustart, Setup-Abbruch, verweigerte Freigabe und späteres Verbinden funktionieren ohne persönliche Daten in Tests.

Abhängigkeiten: SYS-02, SYS-03.

<a id="sys-09"></a>
### SYS-09: Unzureichenden Stromadapter auf unterstützter Hardware erkennen oder ausweisen

Keine nachgewiesene Erkennung der Adapterleistung oder äquivalente Stromwarnung.

Offen:

- Öffentlich verfügbare Strom-/Batterieinformationen auf Zielgeräten prüfen
- Keine Wattzahl oder Minderleistung aus unbelegten Heuristiken behaupten
- Fehlende Sensorfähigkeit je Plattform dokumentieren

Abnahme: Nachgewiesener Messpfad mit geeigneten Adaptern oder explizit nicht verfügbar. SDK-Build erfüllt keinen Hardwaretest.

Abhängigkeiten: BASE-01.

<a id="sys-10"></a>
### SYS-10: Accessibility über alle zentralen Flows abnehmen

Beschriftete Controls und alternative Navigation vorhanden, keine vollständige Accessibility-Abnahme. Benanntes Control für den ruhenden Timer ergänzt, ohne sichtbare Geometrie zu verändern. [Begrenzte Reproduktion, Gegenprüfung und offene Hilfsmittel-Lanes](timer-accessible-controls.md).

Weltuhr: drei sichtbare öffentliche Hitflächen-Audits pro Gerät ohne Restbefund; Add/Done, Auswahl, Entfernen und Schließen mit gemessenen nativen Mindestflächen und realen Randaktionen geprüft. Historische Fehlstände und Test-Scrollkorrektur getrennt dokumentiert. Keine tatsächliche Hilfsmittel-/Hardware-/Originalabnahme. Docs/world-clock-hit-regions.md. [Messungen und Grenzen](world-clock-hit-regions.md).

Lokale Wecker: drei vollständige sichtbare Hitflächen-Audits pro Gerät leer; Ein/Aus, Add, konkretes Löschen und Close mit nativen Mindestflächen und echten Rand-Taps geprüft. Uhrzeitlabel und Off/On/Off als AX-Wert beobachtet, keine tatsächliche Hilfsmittel- oder Systemalarmabnahme. Docs/alarm-hit-regions.md. [Befunde und Grenzen](alarm-hit-regions.md).

Offen:

- VoiceOver-Reihenfolge, Werte, Fokus und dynamische Updates prüfen
- Zoom/Dynamic Type sowie Kontrast und reduzierte Bewegung abnehmen
- Voice Control, Switch Control und AssistiveTouch mit der eigenen UI prüfen
- Gestenexklusive Aktionen per zugänglichem Control anbieten

Abnahme: Face-Editor, Sperre, Timer, Kamera, Rezept und Verbindungen sind ohne präzise Wischgeste oder Sehvermögen bedienbar. Ergebnisse je Hilfsmittel dokumentieren.

<a id="sys-11"></a>
### SYS-11: Live Speech, Captions, RTT und Shortcuts pro Plattform klären

Eigene parameterlose App-Shortcut-Öffnung für iOS/macOS/visionOS mit Compilermetadaten und nativer Body-/Root-Prüfung; echte Siri-/Shortcuts-/Geräteausführung offen. Live Speech/Captions/Vocal Shortcuts und RTT/Medienuntertitel weiterhin getrennt bilanziert.

[API-Matrix](speech-feature-boundaries.md) · [begrenzter App-Einstieg](assistant-app-shortcut.md).

Offen:

- App-eigene und OS-bereitgestellte Unterstützung getrennt erfassen
- Öffentliche App-Intents/Shortcuts und Untertitel für eigene Medien prüfen
- Fremde Telefonie-/Siri-Funktionen nicht als eigene Implementierung deklarieren
- Fehlende Live-Speech-/RTT-Fähigkeiten einzeln bilanzieren

Abnahme: Nachgewiesene Nutzbarkeit je Zielplattform und Hilfsmittel oder konkrete Blockade. Ein Textfeld erfüllt nicht sämtliche F105-Unterfunktionen.

Abhängigkeiten: SYS-10.

<a id="sys-12"></a>
### SYS-12: On-device-Spracherkennung auf echter Hardware abnehmen

Speech/AVFoundation mit explizitem Start, Deutsch/Englisch, Vorschau, Abbruch und 30-Sekunden-Limit vorhanden; UI-Tests speisen synthetische Transkripte ein.

Offen:

- Mikrofon-/Speech-Freigabe, fehlendes On-device-Modell und Offlinezustand testen
- Akustische Qualität bei Musik, Timer und unterschiedlicher Entfernung prüfen
- Kein Cloud-Fallback und kein fortgesetztes Capture nach Abbruch/Hintergrund
- Unterbrochene Audioengine ohne Doppelaufnahme wiederherstellen

Abnahme: Bewusster Test auf iPad mit tatsächlichem Audio. Synthetische Transkription bleibt klar von Hardware-Speech-PASS getrennt.

<a id="qa-01"></a>
### QA-01: Finalen öffentlichen Stand mit vollständiger iPad-/iPhone-Regression einfrieren

Private Baseline hatte zuletzt 32 Modelltests und je vier gezielte Flow-UI-Läufe, fünf SDK-Builds. Frühere Vollsuiten gehören zu früheren Digests. Öffentliche Assets und Ziffern sind neu.

Offen:

- Öffentliche Quellen samt Ressourcen hashen
- Vollständige Core- und UI-Suite auf iPad/iPhone für denselben finalen Digest ausführen
- Eigene Screenshots der öffentlichen Ersatzassets prüfen
- Fehler/Überspringen, Laufzeitwarnungen und ungetestete Grenzen dokumentieren

Abnahme: Ein digestgebundener Abschlussbericht statt vermischter historischer Zähler; sichtbare Rendererprüfung ergänzt DOM-/Accessibility-Assertions.

Abhängigkeiten: PUB-01.

<a id="qa-02"></a>
### QA-02: Physisches iPad signieren, installieren und dauerhaft betreiben

Kein physisches iPad installiert oder vollständig abgenommen. Unsignierter SDK-Build ist kein Geräte-PASS.

Offen:

- Eigenes Signing und benötigte Capabilities konfigurieren
- Touch, Orientation, Displaywachhaltung, Audio, Kamera und bewusste Accounts prüfen
- Mehrstündigen Vordergrund-/Unterbrechungsbetrieb mit Energie, Temperatur und Speicher messen
- Offline-, Freigabe- und Neustartzustände prüfen

Abnahme: Geräte-/OS-/Build-Digest und konkrete Ergebnisse im Bericht. Keine automatischen persönlichen Accountzugriffe oder echten Home-Aktionen.

Abhängigkeiten: QA-01.

<a id="qa-03"></a>
### QA-03: Visuelle Parity aller belegten Zustände und Animationen abnehmen

Ausgewählte historische Bildvergleiche vorhanden, keine vollständige Pixel-/Animationsabnahme.

Offen:

- Geometrie, Typografie, Farbe, Materialien und Übergänge je Referenzzustand prüfen
- Unverzerrte Screens und Perspektivfotos getrennt bewerten
- Fehlende/berichtete Zustände nicht als gesehen ausgeben
- Pro Face und Fluss Restabweichungen dokumentieren

Abnahme: Jeder bestätigte Originalzustand hat reproduzierbare aktuelle Aufnahme und menschliche Sichtprüfung. Restlücken und Systemblockaden bleiben im Ergebnis sichtbar.

Abhängigkeiten: BASE-02, PUB-01, QA-01.

<a id="qa-04"></a>
### QA-04: macOS, tvOS, visionOS und Watch als eigene Plattformabnahmen führen

Fünf SDK-Ziele bauen historisch. Nur iOS/iPadOS besitzen vollständige UI-Simulatorläufe; Mac nur Start-/Fenster-Smoke. Watch ist reduziert.

Offen:

- Mac-Fenstergrößen, Tastatur/Maus und Freigaben testen
- TV-Fokus/Fernbedienung und fehlende WebKit-/Kamera-/Fotopfade abnehmen
- Vision-Fenster/Eingabe und tatsächliche APIs prüfen
- Watch-Begleitumfang explizit abnehmen, nicht als volle quadratische Oberfläche zählen

Abnahme: Je Ziel getrennte Runtime-/Hardwarematrix. Kein fehlender Runtime-Test wird durch einen erfolgreichen SDK-Build ersetzt.

Abhängigkeiten: QA-01.

<a id="qa-05"></a>
### QA-05: Persistenz, Migration, Offline und späte Antworten systematisch prüfen

Lokale Zustände und ausgewählte Neustart-/Offlinefälle sind getestet. Vollständige Daten- und Lifecycle-Matrix fehlt.

Offen:

- Face-/Slot-/Galerie-/Timer-/Rezept-/Profilmigration mit alten und beschädigten Daten prüfen
- Verbindungsabbrüche und spätes Providerergebnis nach Abmelden/Navigation simulieren
- Nur begrenzte eigene Testordner nutzen und Löschen auf diese beschränken
- Kein vermeintlicher Erfolg bei fehlgeschlagenem Write

Abnahme: Deterministische Regression ohne Datenausfluss, Cross-Profile-Leaks, doppelte Aktionen oder beschädigten normalen Nutzerspeicher.

Abhängigkeiten: SYS-03.

[Begrenzter Zustandsdatei-Reader: Start, Linkgrenzen und Gegenprüfung](bounded-state-startup.md).

<a id="qa-06"></a>
### QA-06: Dauerleistung, Energie und Animation-Lifecycle vermessen

Langzeit-Farb- und numerische Stabilität von Flow sind geprüft. Keine gemessene Geräteenergie oder umfassende Speicher-/Framezeitabnahme.

Offen:

- CPU/GPU/Framezeit und Speicher je Face sowie neun Kamerafeeds messen
- Inaktiver ScenePhase und Reduce Motion müssen Arbeit tatsächlich reduzieren
- Langläufe mit Wechsel, Sperre, Kamera und Wiedergabe durchführen
- Messgerät, Dauer, Baseline und Ausreißer dokumentieren

Abnahme: Reproduzierbare Messwerte und begründete Zielbudgets auf echter Hardware, keine pauschale Batterie-/Beschleunigungsbehauptung.

Abhängigkeiten: QA-02.

<a id="extra-01"></a>
### EXTRA-01: Palette, Bounce-Gitter und Flux als optionale Watch-inspirierte Erweiterungen bewerten

Statische Buildhinweise vorhanden. Diese Faces sind nicht als notwendige HomeView-Parity-Anforderung belegt.

Offen:

- Produktentscheidung vor zusätzlicher Implementierung treffen
- Bei Annahme eigene Assets, Zustände und separate Abnahme definieren
- Nicht in den Kern-Parity-Nenner aufnehmen, solange Originalbezug fehlt

Abnahme: Explizite Entscheidung mit belegtem Ziel. Optionale Erweiterungen schließen keine offenen Originalfunktionen.

Abhängigkeiten: BASE-01.

## Vollständigkeit

[function-coverage.json](function-coverage.json) weist jede der 105 Ausgangsfunktionen einem oder mehreren Paketen zu. [backlog.json](backlog.json) enthält Aufgaben und Abnahmekriterien maschinenlesbar. Keine der 105 Funktionen wird hier als vollständig originalgleich abgenommen ausgegeben.

Apple Home bleibt bis zur ausdrücklich fortgesetzten Einrichtung gesperrt. Persönliche Accounts, Kommunikation und Kameras sind keine automatischen Testziele. Nicht verfügbare Siri-, HKSV-, Intercom-, Find-My-, Secure-Exclaves- und PCC-Fähigkeiten bleiben sichtbar blockiert.


## Abschluss 19. Oktober 2026

[SYS-02 / #65](settings-state.md) ist im bilanzierten App-Control-Umfang abgeschlossen. Die drei Musik-Suchfehler sind unter [QA-05](music-search-lifecycle.md) behoben; #67/#80 bleiben für ihre breiteren Kriterien offen. Die [Fade-Flächenkorrektur](fade-surface-tones.md) ist geliefert; #18 bleibt für Originalzeitkurve und weitere Details offen. Apple Home bleibt deaktiviert.
