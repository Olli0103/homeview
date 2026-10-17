# Bearbeitungsstand

## Fortlaufender Gesamtauftrag

Ein erfolgreicher Zwischencommit beendet den Parity-Auftrag nicht. Weitere
freigegebene, nicht blockierte Arbeit wird ohne erneutes „weiter“ fortgesetzt.
`39464d4`: [Prismen und Glaskacheln](home-prisms.md), 99 Modelltests, acht gezielte
UI-Ausführungen und fünf SDK-Builds. #20 bleibt in der Originalabnahme offen.

`5f00961`: [profilgetrennte Home-Layouts und Medienwidgets](personal-home-layouts.md)
mit dem Renderer zusammengeführt. 103 Modelltests, 16 gezielte UI-Ausführungen und
fünf SDK-Builds auf einem gemeinsamen Freeze. #9 bleibt offen; die weitere
Apps-/Wettervariante aus der Originalsequenz wird bereits bearbeitet.

`efff917`: [Fade-Zeiger und Relief](fade-reference-detail.md), 103 Modelltests,
sechs gezielte UI-Ausführungen und fünf SDK-Builds; #18 bleibt offen.

`754890a` / `5efd09f`: [Apps-/Wetterraster und Gestenkorrektur](personal-weather-grid.md),
104 Modelltests, 22 gezielte UI-Ausführungen und fünf SDK-Builds im integrierten
Stand. #9 bleibt offen; angeschnittene Artist-Zeile wird weiter korrigiert.

`35fc888` / `5cc126a` / `45383b5`: [Numerals und vollständig sichtbare Artist-Zeile](numerals-reference.md),
104 Modelltests, acht gezielte UI-Ausführungen und fünf SDK-Builds. #19 bleibt in
der vollständigen Originalabnahme offen. Weitere Home-Analoguhrdetails in Arbeit.

`27dde45` / `b874075`: [Kleine Home-Raster-Uhr](home-grid-clock.md), 104 Modelltests,
sechs gezielte UI-Ausführungen und fünf SDK-Builds. Eigene Kamera-Demoassets
werden als nächster sichtbarer Korrekturschritt integriert.

`2776f7c` / `facfa9a`: [Vier eigene Kamera-Demoassets und vollständiger Nacht-Viewport](demo-camera-assets.md),
104 Modelltests, zwölf gezielte UI-Ausführungen und fünf SDK-Builds. Nur markierte
generierte Standbilder, keine echten Streams. Foto-Demoassets werden getrennt
weiter korrigiert; das Gesamtgoal bleibt aktiv.

## 17. Oktober 2026 · zweites Issue-Paket

[Prüfbericht und eigene Bilder](iteration-20261017-block2.md) · [alle verbleibenden Pakete](remaining-work.md).

