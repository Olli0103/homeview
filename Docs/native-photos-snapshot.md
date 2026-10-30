# Native Fotoauswahl: begrenzter Snapshot-Schutz

30. Oktober 2026 · #67 bleibt offen, F095 partial/parity=false.

## Ergebnis und offene Grenze

Ein eigener, nicht-key UIKit-Fensterschutz verdeckt die native Fotoauswahl auf App-Szenenebene. Er wird über öffentliche Scene-Lifecycle-Benachrichtigungen angezeigt/entfernt, verändert weder Picker-Präsentation noch Auswahl, Eingabe, Authentifizierung oder Modellzustand. Die bisherigen SwiftUI-Schutzschichten bleiben erhalten. iOS-only; andere Apple-Plattformen erhalten dadurch keine neue Runtime-Abnahme.

**Kein vollständiger Snapshot-PASS:** Die iPhone-Systemtastatur bleibt beim nativen Suchfeld über dem Schutz sichtbar. Der originale Whole-Card-Guard (RGB<20, mindestens 98% schwarz, vollständige tatsächliche HomeView-Karte) bleibt unverändert und dieser Fall wird nicht umgedeutet. Der synthetische Suchtext selbst ist verdeckt; daraus folgt keine Zusicherung für andere Tastatur-/Vorschlagszustände.

**Aktueller eingefrorener Stand: 22 gezielte UI-Ausführungen, 21 PASS / 1 FAIL / 0 Skips.** Die zehn neuen Picker-Ausführungen enthalten neun vollständige Guard-/Rückkehr-PASS und den ausdrücklich fehlgeschlagenen iPhone-Tastaturguard. Zwölf bestehende Ausführungen (sechs Methoden je Gerät) bestehen: Kalender einschließlich echtem Hintergrund/Fresh Unlock, zwei native Fehleralerts/Read-only-Erhalt, Assistenten-Sheets, Setup/Reset ohne Löschen sowie Entwurfserhalt/-löschung.

Schwarzanteil der vollständigen tatsächlichen Karte; ≥98% bleibt erforderlich:

| Zustand | iPhone vorher → aktuell | iPad vorher → aktuell |
|---|---|---|
| Raster | 10,140% → 98,618% · PASS | 3,797% → 99,132% · PASS |
| Echter Home-Hintergrund | 10,081% → 98,618% · PASS | 3,154% → 99,132% · PASS |
| Eine ausstehende Auswahl | 8,814% → 98,618% · PASS | 3,442% → 99,132% · PASS |
| Native Vorschau | 18,439% → 98,618% · PASS | 6,753% → 99,132% · PASS |
| Suchtext + Tastatur | 7,811% → 65,452% · **FAIL / offen** | 3,037% → 99,132% · PASS |

Alle 20 zusätzlichen Regressionkarten erfüllen den gleichen Guard. Insgesamt 29 von 30 aktuellen Karten grün, eine rot; native und unabhängige PIL-Klassifikation stimmen überein. Das ist weder ein 90%-Projektfortschritt noch eine universelle Privacy-Abnahme. Alle zehn Picker-Rückkehr-/Zustandsprüfungen laufen durch; beim roten Guard bleibt der genaue Suchtext samt Tastatur erhalten. Die tatsächlich gesichteten Aufnahmen zeigen den Suchtext nicht in der geschützten Karte, wohl aber die verbliebene iPhone-Tastatur.

**Fünf aktuelle SDKs, 73 paketierte Produktdateien und sechs Tooling-Tests bestanden/zurückgelesen.** 89 Core-/Package-/Modelltestinputs sind bytegleich zum 405-Test-Stand `0c42086b41842877b1720f5776c44d1568ba1931`; kein neuer 405er-Core-Lauf behauptet.

[Quellen, getrennte Laufhistorie und Kartenmessungen](verification/native-photos-snapshot.json) · [Bildherkunft und SHA-256](verification/native-photos-snapshot-images.json).


