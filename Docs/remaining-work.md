# Verbleibende Arbeit und Grenzen

- [Elf zusätzliche Sheet-Präsentationen geschützt](app-switcher-sheets.md): 22 tatsächliche Vorher-Snapshots korrigiert, 20 finale UI-Ausführungen/fünf SDKs. Native OS-Composer, Alerts/weitere Felder und physische/Präsenz-/Mediengrenzen bei #67 offen.

- [App-Umschalter: Tastatur über Assistenten-/Reminder-Schutz schließen](app-switcher-keyboard.md): zwei iPhone-Vorherfehler und zwei schon grüne iPad-Gegenkontrollen getrennt; zehn finale UI-Ausführungen/fünf SDKs. Keine pauschale Snapshot-Abnahme.

- [App-Umschalter: offene Profil-/Stadtdialoge verdecken](app-switcher-dialogs.md): vier echte Vorherfehler korrigiert; zwölf aktuelle UI-Ausführungen und fünf SDKs. Weitere Präsentationen und physische Abnahme bei #67 offen.

- [Kalender im tatsächlichen OS-App-Umschalter](app-switcher-calendar.md): vier finale UI-Ausführungen, vollständige Karten und Hintergrund/Fresh Unlock geprüft. Andere persönliche Routen/Sheets, Präsenz/Medien und physische Snapshots bleiben bei #67 offen.

- [Wetter-Quellenlink: vier echte native Randaufrufe mit richtigem Safari-Ziel](weather-attribution-os-route.md); getrennte Testquelle, Produkt unverändert. #73 bleibt für übrige Kriterien offen.

29. Oktober 2026. **40 von 82 ursprünglichen Paketen geschlossen, 42 offen.** Alle ursprünglichen Nummern wurden mit den aktuellen offenen und geschlossenen GitHub-Issues abgeglichen. Das zusätzliche Community-Issue #83 ist geschlossen und wird nicht in den ursprünglichen Nenner eingerechnet. [Read-back](verification/backlog-reconciliation-20261029.json).

## Aktueller Arbeitsblock

- [Wetter-App und Stadtdialog: native Trefferflächen korrigiert](weather-surface-hit-regions.md); zwölf finale UI-Ausführungen, vier leere Audits, fünf SDKs. #73 weiter offen für übrige Kriterien.
- [Wetter-Einstellungen: Stadtfeld/Einheiten und Tastatur-Sichtbarkeit korrigiert](weather-settings-hit-regions.md); zehn finale UI-Ausführungen/fünf SDKs. #73 bleibt für übrige Accessibility-Kriterien offen.
- [Fade-Zeitabbildung nachgeprüft](fade-time-mapping-review.md): sichtbare Lücke bei geschätzter 9:25-Pose; keine weitere Fade-Sequenz in sieben zusätzlichen Filmzeitpunkten. Keine geratene Sekundenbindung übernommen; #18 offen.
- [Native Mac-Startgrenze](mac-runtime-boundary.md) dokumentiert: Builds vorhanden, kein beobachteter UI-Methodenlauf. Keine unbelegte Cmd+A-Änderung, keine Hostberechtigungen aktiviert. #79 bleibt offen; übrige Software-/Referenzarbeit unabhängig fortsetzen.
- [Face-Karten und Rückrichtung korrigiert](face-transition-cards.md): native Vorher-/Nachher-Filme belegen den Fix, sechs volle Ruhepaare pixelgleich.22 erfolgreiche UI-Ausführungen über zwei Testvarianten, zwei alte Testannahmen-Fehler behalten, fünf SDKs. #6 bleibt für Originalkurven und vollständige Bewegungsabnahme offen.
- [Editor-Farben isoliert](face-color-isolation.md): Home ändert Modular nicht mehr ungefragt; feste Home-Clock-Palette bietet keine wirkungslosen Farbtasten. 397 Coretests, zwölf UI-Ausführungen, fünf SDKs; eigene gespeicherte Zustände und exakte Pixel geprüft. #7 bleibt für vollständigen Originaleditor offen.
- [Original-GIF-Nachprüfung](transition-reference-review-20261029.md): 158 Frames gesichtet, sichtbare Teilfolge erhalten; keine vollständige Standardreihenfolge oder Langsam-/Schnell-/Abbruchregel abgeleitet. #6 bleibt offen.

