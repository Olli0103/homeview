# TV-VoiceOver: erreichbare Überschrift und echte Remote-Aktion

30. Oktober 2026 · #73 bleibt offen, F103 partial/parity=false.

## Begrenztes Ergebnis

App-Überschriften werden auf tvOS **nur bei tatsächlich aktiviertem VoiceOver**
über den öffentlichen SwiftUI-Umgebungswert fokussierbar. Sie erhalten eine
Heading-Rolle und stabile Kennung; der zusätzliche normale Fokuseffekt bleibt
aus. Ohne VoiceOver bleibt die bisherige passive Überschrift erhalten. Andere
Plattformen behalten ihre bisherigen Modifier. Keine private API oder Änderung
an Kamera-, Mikrofon-, Konto-, Home- oder Authentifizierungszugriffen.

Der neue native Kamera-Fall liest über tatsächlichen Remote-Fokus und gemeldete
VoiceOver-Sprache: Cameras, Front Door, Back Yard, Living Room, Driveway und
Show 9. Erst nach bewiesenem Fokus und passender Sprache aktiviert Select den
Rasterwechsel. Danach sind neun Demo-Kameras und Show 4 vorhanden; auch Show 4
wird nativ gemeldet. Die ursprüngliche ausgeschaltete VoiceOver-Einstellung
wird wiederhergestellt und zurückgelesen. Ergebnisanhang und unabhängig im
eigenen Runner gespeicherter Bericht sind bytegleich.

| Abnahme | Ergebnis |
|---|---|
| Aktueller TV-Lauf | 9/9, keine Skips/strukturierten Runtimewarnungen |
| Separate mobile Kontrollen | 2/2, keine Skips/strukturierten Runtimewarnungen |
| Standard-SDK-Builds | 5/5, alle 77 Produktdateien zurückgelesen |
| Ganze TV-Kamera- und Matched-Close-Ruheaufnahme | je 1920×1080, RGBA- und PNG-bytegleich zum bisherigen Stand |
| Geometrie | alle fünf bisherigen TV-Rechtecke exakt |
| Ganze mobile Viewports | iPhone 1134² und iPad 1592², RGBA-/PNG-bytegleich |

Keine nachträgliche Maskierung oder RGB-Toleranz. Der TV-Lauf umfasst außerdem
Browser/Menu, Kamera/Mock-Talkback, eigene Fotogalerie, zwei Medienfälle und
beide normalen Timer-Regressionen. SDK-Erfolg ist keine native Abnahme aller
Plattformen. 96 Core-/Package-/Modelltestinputs sind exakt zum gebundenen
458-Test-Ergebnis; kein neuer Core-Lauf behauptet.

## Erhaltene Fehler und sauber getrennte Eingabewege

Zehn vorherige explorative Ausführungen: zwei PASS, acht FAIL. Diese werden
nicht zu einer erfolgreichen Gesamtsuite umetikettiert.

- Die erste VoiceOver-Aktivierung öffnet den tatsächlichen PineBoard-Hinweis
  „VoiceOver Navigation Updates“. Nur dessen beobachteter fokussierter OK-Button
  wird bestätigt; Kamerawerte werden nicht gegen den Systemdialog geprüft.
- Der gewöhnliche Fixturehelfer setzt `continueAfterFailure=false`. Dadurch
  übersprang die erste fatale XCTest-Assertion die Swift-Rückstellung. Die
  unabhängige Kontrolle fand VoiceOver noch an und stellte das ursprüngliche
  Aus wieder her; diese Kontrolle bleibt selbst FAIL. Der gelieferte Helfer
  aktiviert vor jeder OS-Mutation wieder cleanup-sichere Assertions und schreibt
  einen unabhängigen Abschlussbericht. Alle aktuellen Rückstellungen belegt.
- `moveForward` erreicht im begrenzten Vergleich auch einen zweiten normalen
  UIKit-TV-Button nicht. Dagegen bestätigen echte Remote-Richtungen Fokus,
  passenden Sprachwert und den richtigen Callback. Zusätzlich melden nativer
  Service **und der unabhängige UIKit-Appgetter** laufendes VoiceOver. Der
  gesamte Kalibrierungstest bleibt wegen seiner API-Bedingung FAIL; der getrennt
  bewiesene Remote-Callback ist kein API-Traversal-PASS oder akustischer Test.
- Ein transparenter Test-Messanker beeinflusst die gemeldete Lesefolge. Sein
  probeweises Entfernen liefert nur den Kameratitel, nicht alle Controls. Der
  Messanker-Schalter wird nicht ausgeliefert. Der aktuelle Fall verwendet wieder
  den unveränderten Anker und eine tatsächlich fokussierbare Überschrift.
- **Timer weiterhin offen:** Nach Resume heißt das fokussierte Control in AX
  Pause timer, der Sprachreport liefert jedoch MOCK HOME statt Pause timer.
  Eine lokale tvOS-Fokusbindung beseitigt dies nicht und ist vollständig entfernt.
  Normale Timeraktionen bleiben grün. Ursache und akustisches Verhalten daraus
  nicht behauptet; kein Timer-VoiceOver-PASS.

Explorative/fremdappabhängige und nicht bestandene Fälle bleiben außerhalb des
normalen Regressionstargets im gebundenen privaten Archiv. Keine verkürzten
Produkttexte, erwarteten Fehler oder gelockerten ursprünglichen Kamerawerte.

## Quellen, Bilder und offene Grenzen

Code [d8f7cfb](https://github.com/Olli0103/homeview/commit/d8f7cfb0024881b7cf910cefe8a094ad622b1bad),
253 eingefrorene Quellen; ursprüngliche übrige TV-Testmethoden bytegleich.
Alle historischen/aktuellen Source- und Binäreingaben aus gemeinsamen Archiven
und minimalen Deltas rekonstruiert. 1.394 private Dateien/243.351.437 Bytes
versiegelt und zurückgelesen. 104 UI-/Filmframe-PNGs dekodiert; neun TV-, eine
mobile und eine ergänzende Filmübersicht tatsächlich gesichtet. Eigene native
Vollbilder zusätzlich geprüft. OS-Hinweise/-Bäume und Apple-Referenzen privat.

[Ergebnisse und Hashes](verification/tv-voiceover-remote-20261030.json) ·
[Sourcepin](verification/tv-voiceover-remote-source-20261030.json) ·
[Frischer vollständiger Backlogabgleich](verification/backlog-reconciliation-after-tv-voiceover-20261030.json).

[Native Überschrift](verification/tv-voiceover-images/tv-native-heading.png) ·
[Native Rasteraktion](verification/tv-voiceover-images/tv-native-camera-action.png).

Keine vollständige Lesereihenfolge, lange Kartenlektüre, Timer-/übrige zentrale
Flows, Voice Control, Switch Control, AssistiveTouch, akustische, Original- oder
physische Abnahme. Ursprüngliche Issuekriterien unverändert. Home-/Geräte-/Signing-
Pause bleibt bestehen; Gesamtauftrag läuft mit nächster unabhängiger Arbeit weiter.