## Echte System-Präsentation, keine persönliche Bibliothek

Zwei neu erstellte, isolierte Simulatoren: iPhone 18 Pro und iPad Air 11 M4, jeweils iOS 27.0. Genau ein eigener synthetischer 1024×1024-Checkerboard wurde pro Gerät einmal importiert; tatsächliche Sichtbarkeit beider Farben vor jeder Berührung geprüft. Ein frischer Simulator enthält außerdem sechs vorinstallierte OS-Beispielfotos: frisch bedeutet nicht leer. Diese Bilder werden weder ausgewählt noch als eigene Assets veröffentlicht; rohe Picker-/OS-Bilder und Binaries bleiben im privaten Prüfarchiv. Keine bestehende Bibliothek gelesen oder gelöscht, kein Account verbunden, keine reale Home-Instanz und kein Versand/Anruf.

Öffentliche Fixture: [NativePhotosPrivacyCanary.png](../Tests/Fixtures/NativePhotosPrivacyCanary.png), SHA-256 `4065c9efe64a63645f2beb3eaa1960eab1dc75b149f2d4ae9515ed830257fbe0`. Algorithmischer Checkerboard und Text aus eigener Erzeugung, Pillow-Bundled-Font, keine Nutzerfotografie oder extrahierte OS-Fontkonturen; Projekt-Testfixture unter der Repository-Lizenz. Kein mitgeliefertes Produktfoto.

## Eingefrorene Vorher-/Nachherbedingungen

Fünf Zustände je Gerät: unselektiertes Raster; echter Home-Hintergrund; eine noch nicht bestätigte Auswahl; native Long-press-Vorschau; synthetischer Suchtext mit Tastatur. Vorherstand ist der veröffentlichte Produktstand `fa37f6e175c2523f45cf73c9784a2749319c2aa3`; alle 165 Produkt-/Resource-Inputs dort unverändert. Sechs Raster/Home/Auswahl-Belege aus dem erweiterten Testpin, zwei Such-Belege aus dessen qualifiziertem Pin und zwei aktuelle Vorschau-Belege mit derselben finalen Readiness-Prüfung. Separate Baseline-Worktree mit ausschließlich Test-/Fixturekopie; installierte kompilierte Apps jeweils vor/nach Lauf und tatsächliche Runner/Testbundles gegen die jeweiligen eingefrorenen Produkte geprüft. Nicht alle historischen Binaries stammen aus demselben Buildverzeichnis.

Navigation/Kartenidentität bleiben fatal. Nur unabhängige Privacy-Assertions dürfen weiterlaufen, damit Rückkehr, genaue Suchtexte/Tastatur, ausstehende Auswahl sowie bewusster Abbruch ohne Import auch nach einem roten Guard beobachtbar bleiben. Die native transiente Vorschau darf bei Deaktivierung selbst schließen; darunter müssen Picker und Nichtauswahl erhalten bleiben. Das ist keine Aufweichung für Suchentwurf oder ausstehende Auswahl.

## Erhaltene Fehlversuche und Messgrenzen

Erster Präsentationspilot zeigt nur Loading… und gilt ausschließlich für Öffnen/Abbrechen. Zwei falsche Suchfeldannahmen (tatsächlich TextView im photosSearchBar), ein wirkungsloser Vorschau-Tipp im Home-Gutter sowie die unzulässige zusätzliche Cancel-Abfrage unter offener Vorschau sind getrennte Instrumentfehler, keine erfundenen Produktfehler. Die Cancel-/Nichtimportbedingung bleibt nach dem Schließen der Vorschau erforderlich. Frühe unverzügliche iPad-Rückkehraufnahme mit 0 Canary-Pixeln bleibt erhalten; Ursache nicht allein daraus bewiesen.