| Paket | Stand | Grenze |
|---|---|---|
| [FLOW-01, #15](https://github.com/Olli0103/homeview/issues/15) | Wieder offen | Bisherige eigene Glyphen treffen Apple HomeView nicht. Form, Stencil, Proportionen und Material werden gegen UI47 korrigiert. |
| [DAY-07, #53](https://github.com/Olli0103/homeview/issues/53) | Funktional erweitert | Zonenwahl/Persistenz, DST, Datum, Sonnenstandsschätzung. Originalverlauf/Geometrie offen. |
| [DAY-01, #47](https://github.com/Olli0103/homeview/issues/47) | Software gehärtet | Kalenderrechte, Tagesgrenzen, Vorkommen und Quelle. Physischer Testkalender/Accountwechsel offen. |
| [DAY-02, #48](https://github.com/Olli0103/homeview/issues/48) | Software gehärtet | Listenrechte, eigener Zielkalender, exakter Read-back. Reale gemeinsame/Read-only-Listen offen. |
| [DAY-08, #54](https://github.com/Olli0103/homeview/issues/54) | Abgeschlossen | Bounded HTTPS-/WebKit-Navigation mit lokalen Fehler-/History-/Stop-Tests, keine Safari-Kontosynchronisierung. |
| [DAY-04, #50](https://github.com/Olli0103/homeview/issues/50) | Parser/Kochsitzung erweitert | Physische Erkennung und weitere Formulierungen offen. |
| [DAY-09, #55](https://github.com/Olli0103/homeview/issues/55) | Abgeschlossen | Mehrere Rezepte, keine erfundenen Metadaten, stabile IDs und begrenzte Schritte. |
| [AI-06, #38](https://github.com/Olli0103/homeview/issues/38) | Entwurf abgesichert | Erhalt bei Navigation, Löschung bei Hintergrund/Sperre; Originalgesten/Hardware offen. |
| [QA-05, #80](https://github.com/Olli0103/homeview/issues/80) | Speicherung gehärtet | Einzelreparatur und verifizierte Originalbytes; breitere Provider-/Fehlerabnahme offen. |
| [QA-01, #76](https://github.com/Olli0103/homeview/issues/76) | Abgeschlossen | 86 Modelltests und je 65 vollständige UI-Fälle, fünf SDK-Builds auf `0296d04`. |

Die gemeinsame historische Regression auf `0296d04` umfasst 86 Coretests und fünf SDK-Builds. Jeder der neun Code-Commits hat gezielte iPad-/iPhone-Prüfungen sowie einen erneuten Modelltestlauf nach dem Commit. Die terminalen Ergebnisbündel bestätigen 130 erfolgreiche UI-Ausführungen, null Fehler/Skips und keine von XCTest gemeldeten Runtime-Warnungen. Zusammen 216 erfolgreiche Modell-/UI-Ausführungen; Quellen vor/nach dem Lauf identisch.

Nach Eigentümerreview wurde #15 wieder geöffnet: **76 der ursprünglichen 82 Pakete bleiben offen**. Der Eigentümer hat MIT gewählt: [#4](https://github.com/Olli0103/homeview/issues/4) und die zusätzliche externe [Lizenzfrage #83](https://github.com/Olli0103/homeview/issues/83) sind geschlossen. [MIT-Lizenz](../LICENSE) und [Rechtehinweise](../NOTICE.md) sind veröffentlicht. Insgesamt 76 offene GitHub-Issues. [Vollständiger API-Read-back](verification/issue-readback-block2.json).

Geschlossene Arbeitspakete sind keine pauschal akzeptierten Originalfunktionen. Die 105 Referenzfunktionen behalten ihre getrennten Original-, Funktions- und Geräteabnahmen. Es gibt weitere unbegonnene Softwarearbeit; sie wird nicht als durchweg hardwareblockiert ausgegeben.

## Getrennter Wetter-Folgeschritt

`b08c6f8` korrigiert fehlende Messwerte, Quellen-/Altersanzeige, Einheiten und verspätete
Antworten nach Ortswechsel. 95 Modelltests, drei UI-Fälle je iPad/iPhone und fünf
SDK-Builds bestanden; nach Commit erneut 95 Modelltests. Öffentlicher Open-Meteo-
Abruf durch denselben kompilierten Adapter bestanden. Dies ist **keine** neue
Vollsuite oder Originaloptik-Abnahme. [Wetterdaten und Grenzen](weather-data.md).
#21 bleibt offen; insbesondere ist die eigenständige Original-Wetter-App noch nicht
getreu rekonstruiert.

## Erster visueller Korrekturschritt

`d5514f9` korrigiert die breiten Glasformen, 0/1/9-Stencil-Details und die helle
Farbfläche anhand UI47. 95 Modelltests und fünf gezielte UI-Fälle je iPad/iPhone
sowie fünf SDK-Builds bestanden; nach Commit erneut 95 Modelltests. Die Bewegungs-
prüfungen vergleichen dekodierte Pixel statt PNG-Dateiunterschiede. **#15 bleibt
offen**, kein Original-PASS. [Vergleich und Grenzen](visual-recovery-20261017.md).

## App-Marken und persönlicher Screen

`e169206` ersetzt die sichtbaren Plus-Kreis-Platzhalter und korrigiert die
Standard-Favoriten/Begrüßung nach UI16. 95 Modelltests, ein gezielter UI-Fall je
iPad/iPhone und fünf SDK-Builds bestanden, danach erneut 95 Modelltests. Fotos,
profilabhängige Layouts, weitere Widgets und exakte Icon-Lichtdetails bleiben offen.
[Eigene Bilder und Grenzen](app-icons.md). #9 und #3 bleiben offen.

## Vorrang nach Eigentümerreview

Ziel ist eine möglichst genaue Apple-HomeView-Kopie, keine eigenständige Optik.
Die eigenen bisherigen Flow-Glyphen treffen das Original nicht ausreichend; #15
ist wieder offen. Der Screenshot-Videoentwurf wurde verworfen. Zunächst werden
Ziffernform, Stencil, Glas und Farbfläche gegen UI47 korrigiert, anschließend
Raster/Icons und Wetteransicht. Technische Tests sind keine visuelle Abnahme.

## Historie

Im [ersten Paket](iteration-20261017.md) wurden [BASE-01, #1](https://github.com/Olli0103/homeview/issues/1) und [PHOTO-02, #12](https://github.com/Olli0103/homeview/issues/12) abgeschlossen, der Datenschutz und der eigene Fade-Verlauf weitergebaut. Seine 150 Foto-/Datenschutz-Ausführungen und der separate Fade-Nachweis sind historische, eigene Quellstände und werden nicht als neue aktuelle Tests gezählt.

Apple Home bleibt konstruktionsseitig gesperrt. Kein echtes Gerät wurde geschaltet oder entdeckt. Keine pauschale Original-Parität, physische Sprach-/Kamera-/Energie- oder vollständige Bedienhilfenabnahme.

## Eigenständige Wetter-App nach Original UI20

`7894c76` trennt Wetter-App und Wetter-Zifferblatt: zentrierter Ort, dünne Temperatur
und Conditions-Karte statt wiederverwendeter Uhransicht mit Zusatzheader. Der
bestehende öffentliche Adapter liefert die Stundenfolge. 99 Modelltests, acht
gezielte UI-Fälle je iPad/iPhone und fünf SDK-Builds bestanden; nach Commit erneut
99 Modelltests. Null UI-Fehler/Skips/Runtime-Warnungen. 111 gebundene Quellen, SHA
`1638501683b748096ab6368570f2753ae13c654131188a02315375c45b689762`.
[Eigene Bilder und offene Abweichungen](weather-app.md). Kein neuer Vollsuite-PASS
und kein Original-PASS: Wolken/Glas, Wetterübergänge und weitere Originalzustände
bleiben offen. #21 bleibt offen; keine Smart-Home-Eingriffe.

## Strukturierter Wetterhimmel

`ccbae27` ersetzt unscharfe Wolkenflecken durch ein eigenes begrenztes Volumenfeld
mit Konturen und Licht/Schatten. 99 Modelltests, sieben gezielte UI-Fälle je
iPad/iPhone (14 Ausführungen) und fünf SDK-Builds bestanden; nach Commit erneut
99 Modelltests. Bewegte/reduzierte Himmelsbereiche werden als dekodierte RGBA-Pixel
geprüft, bei Reduce Motion null abweichende Kanäle, bei 0 Prozent Bedeckung kein
weißes Wolkenfeld. [Eigene Bilder und Grenzen](weather-clouds.md). Kein Original-PASS
und keine Schließung von #21; Glasziffern und genaue Wolken-/Lichtphasen bleiben offen.
Quelle 112 Dateien, SHA `c08561dfa25fc967db7a636d556bc7e83f9ef3cf4e19175da547e31e56d36fc1`.

## Durchscheinende Wetter-Glasziffern

`4f3c942` ersetzt die nahezu deckende Temperatur durch eigene Maskennormalen,
Wolkenbrechung und Randreflexe nach UI05. Proportionen/Position und Gradzeichen
sind korrigiert. Nur die gekennzeichnete Referenz-Demo hat AQI 21; verbundene Werte
bleiben unbekannt. 99 Modelltests, sieben gezielte UI-Fälle je iPad/iPhone
(14 Ausführungen), fünf SDK-Builds und erneut 99 Modelltests nach Commit bestanden.
113 gebundene Quellen, SHA `0191c0e171904ac3f6fd74f4d1c51881537a8642563d7806371ef7d594fd4fb9`.
[Eigene Bilder und Grenzen](weather-glass.md). Keine Originalabnahme: genaue Formen,
Licht/Brechung und weitere Zustände bleiben offen. Kein neuer X-Clip.

## Wetterlicht und Glasmaterial

`2e13843` hellt den unteren Tageshimmel und den durchscheinenden Ziffernkörper
nach UI05 auf; die schmalen Randreflexe sind nach Sichtprüfung kalibriert.
Hintergrund und Glas verwenden eine gemeinsame Himmelsfunktion. 99 Modelltests,
neun gezielte UI-Fälle je iPad/iPhone (18 Ausführungen) und fünf SDK-Builds
bestanden; nach dem Codecommit erneut 99 Modelltests. 113 Quellen vor/nach Prüfung
und gegen den Codecommit identisch, SHA
`213fa407a7b42230d7bd131a468c78e2be72b25768fc84b087d7878f0ec50db2`.
[Eigene Bilder, Quellen und Grenzen](weather-light.md). Kein neuer vollständiger
UI-Suite-PASS und keine Originalabnahme: genaue Wolken, gerichtetes Sonnenlicht,
Brechung und physische Leistung bleiben offen. #21 bleibt offen.


## Eigene Foto-Demos und Schutz ohne native Freistellung

`dc5316e`, integriert in `c87e3098`: eigene KI-Demo-Landschaft und fiktives
Porträt statt Rezept-/Plus-Platzhaltern; öffentlicher CPU-Gesichtsschutz für
fehlende native Matte. Tatsächlicher Kopf bleibt frei, Uhr unten; kein erfundener
Tiefeneffekt. Null Gesichter und fehlender Detektor sind getrennte Zustände,
damit Landschaften ohne Alpha nicht unnötig verkleinert werden.

108 Modelltests, 16 gezielte UI-Ausführungen auf iPad/iPhone und fünf SDK-Builds
bestanden. 128 Quellen, SHA
`09e0e4a365f122a977c713ffed03888009ce684c326644da0d66a7f03a6253d2`.
[Eigene Bilder, Fehlerhistorie und Grenzen](demo-photo-assets.md). Native Vision-
Freistellung liefert im Simulator weiter Fehlercode 9; genaue Ursache unbewiesen.
Hohe transparente Original-Fotoziffern, allgemeine Foto-/Albumqualität und Hardware
bleiben offen. Keine echte Fotobibliothek, kein HomeKit und keine neue Vollsuite.


## Durchscheinendes Foto-Uhrmaterial · 18. Oktober 2026

`c3b6676`, Integration `9a26adc8`: laufzeitgerenderte öffentliche Systemglyphen
verwenden denselben Fotohintergrund und dieselbe Ausschnitttransformation wie die
Ansicht. Geglättete Normalen, geringe Brechung und Randlicht ersetzen die deckende
rosa Füllung. Kein gespeicherter OS-Font/-Umriss und kein erfundener Depth-Effekt;
Kopfschutz und bisherige Platzierungsrechtecke bleiben unverändert.

108 Modelltests, 16 gezielte UI-Ausführungen auf iPad/iPhone und fünf SDK-Builds
bestanden, null Fehler/Skips/Runtime-Warnungen. Gleiche festgelegte Pixelgrenzen
auf beiden Größen: Durchsicht mit deckender Positivkontrolle, volle Nachtfläche
ohne fremde Farbkanäle. 128 gebundene Quellen, SHA
`d0dcb95a46ea5da221ca1743309352e58dfdd72221df589c8f74ba0e71f828b5`.
[Eigene Bilder und genaue Grenzen](photo-glass-material.md). Hohe Originalglyphen,
native Freistellung, Originallicht und Hardware bleiben offen. Keine neue Vollsuite.


## Native Foto-Analyse: Diagnosegrenze statt erfundener Freistellung

Neun isolierte Simulator-Konfigurationsausführungen prüfen Bildaufbereitung,
angebotene GPU/CPU und öffentliche Personensegmentierung. CPU-Gesichtserkennung
funktioniert; allgemeine Vordergrundfreistellung bleibtCode9. Balanced-Person
meldet fehlende Ressource/nicht unterstütztes Backend, Fast-Person liefert für
das eigene Demo-Porträt einen tatsächlich leeren Rohpuffer. Kein neuer Renderer-
Fix, keine in main übernommenen Diagnoseänderungen und kein erfolgreicher
Depth-PASS. Host-Instanzerkennung ist ausdrücklich kein kompletter PNG-/App-
Rendernachweis. [Befunde und Grenzen](photo-native-boundary.md). Der zuvor geprüfte
Glas-/Kopfschutzstand bleibt unverändert; keine erneuten unveränderten UI-Tests.
