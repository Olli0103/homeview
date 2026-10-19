# Optionale Apple-On-Device-Antworten

19. Oktober 2026 · [AI-01, #33](https://github.com/Olli0103/homeview/issues/33).

## Zwei ausdrücklich getrennte Modi

Der Assistent startet weiterhin mit **Local commands**. Unter **Capabilities and limits → Use Apple on-device answers** kann der Benutzer den Antwortmodus bewusst wählen. Das Öffnen der Information oder die Auswahl sendet keinen Entwurf. Verfügbarkeit wird erst bei Auswahl und vor dem Senden geprüft. Ohne bereitstehendes Modell bleibt ein nicht abgesendeter Entwurf erhalten; keine automatische Wiederholung oder Cloud-Ausweichroute.

Der native Adapter verwendet ausschließlich den konkreten öffentlichen `SystemLanguageModel(useCase: .general, guardrails: .default)` mit `LanguageModelSession` und leerer Toolliste. Apples [aktuelle API-Dokumentation](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel), am 19. Oktober direkt gelesen, bezeichnet ihn ausdrücklich als On-Device-Modell. Das vorhandene OS-Framework wurde statt eines eigenen Inferenzservers ausgewählt. Kein API-Schlüssel, Gateway-Zugang, bezahlter Anbieter, Cloudkontingent oder Abo wird vorausgesetzt. Der getrennte Private-Cloud-Compute-Modelltyp wird nicht verwendet. HomeView aktiviert Apple Intelligence nicht selbst und fordert keinen Modelldownload an.

Im **Antwortmodus** gehen ausschließlich ausdrücklich abgesendete Fragen und der temporäre Gesprächsverlauf an das lokale Modell. Keine Kalender, Fotos, Profile, Rezeptbestände oder sonstigen App-Daten werden automatisch angehängt. Kein Befehlsparser wird nachgeschaltet: Selbst „Set a timer for 5 minutes“ erzeugt hier nur Text, keinen Timer, keine Musikaktion und kein Mock-Home-Kommando. Es gibt keine registrierten Tools, Websuche, Live-Messwerte oder Quellenrecherche. Antworten sind weder Siri noch überprüfte Auskünfte und können falsch oder veraltet sein.

Im **Befehlsmodus** bleiben die vorhandenen ausdrücklich begrenzten Aktionen verfügbar. Der bisherige Schlüsselwortparser interpretierte zehn beschreibende/negierte/mehrteilige Eingaben als Aktionen, etwa „Who invented the light bulb?“ oder „What is the temperature of the Sun at 6000 degrees?“. Dieser Fehler ist mit einem gezielten roten Test erhalten; die Korrektur verwendet vollständige begrenzte Formulierungen. Timer-/Kochschrittdauern bleiben separat validiert. Apple Home bleibt deaktiviert; vorhandene Home-Kommandos betreffen nur MockHome.

## Verlauf, Abbruch und Grenzen

Maximal vier Frage-/Antwort-Paare, insgesamt 6000 Zeichen, 1000 pro Frage und 4000 pro Antwort; bis zu 400 generierte Tokens und 45 Sekunden pro Anfrage. Das Systemkontextfenster kann früher voll sein. Dann wird ein fester Fehler angezeigt und die komplette Sitzung verworfen, nicht still gekürzt, automatisch erneut gesendet oder an einen Server geleitet.

**Stop**, **New**, Verlassen des Assistenten, Hintergrund, Sperre und Profilwechsel verwerfen sichtbaren Verlauf und die native `LanguageModelSession`. HomeView speichert Gespräche nicht im Snapshot oder in einer Gesprächsdatei. Generationen verhindern, dass ein später Erfolg oder Fehler eines alten Auftrags einen neuen Verlauf verändert. Neben dem Timeout-Task wird vor Übernahme einer Antwort die absolute monotone Deadline geprüft. Abbruch bedeutet kein Versprechen, dass jede interne OS-Berechnung augenblicklich beendet ist; spätes Ergebnis wird jedenfalls nicht übernommen. Die Oberfläche scrollt längere Antworten und trennt synthetische UI-Fixtures von echten Modellaussagen.

Der native Pfad benötigt unterstützte iOS-/macOS-/visionOS-26+-Geräte mit verfügbarem Apple-Intelligence-Modell. Auf älteren oder anderen Plattformen wird Nichtverfügbarkeit angezeigt; die Watch bleibt bei lokalen Befehlen. Keine Zusage, dass jedes iPad oder jeder Simulator das Modell ausführen kann.

## Tatsächliche Prüfung

- **214 Modelltests**, darunter 14 neue Gesprächs-/Abbruch-/Kontexttests und zwei Befehlsgrenztests. Der gezielte Parser-Vorherlauf hatte zehn fehlgeschlagene Assertions in einem von zwei Fällen; Quellenhash und vorheriger Code bleiben erhalten.
- **Acht zusätzliche externe Prüfungen** kompilieren den Produktions-Gesprächskern mit einem getrennten kontrollierten Provider: keine Auswahl/ungültige Eingabe/nicht verfügbar/vorab abgebrochen → kein Provideraufruf; alter Erfolg/Fehler → kein Überschreiben; blockierter Timer-Callback → Deadline gilt trotzdem; freigegebener Kontext nach spätem Backendabschluss. Das ist keine globale OS-Netzwerk-/Prozessüberwachung.
- **Echter nativer Lauf auf macOS 27.0.1, AFM 3 Core** mit demselben Produktionsadapter und Gesprächskern: elf synthetische Fragen/Nachfragen in drei getrennten Sitzungen. Neun erfüllen die festgehaltenen Kriterien vollständig; zwei Unbekannt-/Quellenantworten sind vage und bleiben **PARTIAL**, nicht nachträglich PASS. Keine erfundenen persönlichen Daten oder Literaturstellen in diesem kleinen Set. Vier Fakten wurden gegen direkt gelesene NASA-Seiten geprüft; fiktiver Comet-/Leipzig-Kontext und deutscher Folgebezug stimmen. [Alle tatsächlichen Antworten und Einzelfallbewertung](verification/assistant-local-native-qa.json).
- **16 native Simulator-Ausführungen** über zwei quellengebundene Checkpoints: zunächst fünf Methoden je iPad/iPhone, danach drei betroffene/Regressionsmethoden je Gerät. Sieben unterschiedliche Methoden insgesamt. Auswahl ohne Senden, zwei Antworten, keine Timeraktion, Nichtverfügbarkeit samt Entwurfserhalt, Fehler, Stop, Hintergrundreset sowie vorhandener Sprachentwurf/Send-Zwang und lokale Thermostataktion. Dies ist keine aktuelle vollständige UI-Suite und kein physischer Modelltest.
- **Fünf arm64-SDK-Builds** bestanden. Der spätere Unterschied betrifft nur den Screenshotaufruf im UI-Test, nicht den Produktcode. Projektgenerator separat auf exakten Quellen ausgeführt: Projekt/Plist byteidentisch; Python-Syntax geprüft. Keine passende Python-/Node-/POSIX-/Linux-Testsuite in dieser Swift-Änderung.
- Je Checkpoint 23 Eingaben vor/nach identisch und installierte Simulator-Appbytes zurückgelesen. Der erste kompilierte Test-Runner wurde vor einer zusätzlichen Archivkopie durch den Folge-Build ersetzt; seine terminalen Hashprüfungen bleiben erhalten, kein altes Binärarchiv wird behauptet. Das letzte Archiv enthält alle 168 Quellen und 23 kompilierten Eingaben; alle 191 Einträge vollständig zurückgelesen. Der echte native QA-Lauf hat ein eigenes vollständig zurückgelesenes Zehn-Dateien-Archiv.
- 40 eigene PNGs dekodiert, 26 Zustände auf sechs Kontaktbögen gesichtet; zwölf Bilder veröffentlicht. Die erste Telefon-Anbieterauswahl war fälschlich auf den darunterliegenden App-Viewport beschnitten. Der Folgefall liefert den vollständigen nativen Dialog. Alte beschnittene Bilder bleiben historisch, nicht saubere Abschlussnachweise. Einige volle Bilder enthalten die Systemtastatur.

[Quellenbindung und Prüfergebnisse](verification/assistant-local.json) · [separater Gate-Bericht](verification/assistant-local-release-gate.json) · [echter QA-Harness](verification/assistant-local-native-qa.swift).

Das ist eine vorhandene lokale Antwortfunktion mit ausdrücklich begrenztem Kontext, **keine** Garantie allgemeiner Faktenrichtigkeit, Original-Siri-Parität, physischer iPad-Latenz, Flugmodusfähigkeit oder Energieeffizienz. Die beiden vagen Antworten, native Modellfehler und Geräteabhängigkeit werden nicht versteckt.

## Nachfolgende manuelle Sprachausgabe

Die separat wählbare [Antwortstimme](answer-readout.md) wurde anschließend ergänzt. Sie liest nur die letzte fertige Antwort nach Geräteauthentifizierung und zusätzlichem ausdrücklichem Read; keine automatische Ausgabe oder Weitergabe an einen anderen LLM. Die oben dokumentierten Modellantworten und ihre zwei PARTIAL-Ergebnisse bleiben unverändert.