Die finale Vorschau-Prüfung erhält die unmittelbare Aufnahme und wartet zusätzlich begrenzt auf dieselben unveränderten Canary-Farbschwellen. Öffentlicher App-Foreground-Status allein beweist keine Scene-/Compositorbereitschaft. Zeitangaben beziehen sich auf Beobachtung nach Rückkehr des Card-Tap-API-Aufrufs, nicht auf den exakten Touchzeitpunkt oder eine physische Latenzabnahme. Keine Maskierung/Schwellensenkung am 98%-Privacyguard.

Fester öffentlicher Alert-Level, tatsächliches Maximum öffentlicher eigener Fensterlevel, Variante mit makeKeyAndVisible und vorgesehener Rückkehr zum alten Fenster, öffentliche Responder- und endEditing-Aufrufe beseitigen die iPhone-Tastaturebene in den dokumentierten Versuchen nicht. Die öffentliche Diagnose findet einen ViewController, keinen UITextInput, eigene Fensterlevel 0/10 und erfolgreiche API-Rückgaben ohne geänderten Snapshotbefund. Das ist keine Behauptung, sämtliche öffentlichen Lösungswege seien unmöglich. Wirkungsloser Fokus-/Key-/Diagnosecode ist nicht Teil des gelieferten Produktfixes; keine privaten Fensterklassen, privaten Levelkonstanten oder Secure-TextField-Screenshot-Hacks.

## Quellenbindung, Archive und Paketgrenze

235 aktuelle eingefrorene Quellen, Digest `b1f2b205e9d39e66058bd783eed0978aa1102fb35510da1f9e0f80f0b6e32cd6`. Eine bestehende Produktdatei geändert (Root-Anker), eine neue iOS-only Datei; 164 übrige bestehende Produkt-/Resourceinputs unverändert. Projekt mit dem bestehenden Generator aktualisiert. Der erste Build ohne neue Dateiregistrierung (Digest `12544b710c6bb334145b046828f133e2c24fe1ac1cb1216657d357f811b31425`) scheitert und bleibt erhalten; keine UI-Ausführung daraus. Ein vorher fehlender lokaler Buildhelfer ist ein gesonderter Bootstrap-Exit 2, kein Compiler-/UI-Ergebnis. Stockende neue Simulatorinitialisierung sowie begrenzte Screenshot-/Registrydiagnostik bleiben getrennt; ein Import je Simulator, keine automatische Wiederholung nach unsicherem Acknowledgement.

**27 UI-Eingabearchive mit allen enthaltenen Dateien erneut bytegeprüft**, dazu das SDK-Produktarchiv. Die vier aktuellen UI-Gruppen benutzen 19 identische kompilierte/jeweils vor und nach Installation geprüfte Appdateien und fünf identische Runner-/Testdateien. Die zunächst angenommene 22er-Dateizahl war falsch und wurde beim finalen Archivcheck korrigiert; keine unterschiedliche aktuelle App behauptet. Das vollständige SDK-iOS-Paket enthält 22 Dateien. Dem UI-Testpaket fehlen gegenüber diesem Paket drei SSU/NLU-Dateien (`root.ssu.yaml`, `nlu/nlu.lzfse`, `nlu/*.version`). Diese Paketgrenze wird ausdrücklich mitgeführt: die aktuellen Foto-/UI-Ausführungen sind **kein neuer Kurzbefehle-Runtime- oder vollständiger UI-Paket-Metadatennachweis**. Der frische Standard-SDK-Build besteht die bestehende iOS-Metadatengate; kein Metadata-Schritt deaktiviert.

Historie getrennt: 43 frühere UI-Ausführungen mit 14 PASS / 29 FAIL, daneben 22 aktuelle mit 21 PASS / 1 FAIL. Zusammen 65 Ausführungen sind **keine 65er-Erfolgssuite**. 338 native PNGs dekodiert, 42 Übersichten tatsächlich gesichtet, zwei zusätzliche eigene Vorher-Ausschnitte geprüft. Die zwölf veröffentlichten Bilder sind zehn unveränderte ganze HomeView-Karten (einschließlich des roten Keyboardfalls) und zwei rechteckige Ausschnitte ausschließlich des eigenen synthetischen Canary aus tatsächlichen Vorherkarten. Die Ausschnitte illustrieren den Befund; der Guard wurde auf der unveränderten ganzen Karte berechnet, nicht auf diesen Ausschnitten. Keine Maskierung, Neuskalierung oder Ersatzgeschichte.