- Weltuhr: Tageslicht über Mitternacht und einzelne Horizontkreuzungen korrekt als Intervalle darstellen; unbekannten Sonnenstand neutral markieren. [Umsetzung und Grenzen](world-clock-midnight-daylight.md). #53 bleibt wegen der fehlenden konkreten Originalreferenz offen.
- Assistenteneingabe: [#38 im ursprünglichen synthetischen Softwareumfang abgeschlossen](assistant-input-acceptance.md). 18 aktuelle UI-Ausführungen und fünf SDKs; echter OS-Control-Center-Wechsel und Cmd-Period ohne Senden. Unabhängige UIKit-No-ops sind kein Raw-Key-PASS; physische Hilfsmittel und Original-Parity bei #73/#77/#78 bleiben offen.
- [Tatsächlicher App-Shortcut-Aufruf aus Apples Kurzbefehle-App](assistant-os-shortcut.md) auf eigenen frischen iPad-/iPhone-Simulatoren bestanden: normaler OS-Kaltstart und Warmaufruf ohne UITesting-Speicher/Flags, keine implizite Aktion. #74 bleibt für übrige Hilfsmittel-/Plattformgrenzen offen.
- Geräte-/Signing-Abnahmen bleiben auf [ausdrücklichen Eigentümerwunsch pausiert](device-acceptance-hold.md). Das pausiert keine übrige Softwarearbeit und ist keine Erlaubnis zum Schließen unerfüllter Kriterien.

## Verbindlicher Vorrang

Das Ziel bleibt die belegte native Apple-HomeView-Kopie, keine freie Neugestaltung. Originalgeometrie, Bewegung, Funktionsnachweis und echte Geräte-/Dienstabnahme sind getrennt. Umsetzbare Arbeit wird nicht pauschal als Hardwareblockade bezeichnet. Persönliche Quellen werden nur bewusst verbunden; echte Home-Einrichtung und Gerätezugriff bleiben ausgeschlossen.

## Vollständiger aktueller Paketstatus

Geschlossen bedeutet Abschluss des dokumentierten Issue-Umfangs, nicht automatisch vollständige Parity jeder zugeordneten Originalfunktion. Die ursprünglichen Aufgaben und Kriterien bleiben in [backlog.json](backlog.json) erhalten.

| Issue | Arbeit | Status / nächste Grenze |
|---|---|---|
| [#1](https://github.com/Olli0103/homeview/issues/1) | Verbindlichen Parity-Vertrag und API-Grenzen festschreiben | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#2](https://github.com/Olli0103/homeview/issues/2) | Vollständigen Referenzsatz für Zustände und Bewegungen sichern | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#3](https://github.com/Olli0103/homeview/issues/3) | Redistribuierbare Grafik- und Typografiegrundlage herstellen | Offen. Aktuelle Ressourcen und öffentlicher historischer Asset-/Rechteumfang getrennt; #3 nicht vollständig abgenommen. |
| [#4](https://github.com/Olli0103/homeview/issues/4) | Quelllizenz und Veröffentlichungsunterlagen festlegen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#5](https://github.com/Olli0103/homeview/issues/5) | Face-Katalog und Varianten vollständig gegen Referenz abnehmen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#6](https://github.com/Olli0103/homeview/issues/6) | Face-Wechsel und App-Raster-Übergänge vermessen | Offen; zusätzliche Software-, Originalzustands-/Geometrie-/Bewegungsabnahme erforderlich. |
| [#7](https://github.com/Olli0103/homeview/issues/7) | Räumlichen Face-Editor vollständig kalibrieren | Offen. Farb-Querveränderung und wirkungslose Auswahl korrigiert; Originalgeometrie, vollständige Optionen/Familien/Anbieter und physische Abnahme bleiben offen. |
| [#8](https://github.com/Olli0103/homeview/issues/8) | Geteilte Modular-Inhalte mit echten Freigaben trennen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#9](https://github.com/Olli0103/homeview/issues/9) | Persönlichen Home Screen und App-Anordnung abnehmen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#10](https://github.com/Olli0103/homeview/issues/10) | Entfernung und Bewegung durch nachgewiesene Präsenzquelle steuern | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#11](https://github.com/Olli0103/homeview/issues/11) | Foto-Galerie und geteilte Alben vervollständigen | Offen; zusätzliche Software-, Originalzustands-/Geometrie-/Bewegungsabnahme erforderlich. |
| [#12](https://github.com/Olli0103/homeview/issues/12) | Motivgeschützte Uhrplatzierung und Bildausschnitt berechnen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#13](https://github.com/Olli0103/homeview/issues/13) | Tageszeit-, Nacht- und reduzierte Face-Zustände vervollständigen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#14](https://github.com/Olli0103/homeview/issues/14) | Snoopy-Szenen, Atlanten und Timelines klären | Offen. Rechtmäßig nutzbare vollständige Snoopy-Szenen/Timelines fehlen; keine Ersatzfigur als Original-PASS. |
| [#15](https://github.com/Olli0103/homeview/issues/15) | Variable Flow-Ziffern mit korrekten Metriken entwickeln | Offen; zusätzliche Software-, Originalzustands-/Geometrie-/Bewegungsabnahme erforderlich. |
| [#16](https://github.com/Olli0103/homeview/issues/16) | Flow-Glas, Fluidparameter und Originalbewegung kalibrieren | Offen; zusätzliche Software-, Originalzustands-/Geometrie-/Bewegungsabnahme erforderlich. |
| [#17](https://github.com/Olli0103/homeview/issues/17) | CPU-Fluid schrittweise auf Metal-Texturen portieren | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#18](https://github.com/Olli0103/homeview/issues/18) | Fade-Verlauf und zeitabhängige Ziffern abgleichen | Offen; zusätzliche Software-, Originalzustands-/Geometrie-/Bewegungsabnahme erforderlich. |
| [#19](https://github.com/Olli0103/homeview/issues/19) | Numerals-Typografie und analoge Uhrvarianten kalibrieren | Offen; zusätzliche Software-, Originalzustands-/Geometrie-/Bewegungsabnahme erforderlich. |
| [#20](https://github.com/Olli0103/homeview/issues/20) | Prismen-Hintergrund und analoge Materialschichten angleichen | Offen; zusätzliche Software-, Originalzustands-/Geometrie-/Bewegungsabnahme erforderlich. |
| [#21](https://github.com/Olli0103/homeview/issues/21) | Wetterdaten, Wolken, Regen und Frost vollständig abnehmen | Offen; zusätzliche Software-, Originalzustands-/Geometrie-/Bewegungsabnahme erforderlich. |
| [#22](https://github.com/Olli0103/homeview/issues/22) | Monatskalender-Face vollständig abnehmen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#23](https://github.com/Olli0103/homeview/issues/23) | HomeKit-Einrichtung und Adapter nach ausdrücklichem Fortsetzen implementieren | Offen; reale Home-Einrichtung/-Geräte im laufenden Auftrag nicht freigegeben. Übrige Grenzen bleiben erhalten. |
| [#24](https://github.com/Olli0103/homeview/issues/24) | Thermostat, Licht, Lüfter und Beschattung echt anbinden | Offen; reale Home-Einrichtung/-Geräte im laufenden Auftrag nicht freigegeben. Übrige Grenzen bleiben erhalten. |
| [#25](https://github.com/Olli0103/homeview/issues/25) | Türschloss mit echter Autorisierung und Zustandsbestätigung absichern | Offen; reale Home-Einrichtung/-Geräte im laufenden Auftrag nicht freigegeben. Übrige Grenzen bleiben erhalten. |
| [#26](https://github.com/Olli0103/homeview/issues/26) | Szenen und Routinen mit nachgewiesenem Umfang bedienen | Offen; reale Home-Einrichtung/-Geräte im laufenden Auftrag nicht freigegeben. Übrige Grenzen bleiben erhalten. |
| [#27](https://github.com/Olli0103/homeview/issues/27) | Echte Kamera-Streams bis neun Feeds und Detailaktionen anbinden | Offen; reale Home-Einrichtung/-Geräte im laufenden Auftrag nicht freigegeben. Übrige Grenzen bleiben erhalten. |
| [#28](https://github.com/Olli0103/homeview/issues/28) | Türklingel-Ereignis und Unterbrechungsregeln umsetzen | Offen; reale Home-Einrichtung/-Geräte im laufenden Auftrag nicht freigegeben. Übrige Grenzen bleiben erhalten. |
| [#29](https://github.com/Olli0103/homeview/issues/29) | Gegensprechen mit Audio-Lifecycle und Freigaben ergänzen | Offen; reale Home-Einrichtung/-Geräte im laufenden Auftrag nicht freigegeben. Übrige Grenzen bleiben erhalten. |
| [#30](https://github.com/Olli0103/homeview/issues/30) | HKSV-Erkennung und Archivsuche als API-Lücke entscheiden | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#31](https://github.com/Olli0103/homeview/issues/31) | Hausereignisse in einer gruppierten Mitteilungsansicht darstellen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#32](https://github.com/Olli0103/homeview/issues/32) | Rauch-/CO-Geräuscherkennung und eigene Sensoren auf Machbarkeit prüfen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#33](https://github.com/Olli0103/homeview/issues/33) | Allgemeinwissen und fortgesetzten Dialog durch echten Assistenten ersetzen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#34](https://github.com/Olli0103/homeview/issues/34) | Persönlichen Kontext und Onscreen Awareness sicher begrenzen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#35](https://github.com/Olli0103/homeview/issues/35) | Mehrschrittige Aktionen mit Bestätigung und Teilfehlern ausführen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#36](https://github.com/Olli0103/homeview/issues/36) | Antwortansicht mit Text, Bildern und Karten vervollständigen | Offen. Lokale Antwortkarten vorhanden; tatsächliche VoiceOver- und Originalabnahme fehlen. |
| [#37](https://github.com/Olli0103/homeview/issues/37) | Wakeword und Siri-Aktivierung als getrennte Systemgrenze behandeln | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#38](https://github.com/Olli0103/homeview/issues/38) | Assistenten-Geste, Texteingabe und Entwurfserhalt abnehmen | Geschlossen im ursprünglichen synthetischen Softwareumfang; physische Hilfsmittel/Original-Parity bleiben #73/#77/#78. |
| [#39](https://github.com/Olli0103/homeview/issues/39) | Dialogverlauf und geräteübergreifende Fortsetzung klären | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#40](https://github.com/Olli0103/homeview/issues/40) | Antwortstimme, Tempo und Medienunterbrechungen ergänzen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#41](https://github.com/Olli0103/homeview/issues/41) | Dienstverfügbarkeit, Sprachen und Limits sichtbar machen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#42](https://github.com/Olli0103/homeview/issues/42) | FaceTime-Annahme und aktive Anrufsteuerung als API-Lücke bilanzieren | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#43](https://github.com/Olli0103/homeview/issues/43) | Center Stage auf geeigneter Kamera-Hardware prüfen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#44](https://github.com/Olli0103/homeview/issues/44) | Explizite Nachrichten- und Anruf-Systemübergaben abnehmen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#45](https://github.com/Olli0103/homeview/issues/45) | Intercom zu HomePods und persönlichen Geräten auf Machbarkeit prüfen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#46](https://github.com/Olli0103/homeview/issues/46) | Find-My-Geräte, AirTags und Personen ehrlich abgrenzen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#47](https://github.com/Olli0103/homeview/issues/47) | Kalenderverbindung und Agenda auf echter Hardware abnehmen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#48](https://github.com/Olli0103/homeview/issues/48) | Erinnerungen mit Listenrechten und Read-back abnehmen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#49](https://github.com/Olli0103/homeview/issues/49) | Mehrere Timer und große Countdown-Ansicht vollständig abnehmen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#50](https://github.com/Olli0103/homeview/issues/50) | Sprachbefehle für Timer und Kochschritte vervollständigen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#51](https://github.com/Olli0103/homeview/issues/51) | Live Activities für Timer und zulässige Aktivitäten implementieren | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#52](https://github.com/Olli0103/homeview/issues/52) | Eigene Wecker über Neustart und Gerätebetrieb abnehmen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#53](https://github.com/Olli0103/homeview/issues/53) | Weltuhr um Zonenwahl und Tag-/Nachtanzeige ergänzen | Offen. Zonen, DST/Datum und Tageslicht weitergebaut; konkrete Originalansicht/-bewegung bleibt unbelegt. |
| [#54](https://github.com/Olli0103/homeview/issues/54) | Browser-Navigation und sichere externe Inhalte abnehmen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#55](https://github.com/Olli0103/homeview/issues/55) | Rezeptimport, Kochansicht und Bibliothek an Randfällen vervollständigen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#56](https://github.com/Olli0103/homeview/issues/56) | Rezept-Handoff über öffentliche Continuity-Technik implementieren | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#57](https://github.com/Olli0103/homeview/issues/57) | MusicKit-Suche, Bibliothek und Player produktiv abnehmen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#58](https://github.com/Olli0103/homeview/issues/58) | Animiertes Artwork und Lyrics pro öffentlicher Fähigkeit entscheiden | Offen. Statische Cover und Fähigkeitsanzeige vorhanden; echte Lyrics/Animationen und deren Rechte/Adapter fehlen. |
| [#59](https://github.com/Olli0103/homeview/issues/59) | Podcasts durch echte frei zugängliche Feedwiedergabe ergänzen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#60](https://github.com/Olli0103/homeview/issues/60) | Weitere Medien und Drittanbieter-Angebote auf Zugriffsmöglichkeiten prüfen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#61](https://github.com/Olli0103/homeview/issues/61) | AirPlay-Routenauswahl und Mehrraumwiedergabe abnehmen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#62](https://github.com/Olli0103/homeview/issues/62) | Gast- und Peer-to-peer-AirPlay separat klären | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#63](https://github.com/Olli0103/homeview/issues/63) | Medien- und Anruf-Handoff pro Inhaltstyp abgrenzen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#64](https://github.com/Olli0103/homeview/issues/64) | Live-Spiegel, Zoom und Ringlicht auf iPad-Hardware abnehmen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#65](https://github.com/Olli0103/homeview/issues/65) | Control Center und Settings mit echten Zuständen abgleichen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#66](https://github.com/Olli0103/homeview/issues/66) | Sechs Nutzer, Gerätebindung und persönliche Freigabe sicher vervollständigen | Offen. Echte Geräte-/Haushaltsidentitätsbindung und persönliche Freigabe nicht vollständig nachgewiesen. |
| [#67](https://github.com/Olli0103/homeview/issues/67) | Persönliche Inhalte bei Weggehen und Unterbrechungen zuverlässig verbergen | Offen. Kalender und zwei offene Dialoge im Simulator geschützt; weitere Präsentationen, Präsenz/Medien/Unterbrechungen und physische Snapshots offen. |
| [#68](https://github.com/Olli0103/homeview/issues/68) | Gastberechtigungen für Haus, Wetter, Timer und Musik definieren | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#69](https://github.com/Olli0103/homeview/issues/69) | Secure-Exclaves-Identitätsverarbeitung als Hardwaregrenze dokumentieren | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#70](https://github.com/Olli0103/homeview/issues/70) | Private Cloud Compute als externe Systemfähigkeit bilanzieren | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#71](https://github.com/Olli0103/homeview/issues/71) | Ersteinrichtung, Capability-Erklärung und verbundene Angebote ausarbeiten | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#72](https://github.com/Olli0103/homeview/issues/72) | Unzureichenden Stromadapter auf unterstützter Hardware erkennen oder ausweisen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#73](https://github.com/Olli0103/homeview/issues/73) | Accessibility über alle zentralen Flows abnehmen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#74](https://github.com/Olli0103/homeview/issues/74) | Live Speech, Captions, RTT und Shortcuts pro Plattform klären | Offen. Eigene Untertitel und tatsächliche Kurzbefehle-Kalt-/Warmaufrufe auf iPad/iPhone belegt; übrige OS-Hilfsmittel, RTT, Mac-/Vision-Laufzeit und physische Abnahmen offen. |
| [#75](https://github.com/Olli0103/homeview/issues/75) | On-device-Spracherkennung auf echter Hardware abnehmen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#76](https://github.com/Olli0103/homeview/issues/76) | Finalen öffentlichen Stand mit vollständiger iPad-/iPhone-Regression einfrieren | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#77](https://github.com/Olli0103/homeview/issues/77) | Physisches iPad signieren, installieren und dauerhaft betreiben | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#78](https://github.com/Olli0103/homeview/issues/78) | Visuelle Parity aller belegten Zustände und Animationen abnehmen | Offen; zusätzliche Software-, Originalzustands-/Geometrie-/Bewegungsabnahme erforderlich. |
| [#79](https://github.com/Olli0103/homeview/issues/79) | macOS, tvOS, visionOS und Watch als eigene Plattformabnahmen führen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#80](https://github.com/Olli0103/homeview/issues/80) | Persistenz, Migration, Offline und späte Antworten systematisch prüfen | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
| [#81](https://github.com/Olli0103/homeview/issues/81) | Dauerleistung, Energie und Animation-Lifecycle vermessen | Offen; verlangte Geräte-/Dienst-/Hilfsmittelabnahme fehlt bzw. ist pausiert. Weitere Softwarearbeit nicht pauschal ausgeschlossen. |
| [#82](https://github.com/Olli0103/homeview/issues/82) | Palette, Bounce-Gitter und Flux als optionale Watch-inspirierte Erweiterungen bewerten | Geschlossen im dokumentierten Umfang; keine pauschale Original-/Hardware-Parity. |
