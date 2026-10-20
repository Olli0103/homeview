# HKSV: Home-Benutzerfunktion ist nicht automatisch App-Schnittstelle

20. Oktober 2026 · [#30 / HOME-05](https://github.com/Olli0103/homeview/issues/30) · [Quellen-/SDK-/Codebericht](verification/hksv-public-boundaries.json)

**Recherche abgeschlossen; F036 und F037 bleiben blockiert, parity=false.** Es wurde kein HKSV-Zugriff implementiert oder getestet. Die ursprüngliche Abnahme dieses Recherchepakets verlangt einen Fähigkeitsbericht mit konkreten Links und Testgrenzen, keinen erfundenen HKSV-PASS. Die weiterhin gesperrte Home-Anbindung [#23](https://github.com/Olli0103/homeview/issues/23) wird dadurch nicht fortgesetzt.

## Positive Systemfähigkeiten und konkrete App-Lücken

| Unterfunktion | Öffentlich belegter Apple-Home-Bedienweg | Grenze für HomeView |
| --- | --- | --- |
| Personen, Tiere, Fahrzeuge, Pakete erkennen | [Apple beschreibt](https://support.apple.com/guide/iphone/set-up-security-cameras-iph7bc5df9d9/ios) HKSV-spezifische Aktivitätsmeldungen und Timeline-Symbole für diese vier Kategorien. Ein Paket muss nach der Lieferung im Bild liegen. | In den hier geprüften öffentlichen Kamera-Verträgen ist kein Abruf dieser HKSV-Klassifikation oder entsprechender Clip-Ergebnisse belegt. Ein gewöhnlicher MotionDetected-Wert ist nicht dasselbe. F036 unerfüllt. |
| Bekannte Gesichter und Namen | [Home erkennt](https://support.apple.com/guide/iphone/use-face-recognition-iph04af43727/ios) Personen aus Photos **oder** aus benannten jüngsten Home-Kameraclips. Never, Only Me und Everyone in this Home regeln die Bibliotheks-/Namensfreigabe. Never lässt manuell in Home zugeordnete Clip-Gesichter zu. | Keine belegte HomeView-Abfrage der Home-Besucher-/Namensdatenbank. Ein erkanntes Gesichtsrechteck, ein Demoprofil oder eine allgemeine PhotoKit-Freigabe ist kein solcher Identitätsbeleg. Keine Photos-/Home-Freigabe aus Nutzerannahmen abgeleitet. |
| HKSV-Clipkatalog und Wiedergabe | Home zeigt die letzten zehn Tage. Berechtigte Nutzer können die Aufnahme-Timeline bedienen; Eigentümer steuern Zugriff auf Aufnahmen und entfernte Streams. [iCloud-Anleitung](https://support.apple.com/guide/icloud/icloud-homekit-secure-video-mme054c72692/icloud). | Live-Stream oder zuletzt erzeugter Snapshot ist keine API für diesen Cloud-Clipkatalog. Kein bestehendes HKSV-Archiv gelesen, durchsucht oder abgespielt. |
| Videobeschreibungen | [Apple dokumentiert ausdrücklich](https://support.apple.com/guide/iphone/apple-intelligence-home-cameras-bd2gjv2g9nx0/ios) Apple-Intelligence-Beschreibungen aufgezeichneter kompatibler Home-Kameras auf iOS 27. Diese Fähigkeit wird **nicht** als nicht existent bezeichnet. | Kein dokumentierter App-Lesepfad für diese Home-Beschreibungen in den geprüften HomeKit-/CloudKit-Verträgen belegt. F037 bleibt unerfüllt. |
| Natürliche Archivsuche | Derselbe aktuelle Home-Leitfaden nennt natürliche Suchanfragen über die aufgezeichneten Videos. Der Home-Eigentümer aktiviert das für die jeweiligen Kameras. | Der vorhandene Systembedienweg beweist keine HomeView-API für Suchanfrage, Ergebnis-IDs oder Clip-/Beschreibungsausgabe. Eine Mock-Suche oder eigener Medienindex wäre eine andere Fähigkeit. |

Nicht analysierte Clips sind ebenfalls möglich: Laut Apple können bei zu vielen Kameras für die verfügbaren analysierenden Home Hubs Aufnahmen weiter gespeichert werden, ohne spezifische Motion-Klassifikation. Die dokumentierten Kamerazahlen sind deshalb kein Nachweis, dass jeder Clip tatsächlich analysiert wurde.

## Hardware-, Account- und Freigabeebenen

- **Grundlegendes HKSV:** passende HKSV-Kamera, Home Hub, Apple-/iCloud-Home-Kontext und iCloud+-Plan. Die aktuellen Anleitungen nennen 50GB für eine Kamera, 200GB für bis zu fünf und 2TB/6TB/12TB für unbegrenzt viele. Aufnahmen bleiben zehn Tage; ihr Inhalt zählt nicht gegen das Speicherkontingent. Das ist eine dokumentierte Bedingung, keine Kaufempfehlung oder Prüfung eines vorhandenen Kontos.
- **Geteilte Berechtigung:** Der Eigentümer entscheidet über Aufnahmen, entfernte Streams und Kameraverwaltung. Aufnahmeberechtigung ist nicht mit bloßer Mitgliedschaft oder lokalem Live-Bild gleichgesetzt. Die Quellen beschreiben Home-Endnutzerfreigaben, keine automatisch zusätzliche Drittanbieter-API.
- **Bekannte Gesichter:** Home-eigene Gesichts-/Namenszuordnung und die drei Photos-Freigabeoptionen sind getrennt zu prüfen. Photos-Sharing ist nicht pauschal immer notwendig; umgekehrt gewährt generischer Photos-Zugriff keinen bewiesenen Home-Namensdatenbankzugriff.
- **Neue Home-KI:** Die iOS-27-Anleitung nennt HomePod (2. Generation), HomePod mini oder Apple TV 4K mit aktueller Software, einen Home-Eigentümer mit Apple-Intelligence-fähigem iPhone, aktiviertes Apple Intelligence in Home und einen 2TB-iCloud+-Plan. Sie nennt iPhone 15 Pro/Pro Max oder iPhone-16-Modelle und neuer; Sprach-/Regions- und Nutzungslimits können gelten. Höhere Tarifvarianten oder konkrete vorhandene Geräte-/Accountrechte werden hier nicht zusätzlich abgenommen.
- **App-Zugriff:** [HomeKit-Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.homekit), [Usage Description](https://developer.apple.com/documentation/bundleresources/information-property-list/nshomekitusagedescription) und bewusste Nutzerfreigabe betreffen die jeweiligen öffentlichen HomeKit-Zugriffe. [Apple erklärt](https://developer.apple.com/documentation/homekit/enabling-homekit-in-your-app), dass die erste tatsächliche Nutzung – typischerweise die Erzeugung eines HMHomeManager – den Systemdialog auslösen kann. Hier wird keiner erzeugt, auch nicht „nur zum Prüfen“.

Ende-zu-Ende-Verschlüsselung wird nicht als pauschaler Unmöglichkeitsbeweis verwendet: Berechtigte Home-Benutzer können ihre Aufnahmen sehr wohl ansehen. Entscheidend ist der für diese App tatsächlich belegte Schnittstellen- und Berechtigungsweg.

## Was die öffentlichen App-Verträge tatsächlich belegen

[HMCameraProfile](https://developer.apple.com/documentation/homekit/hmcameraprofile) bündelt optionale Kamera-Steuerungen. Hersteller müssen nicht jede unterstützen. Gelesen wurden die vollständigen aktuellen DocC-Dokumente und die öffentlichen SDK-Header:

- [HMCameraStreamControl](https://developer.apple.com/documentation/homekit/hmcamerastreamcontrol): Start/Stop, aktueller Stream-/Status und Delegate.
- [HMCameraSnapshotControl](https://developer.apple.com/documentation/homekit/hmcamerasnapshotcontrol): Snapshot auslösen, jüngster Snapshot und Delegate. Nicht gleichgesetzt mit historischen HKSV-Clips oder deren Erkennungs-/Suchmetadaten.
- Einstellungen, Mikrofon-/Lautsprechersteuerung sind weitere optionale Profilteile; ihr Vorhandensein ist kein Archiv- oder KI-Ergebniszugriff.
- [CKContainer](https://developer.apple.com/documentation/cloudkit/ckcontainer) beschreibt die eigenen App-Datenbanken und Container mit passenden Entitlements. Ein aktiver iCloud-Account oder die generische Containerklasse gewährt nicht automatisch Apples HKSV-Daten, Face-Namen oder Home-KI-Index. Keine Containerinstanz und kein Account-/Datenbankaufruf hier.

Die Kamera-Klassen sind in den gelesenen Headern unter anderem für iOS und Mac Catalyst deklariert, aber ausdrücklich nicht für natives macOS. Das widerlegt **nicht** die von Apple dokumentierte Wiedergabe in der macOS-Home-App. SDK-App-Vertrag, Catalyst, System-App und tatsächliche Geräteabnahme werden getrennt geführt. Für weitere Plattformen ist eine Deklaration kein Laufzeit-/Kamerafunktions-PASS.

Der strikt öffentliche SDK-Scan liest 22.520 aufgelöste, deduplizierte Header/öffentliche Swift-Interfaces in fünf SDKs von Xcode 27.0 (27A266a). PrivateFrameworks, PrivateHeaders sowie private/package Swift-Interfaces sind ausgeschlossen. Die rohen Suchtreffer bleiben erhalten: etwa interface/Face-Wortanteile, Zubehör-Discovery-Suche, Cloud-Sync-Fehler und ein InputDeviceType-Enumwert Recording sind keine HKSV-Archiv-APIs. Keine passende Integrationskette für die obigen Unterfunktionen ist damit belegt. **Dies ist kein universeller Nicht-Existenzbeweis für jede zukünftige oder anders benannte Schnittstelle.** Es wurden keine privaten Frameworks, Binärsymbole oder Laufzeitobjekte untersucht.

## Vorhandener Drittanbieterpfad ist keine stillschweigend akzeptierte Alternative

Die öffentliche [HAP-NodeJS-Dokumentation](https://developers.homebridge.io/HAP-NodeJS/interfaces/CameraRecordingDelegate.html) beschreibt tatsächlich einen CameraRecordingDelegate: Ein Zubehör verwaltet seinen eigenen Prebuffer; nach Benutzeraktivierung und ausgewählter Controller-Konfiguration liefert es auf Anfrage fragmentierte Aufnahme-Pakete an einen HomeKit-Controller. Dieser positive Aufnahmeweg wird nicht verschwiegen.

Das ist in diesem Vertrag der **Zubehör-zu-Controller-Lieferweg**, kein belegter HomeView-Clientzugriff auf Apples bereits gespeicherten HKSV-Clipkatalog, Besucheridentitäten oder Home-KI-Suchergebnisse. Es wurde nichts installiert, gepairt, gestartet oder als kompatibel auf diesem Host getestet. Eine eigene Kamera-/Archiv-/ML-Lösung oder solche Bibliothek wäre ein separater Produktumfang mit eigener ausdrücklicher Freigabe und Datenrechten; sie wird weder gebaut noch stellvertretend ausgewählt.

## Konkreter HomeView-Stand und Nachweisgrenze

CameraAndCommunication.swift zeigt ausdrücklich gebündelte generierte Demostills und Mock-Talkback, keinen Kamerazugriff oder HKSV-Archivclient. NativeHomeKitService.init wirft unverändert realHomeDisabled; sein Manager ist optional und wird nirgends in diesem Initialisierungspfad erzeugt. Eine Demoansicht wird nicht zu einer echten HKSV-Erkennung umetikettiert.

Alle 206 Quellen-/Test-/Ressourcen-/Projekt-/Scriptdateien bleiben bytegleich zum veröffentlichten Stand 337aaa6. Reine Dokumentations-/SDK-Prüfung: keine neuen Builds, UI-/Core-/nativen App-Läufe, Bilder oder Geräte-PASS-Behauptungen. Keine Home-Anbindung, kein Home-Manager, keine Discovery, Kamera, Photos-/iCloud-/CloudKit-/Accountabfrage, Berechtigung, Einstellung, Recording, Drittanbieterinstallation oder eigene Transportlösung. F036/F037 und sämtliche ursprünglichen Funktions-/Service-/Originalkriterien bleiben unerfüllt; nur das Recherchepaket ist abgeschlossen.