Bekannte Konsolendiagnostik (doppelte UIAccessibilityLoaderWebShared-Implementierung, Xcode-Debuggerversion/noURL, alte Remote-AX/kAXErrorServerNotFound) bleibt im privaten Original erhalten. Keine allgemeine Warnungsfreiheit oder bewiesene Produktursache dafür.

## Eigene Belegbilder

| Gerät | Eigener Canary-Ausschnitt der Vorherkarte | Ganze aktuelle Vorschaukarte | Aktuelle Suche/Tastatur |
|---|---|---|---|
| iPhone | [Vorher](verification/images/native-photos-snapshot-20261030/phone-before-owned-canary-only.png) | [Geschützt](verification/images/native-photos-snapshot-20261030/phone-preview-whole-card.png) | [Tastatur ausdrücklich offen](verification/images/native-photos-snapshot-20261030/phone-search-keyboard-OPEN-FAIL-whole-card.png) |
| iPad | [Vorher](verification/images/native-photos-snapshot-20261030/pad-before-owned-canary-only.png) | [Geschützt](verification/images/native-photos-snapshot-20261030/pad-preview-whole-card.png) | [Geschützt](verification/images/native-photos-snapshot-20261030/pad-search-keyboard-whole-card.png) |

## Reproduktion des opt-in Simulatorzweigs

Ausschließlich einen **neu erstellten** Simulator mit Namenspräfix `HomeView Photo Privacy ` verwenden; nie eine bestehende persönliche Bibliothek umbenennen, durchsuchen oder löschen. Die Tests überspringen andere Gerätenamen vor Appstart/Pickeröffnung; die privaten Controller binden zusätzlich Neuanlage, genau einmaligen Fixtureimport und binäre Installation an die jeweilige UUID. Die benannten UI-Ziele erwarten die beobachtete englische OS-Accessibility-Oberfläche.

1. Projekt nach Source-Ergänzungen mit `python3 Scripts/generate_project.py` regenerieren.
2. Frisches iOS 27-Gerät mit `xcrun simctl create` anlegen/booten und die öffentliche Fixture unter `Tests/Fixtures/NativePhotosPrivacyCanary.png` genau einmal mit `simctl addmedia` hinzufügen. CLI-Ack/bootstatus allein beweisen keine sichtbare befüllte Auswahl; die tatsächliche Canary-Prüfung bleibt nötig.
3. Standard-`xcodebuild build-for-testing`, dann `test-without-building` mit der neuen UUID und den fünf `testIsolatedSyntheticNativePhotosPicker…`-Privacy-/Background-Methoden in [HomeViewUITests.swift](../Tests/UITests/HomeViewUITests.swift). Quellen, kompilierte Produkte, Launchkonfiguration und tatsächliche installierte App vor/nach Ausführung binden; originale Fehlläufe aufbewahren. Rohe OS-/Samplefotoaufnahmen privat halten.
4. Den iPhone-Suchfall als derzeitigen FAIL behandeln, nicht überspringen oder den 98%-Guard lockern. Komplette Standard-Bundle-Metadaten separat über `Scripts/build_platforms.py` prüfen; UI-Testpaket nicht mit dessen vollständigem iOS-Paket gleichsetzen.


## Verbleibend

Systemtastaturfall, weitere native Composer/Plattformen, physische Snapshots/Authentifizierung, Präsenz und vollständige Medien-/Unterbrechungsregeln bleiben offen. Keine blanket Original-, System-, Account- oder Hardware-Parity. Die Geräte-/Signing-Pause und Home-Sperre bleiben unverändert. Der Gesamtauftrag wird nach dieser Lieferung fortgesetzt.
