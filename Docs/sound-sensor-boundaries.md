# Alarmgeräusche und Raumsensoren: Machbarkeitsentscheidung

20. Oktober 2026 · [#32 / HOME-07](https://github.com/Olli0103/homeview/issues/32) · [Quellen und Prüfumfang](verification/sound-sensor-boundaries.json)

**Recherche abgeschlossen. F039 und F040 bleiben blockiert, parity=false.** HomeView erhält weder eine Schutzfunktion noch neue Messwerte. Die Home-Anbindung bleibt ausdrücklich aus. Das abgeschlossene Recherchepaket ist nicht die Abnahme der ursprünglichen Hardware-/Systemfunktionen.

## Entscheidung je Funktion

| Funktion | Belegter vorhandener Weg | Entscheidung für HomeView |
| --- | --- | --- |
| F039: Rauch-/CO-Alarmgeräusche erkennen und melden | Apple dokumentiert Sound Recognition auf HomePod mini und HomePod (2. Generation). Home benachrichtigt iPhone, iPad oder Apple Watch; ein bewusstes Check-in ist möglich. | Kein belegter App-Lesepfad für die HomePod-Erkennung in den hier gelesenen Verträgen. Nicht implementiert, keine Schutzbehauptung und kein Alarmtest. |
| Eigene Audio-Klassifikation als mögliche Alternative | SoundAnalysis kann selbst bereitgestellte Audiodateien/-streams mit Apples Modell oder einem eigenen Core-ML-Modell klassifizieren. | Technisch eigener App-Ansatz, **nicht** HomePods Erkennung. Nicht ausgewählt oder gebaut. Keine Modell-/Klassenabfrage, Aufnahme, Erkennungsquote, Hintergrund- oder Alarmzustellung geprüft. |
| F040: eigene Temperatur-/Feuchtesensoren für Automationen | HomePod mini/2 besitzen physische Sensoren. HomeKit kennt passende Messwert-Characteristics von Zubehör. | Für das HomeView-Zielgerät sind weder entsprechende eigene Raumfühler noch eine verifizierte externe Messkette nachgewiesen. Keine Messung oder Automation. Hardwarefunktion bleibt blockiert. |

## F039: Alarmton ist nicht Rauch oder CO

Die vollständige [HomePod-Anleitung](https://support.apple.com/guide/homepod/apd1f1921722/homepod) beschreibt ausdrücklich das **Geräusch eines vorhandenen Rauch- oder CO-Melders**, keine Rauchpartikel- oder Gaskonzentrationsmessung durch HomePod. Die Benachrichtigung zeigt CRITICAL und den erkennenden HomePod. Beim bewussten Öffnen kündigt HomePod das Check-in an; Talk ist möglich. Eine HomeKit-Kamera im selben Raum liefert optional ein Bild, ist in dieser Anleitung aber keine Voraussetzung für die Geräuscherkennung.

Die [HomePod-mini-Spezifikation](https://support.apple.com/en-us/111914) und die [HomePod-2-Spezifikation](https://support.apple.com/en-us/111843) nennen diese Funktion positiv. Apple verlangt die aktualisierte Home-Architektur und aktuelle Software auf den auf das Zuhause zugreifenden Apple-Geräten. Die konkrete Geräte-, OS-, Account- und Home-Eignung des Nutzers wurde nicht untersucht; die produktseitigen Einführungsjahre sind keine Software-Mindestversion für diese Funktion.

Apple sagt selbst, dass die Erkennung Geräusche erkennen **kann** und nicht in Situationen als verlässlich vorausgesetzt werden soll, in denen Verletzungen drohen, oder in Hochrisiko-/Notfallsituationen. Hier wird daher weder eine Sicherheitszertifizierung noch verlässliche Alarmierung, Erkennung jedes Melders, Abwesenheitsüberwachung oder Ersatz eines Rauch-/CO-Melders behauptet.

### Öffentliche App-Schnittstellen sauber getrennt

- [SNClassifySoundRequest](https://developer.apple.com/documentation/soundanalysis/snclassifysoundrequest) verarbeitet ein SoundAnalysis- oder eigenes Core-ML-Modell. [SNAudioStreamAnalyzer](https://developer.apple.com/documentation/soundanalysis/snaudiostreamanalyzer) analysiert vom App-Code bereitgestellte Audiodaten. Die dokumentierte Möglichkeit ist real; eine pauschale Behauptung „Drittanbieter können keine Geräusche klassifizieren“ wäre falsch.
- [knownClassifications](https://developer.apple.com/documentation/soundanalysis/snclassifysoundrequest/knownclassifications) liefert die Labels **des jeweiligen Modells**. Die Eigenschaft beweist allein weder eine bestimmte Rauch-/CO-Klasse auf einem bestimmten Gerät noch zuverlässige akustische Abdeckung, Konfidenzschwellen, Alarmzustellung bei App-Suspension oder Sicherheitszulassung. Hier wurde kein Request/Analyzer erzeugt und kein Modell ausgeführt.
- [HMCharacteristicTypeSmokeDetected](https://developer.apple.com/documentation/homekit/hmcharacteristictypesmokedetected) und [HMCharacteristicTypeCarbonMonoxideDetected](https://developer.apple.com/documentation/homekit/hmcharacteristictypecarbonmonoxidedetected) sind positive öffentliche Zubehör-Statusverträge. Ein Status eines tatsächlich eingebundenen Melders ist nicht automatisch ein abrufbares HomePod-Alarmton-Ergebnis. Keine solche Zuordnung oder tatsächliche Zubehörfähigkeit wird hier angenommen.
- HomeKit-Entitlement, Zweckbeschreibung und Nutzerfreigabe wären getrennt nötig; die [öffentliche HomeKit-Einrichtungsanleitung](https://developer.apple.com/documentation/homekit/enabling-homekit-in-your-app) ist kein Anlass, den gesperrten Home-Manager „nur zum Prüfen“ zu erzeugen.

Die vorhandenen Apple-Systemfunktionen und das öffentliche SoundAnalysis sind die vorhandenen Lösungen dieses Rechercheumfangs. Ein eigener Daueraufnahme-/ML-/Benachrichtigungsdienst wäre ein neuer Produktumfang, kein stillschweigender Ersatz. Keine Installation, neue Bibliothek, Ausgabe oder Systemkonfiguration wurde veranlasst. Aus den begrenzt gelesenen Verträgen folgt kein universeller Nicht-Existenzbeweis für anders benannte oder zukünftige APIs.

## F040: Hardware und Herkunft des Wertes

Die [vollständige HomePod-Anleitung zur Raumtemperatur/-feuchte](https://support.apple.com/guide/homepod/apd8085c1032/homepod) nennt HomePod mini und HomePod (2. Generation) ausdrücklich. Die Sensoren sind für Innenräume um 15–30 °C und 30–70 % relative Feuchte optimiert. Das sind Optimierungsbereiche, **keine** behauptete Genauigkeit oder Garantie außerhalb/innerhalb eines Bereichs. Längere laute Audiowiedergabe kann die Genauigkeit beeinträchtigen; nach dem Start benötigen die Sensoren Kalibrierzeit. Apples separate Betriebsbedingungen 0–35 °C bzw. 5–90 % sind nicht mit Messgenauigkeit gleichgesetzt.

[HMCharacteristicTypeCurrentTemperature](https://developer.apple.com/documentation/homekit/hmcharacteristictypecurrenttemperature) bezeichnet die vom **Zubehör** gemessene Temperatur in Celsius. [HMCharacteristicTypeCurrentRelativeHumidity](https://developer.apple.com/documentation/homekit/hmcharacteristictypecurrentrelativehumidity) bezeichnet dessen relative Feuchte in Prozent. Die Konstanten sind kein eingebauter Raumfühler des iPad und kein Nachweis, dass gerade ein bestimmter HomePod diese Werte einer Drittanbieter-App bereitstellt. Später wäre eine konkrete Messkette mit Hardwareidentität, Service-/Characteristic-Zuordnung, Leserechten, Einheit, Messzeit, Aktualität/Offlineverhalten und Fehlerzustand zu belegen. Es wurden keine Geräte gesucht oder Werte gelesen.

[ProcessInfo.thermalState](https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.property) ist ein qualitativer Wärme-/Lastzustand des Systems zur Ressourcensteuerung, keine Raumtemperatur in Grad und kein Feuchtesensor. Wetterdaten, Thermostat-Sollwerte, ein CPU-Wärmezustand oder Gesundheitsdaten werden nicht als Raumfühler umgedeutet. HomeViews MockHome startet mit 68 und verändert diesen Demowert über Mock-Befehle; die feste 30%-Anzeige in HomeScreens ist ebenfalls kein nachgewiesener Sensorwert. Keine dieser bestehenden Darstellungen wird hier als Messung abgenommen.

Ein kompatibler externer Sensor mit nachgewiesenem öffentlichen Protokoll wäre eine andere Hardware-/Integrationsentscheidung. Er wird nicht gekauft, installiert, verbunden oder stellvertretend akzeptiert. Unter der fortbestehenden Home-Sperre wird keine Automation mit realen Sensoren eingerichtet.

## Plattformmatrix: Deklaration ist kein Geräte-PASS

Gezielt gelesen wurden ausschließlich öffentliche Header aus fünf installierten SDKs; keine Binäranalyse und kein Framework wurde instanziiert. DocC und die Header stimmen für die betrachteten Vertragsrollen überein.

| Ziel | Öffentliche Deklaration | Tatsächlicher HomeView-Stand |
| --- | --- | --- |
| iOS/iPadOS | SoundAnalysis-Request ab iOS 13; Apple-Klassifizierer/knownClassifications ab iOS 15. HomeKit-Zubehör-Characteristics vorhanden. | F039/F040 blockiert; kein Mikrofon-/Home-/Hardwarelauf. |
| natives macOS | SoundAnalysis-Request ab macOS 10.15, Modell-/Labelweg ab 12. Die gelesenen HomeKit-Characteristics sind ausdrücklich API_UNAVAILABLE(macos). Catalyst ist separat ab 14 deklariert. | Keine eigene Erkennung oder Raummessung; Apples Mac-Home-App wird dadurch nicht als unfähig bezeichnet. |
| watchOS | Request ab 6, Modell-/Labelweg ab 8; Zubehör-Characteristics in öffentlichem Header vorhanden. | Keine Watch-Sensor-/Alarmabnahme. Benachrichtigung des HomePod-Systemwegs ist kein eigener Detector. |
| tvOS | Request ab 13, Modell-/Labelweg ab 15; Zubehör-Characteristics im SDK vorhanden. | Keine Zusage eines App-Mikrofons, dauerhaften Detektors, Raumfühlers oder zugestellten Alarms. |
| visionOS | SoundAnalysis ab 1 und relevante HomeKit-DocC-Verträge vorhanden. | Kein Gerätesensor-/Home-/Hintergrundnachweis; F039/F040 blockiert. |

Das Vorhandensein einer API-Deklaration beweist weder passende physische Sensoren/Mikrofone noch Konto-, Hardware-, Dauerbetrieb- oder Zustellrechte. Die Matrix ist eine dokumentierte Machbarkeitsentscheidung, keine Funktionsfreischaltung.

## Abschluss und weiterhin offene Nachweise

Das ursprüngliche Recherche-Akzeptanzkriterium – Entscheidung pro Funktion, keine erfundenen Messwerte oder Sicherheitsversprechen – ist erfüllt. Alle ursprünglichen F039/F040-Funktions-, Geräte-/Service- und Originalkriterien bleiben unverändert unerfüllt. [#23](https://github.com/Olli0103/homeview/issues/23) bleibt offen; keine Home-Anbindung.

Alle 206 Produkt-, Test-, Ressourcen-, Projekt- und Scriptdateien sind bytegleich zum Ausgangsstand 7200318. Keine neuen Builds, UI-/Modelltests, Bilder oder Hardwareergebnisse werden beansprucht. Keine Audioaufnahme/-wiedergabe, SoundAnalysis-Instanz, Sensorabfrage, Berechtigungsabfrage, kritische Benachrichtigung, Änderung von System-/Home-Einstellungen oder echte Sicherheitsaktion wurde ausgeführt.
