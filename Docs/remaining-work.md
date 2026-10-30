# Verbleibende Arbeit und Grenzen

**Aktuell30.Oktober:42 ursprüngliche Issues erledigt,1 Snoopy-Ausschluss,39 offen.** [Vollständiger frischer GitHub-Abgleich](verification/backlog-reconciliation-20261030.json). [#25](https://github.com/Olli0103/homeview/issues/25) ist im ursprünglichen Mock-Sicherheitsumfang geschlossen; F028 bleibt ohne reale Home-/Original-Parity. #24 ist ebenfalls nach seinem ursprünglichen synthetischen Gerätevertrag abgeschlossen; weiter mit der originalen Rechercheabnahme von #74 unter unveränderten Home-/Geräte-Holds.

- [Zwei native Fehlermeldungen im App-Umschalter geschützt](app-switcher-alerts.md): vier Vorherfehler und vier verworfene Rückkehrfehler erhalten; zwölf aktuelle UI-Ausführungen/fünf SDKs bestanden. Meldung, Picker und Read-only-Speicher bleiben erhalten. Weitere OS-Composer, physische/Präsenz-/Mediengrenzen bei #67 offen.

- [Neun zusätzliche Root-Eingaberouten geschützt](app-switcher-root-fields.md): neun iPhone-Vorherfehler und neun bereits grüne iPad-Gegenkontrollen; genaue Entwürfe bleiben erhalten.34 aktuelle UI-Ausführungen/fünf SDKs. Native Composer, Alerts und physische/Präsenz-/Mediengrenzen bei #67 offen.

- [Elf zusätzliche Sheet-Präsentationen geschützt](app-switcher-sheets.md): 22 tatsächliche Vorher-Snapshots korrigiert, 20 finale UI-Ausführungen/fünf SDKs. Native OS-Composer, Alerts/weitere Felder und physische/Präsenz-/Mediengrenzen bei #67 offen.

- [App-Umschalter: Tastatur über Assistenten-/Reminder-Schutz schließen](app-switcher-keyboard.md): zwei iPhone-Vorherfehler und zwei schon grüne iPad-Gegenkontrollen getrennt; zehn finale UI-Ausführungen/fünf SDKs. Keine pauschale Snapshot-Abnahme.

- [App-Umschalter: offene Profil-/Stadtdialoge verdecken](app-switcher-dialogs.md): vier echte Vorherfehler korrigiert; zwölf aktuelle UI-Ausführungen und fünf SDKs. Weitere Präsentationen und physische Abnahme bei #67 offen.

- [Kalender im tatsächlichen OS-App-Umschalter](app-switcher-calendar.md): vier finale UI-Ausführungen, vollständige Karten und Hintergrund/Fresh Unlock geprüft. Andere persönliche Routen/Sheets, Präsenz/Medien und physische Snapshots bleiben bei #67 offen.

- [Wetter-Quellenlink: vier echte native Randaufrufe mit richtigem Safari-Ziel](weather-attribution-os-route.md); getrennte Testquelle, Produkt unverändert. #73 bleibt für übrige Kriterien offen.

29. Oktober 2026. **41 von 82 ursprünglichen Paketen geschlossen, 41 offen: 40 im dokumentierten Umfang abgeschlossen und 1 ausdrücklicher Scope-Ausschluss (#14/Snoopy, `not_planned`, nicht implementiert).** [Eigentümerentscheidung](scope-exclusions.md). Der vollständige [40/42-Abgleich](verification/backlog-reconciliation-20261029.json) bleibt als früherer Prüfstand erhalten; die zusätzliche #14-Schließung ist [exakt zurückgelesen](verification/snoopy-scope-exclusion-20261029.json). Das zusätzliche Community-Issue #83 ist geschlossen und wird nicht in den ursprünglichen Nenner eingerechnet.

## Aktueller Arbeitsblock

- [Eigene TV-/Vision-Quelluntertitel nativ geprüft](tv-vision-source-captions.md): zwei getrennte akzeptierte Vollfälle, sechs erhaltene Fehlversuche; TV-Cue durch Remote erreichbar und Rückweg zur Feedliste korrigiert. Fünf finale SDKs/73Outputs/242Inputs; Core unverändert. #74 weiter offen für übrige OS-Pfade und sichtbare Vision-Warmzielwahl.

- [#74: alle48 Plattform-/Hilfsmittelzellen bilanziert](speech-acceptance-ledger-20261030.md): vier historisch benutzbare Teilpfade, dokumentierte Setup-/Host-/Appgrenzen; fünf OS-Pfade und drei eigene Softwareprüfungen noch offen. Vision-Inventur1PASS, drei Kalt-/WarmmethodenFAIL;14 tatsächliche Kamerabilder geprüft, Diagnose aus Standardtarget bytegenau entfernt. Kein neuer Produktcode oder voreilige Schließung.

- [#24: ursprünglicher synthetischer Gerätevertrag geprüft](mock-device-contract.md): alle vier Regler mit Erfolg/Timeout/Ablehnung/Fremdänderung und Neustarts;449Coretests, letzte neun native Mobil-/TV-/Watch-Ausführungen/fünf SDKs. Read-only-/Stale-Metadata-/Plan-Dialogfehler getrennt korrigiert. Keine reale Home-/Original-Parity; Veröffentlicht mit `06ba7e7`; Issue24 als closed/completed mit exaktem Body und unveränderter ursprünglicher Abnahme zurückgelesen.

- [#25: ursprünglicher Mock-Schloss-Sicherheitsvertrag erfüllt](mock-lock-security.md):429Coretests, zwölf aktuelle native UI-Ausführungen/fünf SDKs sowie unabhängige1152Vektoren/5775Bedingungen und Terminal-Cancel-Gegenprobe bestanden. Gerätefreigabe statt Demo-Profil, separate30s-Einmalbestätigung, Widerruf, Unknown/Jammed/Batteriefehler und nichtoptimistischer Read-back. Echte Home-/Identitätsbindung bleibt #23/#66, F028partial/parity=false. Veröffentlichung sowie geschlossener Issue-State mitreasoncompleted, unverändertem Aufgaben-/Abnahmetext und Labels frisch zurückgelesen; Zähler jetzt40offen. Danach #24: typisierter Geräte-/Read-back-Vertrag unter unveränderter Home-Sperre, nicht weitere kleine Schriftpakete.

- **Abschlussorientierung,30.Oktober, vor#25:** damals40 ursprüngliche Issues erledigt,1 Snoopy-Ausschluss,41 offen. Die letzten Schrift-/Kontrastlieferungen schließen kein weiteres Issue. Alle41 ursprünglichen Abschlusskriterien erneut gelesen; nicht pauschal als Hardwareblockaden eingestuft. Nächster unabhängiger Softwareblock: **#25** (explizite kurzlebige Bestätigung, Zustandsbestätigung und negative Mock-Sicherheitsfälle). Keine Änderung der Home-Sperre. Mac-Abnahme bei#79 bleibt konkret blockiert: Entwicklermodus weiterhin aus, Gateway-Computerzugang nicht verfügbar, kein verbundener Computer-Node; frühere erfolglose Starts werden nicht blind wiederholt oder durch SDK-Builds ersetzt.

- [Weltuhr-Kontrastdurchgang abgeschlossen](world-clock-contrast.md):16 aktuelle UI-Ausführungen/fünf SDKs, zehn normale Textbedingungen6,90–7,00:1.27 von36 vorab qualifizierten Außenvergleichen exakt; neun iPhone-Paare am OS-Home-Indikator strikt fehlgeschlagen, zwölf weitere Posen weiterhin unqualifiziert. Kein aufgeweichter Bildvertrag und keine Issue-Schließung.

- [Weltuhr: Liste, Städtewahl und natives Detail skalieren](world-clock-dynamic-type.md):18 aktuelle UI-Ausführungen/fünf SDKs,38 gemeldete Textausdehnungen wachsen und48 ganze normale Root-/Sheet-Paare exakt gleich. Vier native Messinstrumentfehler erhalten, acht AX-Textkind-Gaps und Lese-/Kontrast-/Hilfsmittelgrenzen offen; #53/#73 bleiben offen.

- [Podcast-Texte auf weißem Root kontrastiert](podcast-contrast.md):20 native normale Farbbedingungen jetzt6,90–7,00:1; zwölf aktuelle UI-Ausführungen/fünf SDKs.22 vorab qualifizierte Außenvergleiche exakt,50 Zielrahmen gleich;28 Scrollposen unqualifiziert. Nur neun lokale Farben geändert; #73 bleibt für weitere Flows/Lese-/Hilfsmittelgrenzen offen.

- [Podcast-UI: Systemschrift ohne geänderte Normalansicht](podcast-controls-dynamic-type.md): zwölf aktuelle UI-Ausführungen/fünf SDKs,40 gemeldete Textausdehnungen wachsen,50 ganze normale RGBA-Paare exakt gleich. Native Feed-Controls schon vorher skalierend/unverändert; acht AX-Textkind-Gaps, Lese-/Kontrast-/Hilfsmittelgrenzen offen. Neue Inventuren ohne Wiedergabe, separate bestehende Caption-Regression nur mit stummem eigenem Bundle; #73 offen.

- [Pausierte Demo-Musik skaliert und scrollt](demo-music-dynamic-type.md): acht akzeptierte aktuelle UI-Ausführungen/fünf SDKs. 14 Textausdehnungen wachsen, alle 16 normalen ganzen RGBA-Paare exakt gleich; vier übernommene Scroll-Instrumentfehler erhalten. Kein Playback/Provider-/Kontrast-/Hilfsmittel-PASS, #73 offen.

- [Foto-/Album-Einstellungen: Systemschrift und Kontrast](photo-controls-accessibility.md): 18 aktuelle UI-Ausführungen/fünf SDKs grün. 26 native Textbedingungen wachsen; 18 qualifizierte Kontrastbedingungen 7,00:1, zwei XXXL-Ganztext-ROIs bleiben unqualifiziert. Keine pauschale Normalpixel-/Hilfsmittel-/Original-Parity; #73/#11 offen.

- [Native Fotoauswahl auf Fenster-Ebene geschützt, iPhone-Tastaturebene offen](native-photos-snapshot.md): zehn aktuelle neue UI-Ausführungen mit neun PASS/einem ausdrücklich offenen 98%-Keyboardguard; zwölf bestehende Regressionen und fünf SDKs grün. Bild-/Suchinhalt verdeckt, ausstehende Auswahl/Suchentwurf erhalten. Kein vollständiger #67-Abschluss.

- [Tatsächliches OS-Reduce-Motion statt bloßem Launchflag](system-reduce-motion.md): acht PID-gebundene OFF→ON→OFF-Fälle auf beiden Simulatoren; acht exakt stille und16 bewegte Regionpaare. Alle17 Präferenz-Ausführungen zurückgestellt/zurückgelesen,165 Produktinputs unverändert. Frühere ungemessene Lifetime-Marker und ein Indexfehler bleiben getrennt; #73 offen.

- [Verbindungsaktionen nennen ihren Dienst](service-action-labels.md): 16 AX-/native Namensbedingungen rot→grün; zehn akzeptierte aktuelle UI-Ausführungen/fünf SDKs. Vier ganze Normal-/Fokus-Pixelpaare exakt gleich. Alte Wiederverbindungsfehler auch mit Vorher-App reproduziert, spätere Beobachtung ausdrücklich keine Ursachenklärung; sichtbare Eingabevorbereitung qualifiziert, alle Callback-/Rückkehrbedingungen erhalten. #73 offen.

- [Native VoiceOver-Fokus-/Sprachausgabe](native-voiceover-focus.md): zwölf qualifizierte Einstiegsfälle auf iPhone/iPad,165 Produktinputs unverändert. Roh-Touch-/Tastaturwege scheitern auch am unabhängigen UIKit-Button; keine ausschließlich HomeView-spezifische Ursache.17 UI-Ausführungen insgesamt13PASS/4FAIL, alle VoiceOver-Rückstellungen zurückgelesen. Zwei falsche Rezeptvorgaben korrigiert, Originalfehler erhalten; #73 bleibt offen.

- [Demo-Kamera: Systemschrift und endliches Accessibility-Scrollraster](camera-dynamic-type.md):22 akzeptierte aktuelle UI-Ausführungen über zwei Testpins bei bytegleicher App/fünf aktuelle SDKs.46 Textbedingungen/vier separate Buchstabenpaare wachsen;20 normale und zwei große eingefrorene Face-Pixelpaare exakt gleich. Vier Overlay-Selektorfehler, vier frühe Lazy-AX-Fehler und ein ungeklärter iPhone-Scrollfehler erhalten; Foto-Kontrast/Hilfsmittel bei #73 offen.

- [Verbindungen und lokale Sperransichten skalieren und kontrastieren](connections-lock-dynamic-type.md):18 akzeptierte aktuelle UI-Ausführungen bei bytegleicher App über drei Testpins, fünf SDKs.62 Textausdehnungs- und48 Kontrastbedingungen grün;22 exakt passende Normalpaare außerhalb der Farbrollen gleich,24 Scrollposen ausdrücklich unqualifiziert. Fünf aktuelle Instrumentfehler erhalten; keine realen Verbindungen oder Authentifizierung, #73 offen.

- [Rezept-Systemschrift, Scrollwege und vier Textfarben korrigiert](recipe-dynamic-type.md): zwölf aktuelle UI-Ausführungen/fünf SDKs;46 Textausdehnungsbedingungen und16 Farbbedingungen grün.14 normale Rezeptpaare außerhalb der Farbrollen gleich, zwei Timer-Einrichtungsbilder exakt gleich. Vier anfängliche Helferfehler und drei unqualifizierte Eck-ROIs erhalten; #73 für übrige Flows/Hilfsmittel offen.

- [Face-Editor-Anleitung und Slotfamilie kontrastiert](face-editor-root-contrast.md): acht Messungen jetzt6,19–7,00:1; sechs frische UI-Ausführungen/fünf SDKs. Vier Vorherfälle ausdrücklich wiederverwendet. Sieben passende Pixelpaare außerhalb der Textregionen gleich; ein anders gescrolltes XXXL-iPad-Paar unqualifiziert erhalten. Vollständiger Issue-Verlauf archiviert, Kriterien erhalten; #73 offen.

- [Face-Editor: fünf UI-Schriftrollen skalieren](face-editor-dynamic-type.md): zehn aktuelle UI-Ausführungen/fünf SDKs, vier normale Pixelpaare exakt gleich. Eine iPhone-Controlhöhen-Bedingung bleibt rot; tatsächlich gerenderter Chip-Schriftzug separat rund2,7-fach vergrößert. Kein Farbfix am unqualifizierten Glas-Kontrast, #73 offen.

- [Timer-Einrichtung skaliert ohne geänderte Normalansicht](timer-setup-dynamic-type.md): sechs Vorher-Vergrößerungsbedingungen korrigiert;20 aktuelle UI-Ausführungen/fünf SDKs, sechs normale Aufnahmen exakt pixelgleich. Acht Start-Randaktionen waren schon vorher grün und bleiben es, trotz kleinerer AX-Höhe auf dem iPhone. #73 offen für übrige Flows/Hilfsmittel.

- [Timer-Systemschrift und Accessibility-Anordnung korrigiert](timer-dynamic-type.md): drei Rollen wachsen auf iPhone/iPad, echte Auswahl/Löschen erhalten pausierte Peer-Werte. Vier normale Ansichten exakt pixelgleich;20 akzeptierte UI-Ausführungen über zwei Testpins bei bytegleicher App/fünf SDKs. Vorherige Eingabe- und Zeitfensterfehler erhalten; #73 weiter offen.

- [TV-/Vision-Settings ohne Aktivierung inventarisiert](os-speech-settings-inventory-20261029.md): fünf erfolgreiche OS-Oberflächenfälle, zwei frühere Eingabeversuche getrennt erhalten. Vision Live Speech sichtbar Off; bekannte positive Such-/Menükontrollen fehlen ebenfalls, daher keine negative RTT-/TV-OS-Behauptung.165 Produktinputs unverändert; #74 offen, weitere App-Arbeit läuft.

- [Profil-Editor-Kontrast korrigiert](personal-editor-contrast.md):16 eigene Textmessungen jetzt etwa6–18:1 statt selbst maximal <1,31:1. Acht aktuelle UI-Ausführungen/fünf SDKs; Geometrie, Konfiguration und Rückkehrpixel unverändert. Nur lokales Editorschema, #73 weiter offen.

- [Sieben Done-/Cancel-Trefferrechtecke korrigiert, zwei native Toolbar-Controls unverändert gegengeprüft](secondary-hit-regions.md):36 aktuelle UI-Ausführungen/fünf SDKs. Echte44-Punkte-Randpunkte außerhalb nativer AX-Bounds funktionieren; verworfene Vorbehalte getrennt erhalten. Profil-Editor-Kontrast [im separaten Folgestand korrigiert](personal-editor-contrast.md); #73 offen.

- [Assistenten-Systemschrift und Done-Rechteck korrigiert](assistant-dynamic-type.md): drei Antwort-Textrollen wachsen nun in größter Accessibility-Kategorie; vier normale Antwortansichten exakt pixelgleich.18 aktuelle UI-Ausführungen/fünf SDKs; Gerätepräferenzen zurückgestellt. Nur dieser Teilumfang, #73 für übrige Flows/Hilfsmittel offen.

- [Manuelles Vorlesen sichtbarer Antwortkarten vervollständigt](card-readout.md):18 Vorherfehler in76AppModel-Assertions; danach405Coretests/76AppModel-Assertions,14 aktuelle UI-Ausführungen/fünf SDKs bestanden. Kein automatisches Sprechen oder versteckte Quellen-/Aktionsinhalte; #36 für Original-/Live-/Hilfsmittelgrenzen offen.

- [iOS-Shortcut-Paketvollständigkeit abgesichert](shortcut-package-completeness.md): drei fehlende generierte Dateien trotz Compilererfolg kontrolliert reproduziert; bestehender Buildweg prüft Artefakte, bewahrt Erstbefund und führt höchstens einen normalen Clean-Build aus. Sechs Tooling-Tests, echter Guard-Wiederherstellungspfad und fünf frische SDKs; kein neuer OS-Hilfsmittelaufruf, #74 offen.

- [Native TV-Kamera-Gegenkontrolle und fokussierbare Fotogalerie](tv-camera-photos.md): sechs aktuelle TV-Methoden/vier mobile Fotoregressionen/fünf frische SDKs bestanden. Next photo erreicht und Bildnummer frei. Keine Live-Quellen oder Geräteabnahme; #79 offen. Die dort zusätzlich beobachtete inkrementelle Shortcut-Verpackungsgrenze ist [separat reproduziert und abgesichert](shortcut-package-completeness.md).

- [Fiktiver Nachrichtenbeleg als zusätzlicher Antworttyp](assistant-message-evidence.md):398Coretests/zehn aktuelle native mobile UI-Ausführungen/fünf SDKs bestanden. Kein Nachrichten-API oder ausführbarer Karteninhalt; #36 für Live-/Original-/Hilfsmittelkriterien offen.

- [Alle vier vorhandenen S07-GIFs vollständig eingeordnet](remaining-original-gifs-20261029.md):299 Frames, Kameraface→Home und Numerals→Assistentenantwort; Artikelkontext geprüft, kein sichtbarer Aktivierungsvorgang oder neue Gestenkennlinie. Ausgewähltes Kamera-Face liegt bereits hinter dem eigenen Home-Raster; keine unbelegte Produktänderung. #6/#19/#36 weiter offen.

- [Native Vision-Fenster/Eingabe/Timer/lokaler Browser](vision-native-runtime.md): vier aktuelle Methoden bestanden, fünf tatsächliche virtuelle Kamerabilder zeitgebunden. Kein Produkt-Rendererfix,165 Produktinputs unverändert. Größenänderung/Mehrfenster, reale APIs und physische Eingabe bleiben separat offen bei #79.

- [Native Watch-Installation und unabhängige Temperaturaktionen korrigiert](watch-native-runtime.md): zwei aktuelle native Methoden/fünf SDKs bestanden; reduzierte eigenständige Oberfläche, keine Geräte-/Energie-/volle iPad-Abnahme. #79/#81 für übrige Kriterien offen. Separater [Vision-Nachweis](vision-native-runtime.md) liegt vor.

- [Native TV-Remote und Timerfokus](tv-remote-runtime.md): echter Vorherfehler behoben, vier aktuelle TV-Methoden/zwei mobile Timerregressionen/fünf SDKs bestanden. TV-Kamera-/Foto- und übrige Plattform-/Geräteabnahmen bei #79 offen; [Watch](watch-native-runtime.md) und [Vision](vision-native-runtime.md) getrennt nachgewiesen.

- [#3: lokaler Historienbereinigungskandidat](asset-history-cleanup-candidate.md) vorbereitet: bekannter Icon-Blob entfernt, heutiger Baum exakt identisch. Keine öffentliche Umschreibung/pauschale Rechtefreigabe; andere historische Einzelherkunft offen.

- [Sprache/RTT: aktuelle spezialisierte OS-Pfade und einzelne Grenzen](speech-platform-update-20261029.md). Zwölf Live-Speech-/RTT-Zellen bilanziert, drei OS-Pfade noch nicht positiv geklärt; tatsächliche Hilfsmittel-/Gesprächsabnahmen getrennt. #74 bleibt offen.

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

Geschlossen bedeutet Abschluss des dokumentierten Issue-Umfangs oder einen ausdrücklich benannten Eigentümer-Scope-Ausschluss, nicht automatisch vollständige Parity jeder zugeordneten Originalfunktion. Die ursprünglichen Aufgaben und Kriterien bleiben in [backlog.json](backlog.json) erhalten.

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
| [#14](https://github.com/Olli0103/homeview/issues/14) | Snoopy-Szenen, Atlanten und Timelines klären | Eigentümer-Ausschluss wegen der Rechte (29. Oktober), `not_planned` geschlossen. Nicht implementiert/abgenommen; kein Ersatz als Original-PASS. [Scope](scope-exclusions.md). |
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
| [#25](https://github.com/Olli0103/homeview/issues/25) | Türschloss mit echter Autorisierung und Zustandsbestätigung absichern | Geschlossen im ursprünglichen Mock-Sicherheitsvertrag: Gerätefreigabe, separate Einmalbestätigung, Widerruf, Fehlerzustände und bestätigter Read-back. Reales Home und Haushaltsbindung bleiben #23/#66; F028partial/parity=false. |
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
| [#67](https://github.com/Olli0103/homeview/issues/67) | Persönliche Inhalte bei Weggehen und Unterbrechungen zuverlässig verbergen | Offen. Kalender, dokumentierte Sheets/Eingaberouten, zwei generische native Fehleralerts und nativer Foto-Picker-Inhalt im Simulator geschützt; separate iPhone-Picker-Tastaturebene, weitere OS-Präsentationen, Präsenz/Medien/Unterbrechungen und physische Snapshots offen. |
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
