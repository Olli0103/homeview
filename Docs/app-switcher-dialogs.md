# Offene Dialoge vor App-Umschalter-Vorschauen schützen

29. Oktober 2026 · begrenzter Fix zu [#67](https://github.com/Olli0103/homeview/issues/67), Gesamtissue offen. Auf dem zuvor veröffentlichten [Kalender-Nachweis](app-switcher-calendar.md) aufgebaut; dessen grüner RootView-Fall galt ausdrücklich nicht für offene Dialoge.

## Tatsächlicher Vorherfehler

Vier native Vorherausführungen scheitern, bevor Produktcode geändert wird: offener Profil-Editor und offener Wetter-Stadtdialog je iPhone 18 Pro und iPad Air 11-inch (M4), iOS 27 Simulator. Die tatsächliche vollständige HomeView-Karte im SpringBoard-Umschalter zeigt den Dialog weiterhin. Im Stadtdialog ist der selbst eingegebene synthetische Marker `OWNED_PRIVATE_CITY_CANARY` lesbar; auf dem iPhone bleibt auch die Tastatur im Snapshot. Der Profilfall zeigt ausschließlich das mitgelieferte Demo-Profil Alex, keine behauptete echte Haushaltsidentität.

Die Ursache ist konkret: Die vorhandene RootView-Abdeckung liegt **unter** den präsentierten Sheets. Der erfolgreiche normale Kalenderfall war deshalb kein Nachweis für diese Dialoge.

| Vollständige eigene Karte | Vorher: Schwarzanteil | Nachher | Sichtprüfung nachher |
|---|---:|---:|---|
| iPhone, Profil-Editor | 7,35 % | 98,27 % | Schutz statt Profil-/Layouttext |
| iPhone, Stadtentwurf | 7,71 % | 98,23 % | Schutz statt Entwurf und Tastatur |
| iPad, Profil-Editor | 60,08 % | 99,00 % | Schutz statt Profil-/Layouttext |
| iPad, Stadtentwurf | 59,95 % | 99,00 % | Schutz statt Stadtentwurf |

Der 98-%-Guard für RGB unter 20 ist nur eine grobe Gegenprobe. Die tatsächlichen Kartenbilder wurden ebenfalls gesichtet; abgerundete Außenecken, die eigene OS-App-Kennung und feine Dialogkanten werden nicht als private Inhalte oder perfektes Schwarz ausgegeben. Keine OCR-/Timing-/physische Snapshot-Garantie aus diesen Prozenten.

## Begrenzte Korrektur

Nur drei Produktdateien ändern sich:

- `RootView.swift`: die vorhandene deckende Inaktiv-Abdeckung wird als wiederverwendbarer ViewModifier ausgeführt; der Root verwendet denselben Schutz weiter.
- `HomeScreens.swift`: der tatsächlich betroffene Profil-Editor erhält die Abdeckung innerhalb seiner Präsentation.
- `WeatherScreen.swift`: der tatsächlich betroffene Stadtdialog erhält denselben Schutz. Sein eigener FocusState wird bei Inaktivität gelöst, damit die Tastatur den Schutz nicht überlagert. Der Entwurf wird dabei nicht gelöscht.

Keine neue Authentifizierungs-/Sitzungssperre bei bloßer Inaktivität. Keine Provider-, Persistenz-, Berechtigungs- oder Medienänderung. Die App-Umschalter-Tests kehren durch Berührung der tatsächlichen OS-Karte zurück: beide Dialoge bleiben bedienbar, der Stadtentwurf bleibt erhalten und „Done“ ändert die angezeigte Stadt Berlin nicht. Der neue Stadtfall drückt **nicht** „Update weather“ und löst keine reale Geocodierung aus. Die getrennte vorhandene Dialogregression betätigt Update ausschließlich mit dem synthetischen Fixture-Provider.

## Finale Abnahme an einem Quellenstand

**Zwölf erfolgreiche UI-Ausführungen, sechs eindeutige Methoden je zwei Simulatoren**, null Skips und null strukturierte Runtimewarnungen:

- Die vier zuvor fehlgeschlagenen Dialogausführungen bestehen ohne Teständerung.
- Vier Kalenderausführungen prüfen tatsächlichen OS-Umschalter, echte Home-Hintergrundsperre und frische Entsperrung nach der gemeinsamen Schutz-Refaktorierung.
- Zwei Stadtdialog-Ausführungen prüfen tatsächliche obere/untere Ränder, Einheiten, Fixture-Update, Eingabe, Tastatur-Sichtbarkeit und Done ohne implizites Update.
- Zwei Profil-Ausführungen prüfen Layoutspeicherung, Neustart und unverändertes anderes Demo-Profil.

Fünf arm64-SDK-Builds bestehen: iOS, macOS, tvOS, visionOS und watchOS. Das sind Kompilierungen, keine neue Laufzeitabnahme der vier übrigen Plattformen. Keine neuen Coretests: Core-/Package-/Core-Testdateien bleiben unverändert; frühere Core-Ergebnisse werden nicht in diesen Lauf übernommen.

225 Quellen vor/nach allen Ausführungen und vor Veröffentlichung geprüft. Kandidat und Regressionen verwenden exakt dieselben kompilierten App-/Test-/Launch-Eingaben. Sechs ausgeführte Archive einschließlich der beiden roten Vorherläufe vollständig zurückgelesen; installierte Appbytes je Lauf geprüft. Beim reinen Vorher-Testneubau war nur `Assets.car` gegenüber dem Kalenderstand anders, während 18 von 19 Produktdateien einschließlich Appcode bytegleich blieben. Diese konkrete Variation wird erhalten, nicht als vollständige 19-Datei-Gleichheit ausgegeben.

88 Core-/Package-/Core-Testeingaben bleiben bytegleich; 73 tatsächliche SDK-Produktdateien sind gesondert archiviert und vollständig zurückgelesen. Die aktuelle Assetprüfung verlangte nach der Änderung von HomeScreens einen neuen Ganzdatei-Quellhash. Der enthaltene Cover-Renderer blieb exakt unverändert; nur dieser Provenienz-Quellhash wurde [belegt aktualisiert](verification/asset-provenance-source-refresh-snapshot-dialogs.json). Alle 58 Ressourcen und 17 Provenienzeingaben bestehen die Prüfung, kein neuer historischer Rechteentscheid.

56 PNGs über Vorher-/Nachher-/Regressionsläufe dekodiert; acht Übersichten und vier Einzelbilder tatsächlich gesichtet, darunter beide vollständigen geschützten Stadtdialog-Karten und beide nativen fokussierten Stadtdialoge. Zwölf eigene synthetische Appbilder gespeichert und zurückgelesen; rohe OS-Umschalterbilder mit fremden App-Karten/Bäumen bleiben privat.

Finaler Quelldigest: `f75a2984df9d9be72115cbb84b4c30eed497ca3294d0a4ea082f6da873316cb7`.
Finales UI-Eingabearchiv: `8f00eb9cb5b4d72b73a74cc5fbf23278b91643e827f5b3d196b42a4344ec3b36`.

[Getrennte Messungen/Läufe/Bilder](verification/app-switcher-dialogs.json) · [zwei ausgeführte Quellenvarianten](verification/app-switcher-dialogs-source.json) · [SDK-/Produktarchive](verification/app-switcher-dialogs-platforms.json) · [eigene synthetische Appbilder](screenshots/app-switcher-dialogs).

## Offene Grenzen

Anschließend separat geprüft und korrigiert: [Tastaturen auf normaler Assistenten-/Reminder-Route](app-switcher-keyboard.md). Deren Quellen und zehn UI-Ausführungen sind nicht Teil der hier dokumentierten Zwölferprüfung.

**#67 bleibt OPEN, F095 partial/parity=false.** Zwei App-Dialoge und der Kalender sind damit geprüft, nicht jede Präsentation. Andere App-Dialoge und der native Messages-Composer sind gesondert offen; keine Nachricht oder Verbindung wird automatisch ausgelöst. Physische Snapshots/Authentifizierung, echte Präsenz, sämtliche Unterbrechungs-/Medienregeln und Original-Parity bleiben unbelegt. Geräte-/Signing-Abnahmen bleiben auf Eigentümerwunsch pausiert; keine Home-Anbindung, persönlichen Konten, Systemalarme oder Live-Medien.
