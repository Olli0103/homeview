# Native Settings: Live Speech und RTT ohne Aktivierung inventarisiert

29. Oktober 2026 · [#74](https://github.com/Olli0103/homeview/issues/74). **Read-only-Systemoberfläche im Simulator, keine HomeView-Funktions-, Hilfsmittel-, Telefonie- oder Hardwareabnahme.** Ergänzt die [sechs Plattformen und positiven Apple-Quellen](speech-platform-update-20261029.md). F104/F105 bleiben ohne Parity; #74 bleibt offen.

## Was tatsächlich ausgeführt wurde

Eigene accountfreie tvOS-27- und visionOS-27-Simulatoren starteten die unveränderten nativen Settings-Apps. Nur die Accessibility-Kategorie wurde geöffnet. Danach TV-Fokusbewegung beziehungsweise Vision-Tabellenscrollen und die lokalen Suchtexte `RTT`/`Live Speech`; Suchtext abschließend gelöscht. Keine Feature-Zeile aktiviert, keine Schalter, Konten, Anrufe oder Mikrofone. Die Vision-Kamera ist ausschließlich die öffentliche **virtuelle Simulator-Screenshot-Kamera**, keine reale Aufnahme.

| Probe | Beobachteter Befund | Zulässige Schlussfolgerung |
|---|---|---|
| TV-Menü | Zehn Down-Aktionen, zweimal identischer Endfokus. Neun Zeilen von Hover Text bis Accessibility Shortcut. Live Speech/RTT nicht sichtbar. | Nur dieser Simulator-Menüstand. Die offizielle TV-Anleitung N7 dokumentiert VoiceOver, das hier ebenfalls fehlt. Deshalb keine OS-Nichtverfügbarkeitsbehauptung. |
| Vision-Menü | Live Speech zunächst nur im AX-Modell außerhalb des Fensters; native langsame Tabellenaktion bringt die Zeile vollständig in den vorher festgelegten Clip. Zeile zeigt weiterhin **Off**. | Vorhandene, tatsächlich gerenderte Einstellungszeile; keine Sprach- oder Anruffunktion geprüft. |
| Vision-Suche `RTT` | Literal eingegeben; Sidebar ohne Trefferzeile, bisheriger Accessibility-Detailbereich bleibt. | Kein RTT-Pfad gefunden, aber auch kein belastbarer negativer OS-Beweis. |
| Positive Suchkontrolle `Live Speech` | Bekannt vorhandene und sichtbare Funktion liefert ebenfalls keine Trefferzeile; Detailbereich unverändert. | Suchindex/-verhalten in dieser Umgebung nicht positiv qualifiziert. Die leere Sidebar ist kein RTT-Negativtest und keine behauptete „No Results“-Meldung. |

Die drei letzten Vision-Zustände sind jeweils innerhalb einer zehnsekündigen nativen Haltephase per tatsächlicher Simulator-Kamera aufgenommen und gehasht. Die dekodierten Bilder und feste Fensterausschnitte wurden gesichtet: Zeile und Suchtexte sichtbar, Live Speech weiterhin Off. Rohbilder mit Apples virtueller Umgebung und rohe System-AX-Bäume bleiben privat; veröffentlicht werden nur eigene Tests und abgeleitete Befunde/Digests.

## Testgeschichte und Bindung

**Sieben tatsächliche Settings-Ausführungen: fünf erfolgreich, zwei frühere Eingabeversuche fehlgeschlagen.** Kein gemeinsamer finaler Fünferlauf: Root-Inventar, Kategorie-Inventar und tiefer Vision-Fall stammen aus getrennten eingefrorenen Testquellständen. Die fünf erfolgreich ausgeführten Methoden sind in der Abgabe unverändert erhalten.

Der erste tiefe Vision-Versuch scheiterte beim appgebundenen Koordinatenereignis mit ungültiger leerer Scene-ID, noch vor einer gehaltenen Aufnahme. Fenstergebundene Gutter-Gesten wurden danach akzeptiert, bewegten die Zeile aber in acht Versuchen nicht; die unveränderte Sichtbarkeitsassertion schlug fehl. Erst die semantische langsame Tabellenaktion erfüllte denselben Clip. Keine Änderung an Settings, keine gelockerte Sichtbarkeitsgrenze und kein erfundener HomeView-Produktfehler.

Alle sieben Quellen-/Compiler-/Launch-Archive vollständig zurückgelesen und gegen ihre Dateimanifeste geprüft. Installierte eigene UITestrunner und Testbundles passen zu den ausgeführten Binaries; Settings-Info/Executable-Hashes vor/nachher unverändert. **Die frisch kompilierte HomeView-App war hier nicht das Testobjekt und wurde nicht gestartet**: Der ursprüngliche `installed_own_app_verified=false`-Befund bleibt erhalten, statt ihn in einen HomeView-PASS umzudeuten. Die ersten beiden Runnerprüfungen sind separat reconciliert.

Alle **165 Produkt-/Ressourceninputs bleiben exakt `3aa94a6`**. Nur TV-/Vision-UITestdateien erweitert; entsprechende Testziele gebaut. Kein neuer Core-Lauf oder Fünf-SDK-Produkt-PASS behauptet. Fünf erfolgreiche Ergebnisübersichten enthalten keine Skips/strukturierten XCTest-Runtime-Warnungen; rohe Vision-Logs enthalten dennoch einen Backlight-XPC-Hinweis. [Quellen, einzelne ausgeführte Stände, Ergebnis- und Archivbindung](verification/os-speech-settings-inventory-20261029.json).

## Verbleibende konkrete Grenzen

- TV Live Speech/RTT und Vision RTT sind mit diesen Menüs/Suchoberflächen weiterhin **nicht positiv geklärt**, nicht als „OS unmöglich“ klassifiziert. Die verfügbaren negativen Oberflächen sind durch die genannten Gegenkontrollen nicht als vollständiger Fähigkeitskatalog geeignet.
- Vision Live Speech ist laut spezialisiertem Apple-Guide N5 an Anrufe gebunden. Keine autorisierte Gesprächsumgebung/Gegenseite und keine physische Abnahme im Prüfumfang; keine Ausgabe oder Telefonie-Uplink behauptet.
- Vorhandene eigene Untertitel und echte frühere mobile OS-Shortcut-Aufrufe bleiben separat belegt. Dictation, Type to Siri, Live Captions und Vocal Shortcuts sind keine durch diesen Settings-Lauf abgenommenen Dienste.
- Geräte-/Signing-Pause und Home-Sperre bleiben unverändert. Übrige Softwarearbeit wird fortgesetzt; keine erneute Einrichtung angefordert.
