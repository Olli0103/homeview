# Intercom: Machbarkeit geklärt, Originalzustellung blockiert

20. Oktober 2026 · [#45 / COM-04](https://github.com/Olli0103/homeview/issues/45) · [Mess-/Quellenbericht](verification/intercom-public-feasibility.json)

**Ergebnis:** In den geprüften offiziellen Dokumenten und öffentlichen Schnittstellen der fünf installierten SDKs ist kein unterstützter Drittanbieter-Sendepfad zu **Apple Home Intercom** belegt. Die Machbarkeitsprüfung ist damit abgeschlossen. **F058 bleibt blockiert, Originalzustellung unerfüllt, parity=false.** Es wurde keine Nachricht zugestellt und keine Zielbestätigung gemessen.

Das ursprüngliche Recherche-Issue lässt ausdrücklich „API-Nachweis und tatsächlicher Ziel-Read-back **oder blockierter Status**“ zu. Ein Abschluss dieses Recherchepakets ist deshalb keine Implementierungs- oder Geräteabnahme. Eine allgemeine Behauptung, es könne nirgends und niemals einen anderen Weg geben, wird nicht aufgestellt.

## Belegte Grenzen

| Weg | Was die Quelle tatsächlich beschreibt | Was das nicht belegt |
| --- | --- | --- |
| [Apple Intercom](https://support.apple.com/en-us/101606) | Benutzer sendet über Siri oder Home-App; alle Empfänger oder bestimmter Raum/Zone. Home-Einstellungen bestimmen Mitglieder, beteiligte HomePods und Empfangsmitteilungen auf persönlichen Geräten. | Keine Drittanbieter-Sendemethode, stabilen Ziel-IDs oder App-Zustellbestätigung. Die dokumentierten Systemeinstellungen sind nicht Olli-spezifisch geprüft. |
| [HomeKit](https://developer.apple.com/documentation/homekit) / [Apple Home](https://developer.apple.com/apple-home/) | Konfiguration und Steuerung unterstützter Hausgeräte; App-Entitlement und Usage Description für HomeKit-Daten. | HomeKit-Berechtigung ist kein Nachweis einer Apple-Intercom-Sendeberechtigung. Mikrofon- oder Siri-Freigabe allein ebenfalls nicht. |
| [SiriKit Messaging](https://developer.apple.com/documentation/sirikit/messaging) | `INSendMessageIntent` lässt Siri Nachrichten über **den eigenen Dienst** der App senden; die App spendet eigene Interaktionen. | Kein Aufruf, der Apple Home zum Versand einer Intercom-Aufnahme verpflichtet. Eine Intent-Spende ist keine Zustellung. |
| [Shortcuts-URL](https://support.apple.com/guide/shortcuts/run-a-shortcut-from-a-url-apd624386f42/ios) | Start eines namentlich benannten Benutzer-Kurzbefehls mit optionalem Text. | Keine dokumentierte direkte Intercom-API, Empfängerliste oder bestätigte Zustellung. Kein bestehender Kurzbefehl wurde geprüft, erstellt oder ausgeführt; eine mögliche benutzerseitige Kette bleibt separat unbelegt. |
| [pyatv](https://pyatv.dev/) | Vorhandene Open-Source-Bibliothek für AirPlay/Mediensteuerung, unter anderem HomePod-Streaming. Die Projektdokumentation bezeichnet ihre Protokolle ausdrücklich als privat/reverse-engineert. | Kein Ersatzbeleg für Apple-Home-Intercom-Semantik. Nur Dokumentation geprüft; weder installiert noch Geräte gesucht oder angesprochen. Keine eigene Audioalternative geplant. |

Es gibt damit keinen nachgewiesenen App-Vertrag für **Senden → ausgewähltes Apple-Intercom-Ziel → bestätigten Empfang**. Lokales Abspielen, AirPlay-Streaming, ein Banner oder ein Eintrag in der Demo-Historie werden nicht als Ersatz abgenommen.

## Öffentliche SDK-Suche

Xcode **27.0 / 27A266a**, ausschließlich `System/Library/Frameworks`: Header unter `Headers` sowie öffentliche Swift-Interfaces unter `Modules`, aufgelöste Dateien dedupliziert. `PrivateFrameworks`, `PrivateHeaders`, `.private.swiftinterface` und `.package.swiftinterface` ausgeschlossen. Keine Binäranalyse, kein Framework instanziiert.

| SDK | Untersuchte Dateien | Intercom-Treffer |
| --- | ---: | ---: |
| iPhoneSimulator 27.0 | 4.577 | 1 |
| MacOSX 27.0 | 6.862 | 4 |
| AppleTVSimulator 27.0 | 3.654 | 1 |
| XRSimulator 27.0 | 4.398 | 1 |
| WatchSimulator 27.0 | 3.029 | 1 |

Alle **acht** Treffer sind im Bericht aufgeführt, nicht als „keine Intercom-Symbole“ unterschlagen:

- `MTRDeviceTypeIDTypeIntercomID = 0x140`: Matter-Gerätetyp, keine Apple-Home-Sendemethode. Die Deklaration ist vorläufig; `MTR_PROVISIONALLY_AVAILABLE` wird ohne aktiviertes `MTR_ENABLE_PROVISIONAL` auf `NS_UNAVAILABLE` abgebildet. Kein entsprechender Schalter wurde aktiviert.
- `kBluetoothSDPUUID16ServiceClassIntercom = 0x1110`: Bluetooth-SDP-Serviceklasse in zwei macOS-Headern, kein HomePod-Intercom-Zustellvertrag.
- `telBadIntercomID = -10052`: alter Carbon-Telefoniefehler, keine Sendeschnittstelle.

Die Dateisuche ist ein begrenzter Namens-/Interface-Audit und kein mathematischer Unmöglichkeitsbeweis für anders benannte oder künftig neue APIs. Zusammen mit den oben geprüften Verträgen reicht sie hier zu **„kein unterstützter Pfad belegt; blockiert“**, nicht zu einer universellen Negativbehauptung.

Eine frühere explorative Suche ließ private Swift-Interface-Namen zu und enthielt Teilwort-Fehlfundstellen wie `PrinterCommandSupport`; sie wurde nicht als öffentlicher Nachweis übernommen. Das vorliegende strikte Inventar trennt diese Grenzen. Ein geratenes Matter-Dokumentationsziel lieferte 404; daraus wird keine API-Verfügbarkeit abgeleitet. Ein Tech-Talk-Abruf lieferte nur Navigation, keinen abgenommenen Transkriptbeleg.

## Konsequenz für HomeView

Die vorhandene Intercom-Ansicht bleibt ausdrücklich **Local simulation. Not connected to HomePod Intercom**. Ihr Demo-Knopf schreibt nur die lokale Laufzeit-Historie und zeigt einen Simulationshinweis. In dieser Prüfung wurde kein Produktcode geändert oder ausgeführt; sämtliche 206 Quellen-/Test-/Ressourcen-/Projekt-/Scriptdateien bleiben bytegleich zum veröffentlichten Rezeptstand `e1bf80a`. Daher keine neuen Builds oder UI-PASS-Behauptungen für diese reine Recherche.

Die vollständigen abgerufenen Dokumente, Scanprogramm und SDK-Dateihashliste bleiben im externen Nachweisarchiv; dessen acht Einträge wurden vollständig zurückgelesen. Im Repository liegen nur Bericht, kurze zugeordnete Belege und Digests, keine kopierten SDK-Header oder Apple-Referenzbilder.

**Nicht vorgenommen:** Home-Einrichtung, `HMHomeManager`, Discovery, Mikrofonaufnahme, persönliche Daten, Geräteansprache, Shortcut-Ausführung, Nachricht, Audio-Streaming oder Berechtigungsänderung. Eine eigene Audiozustellung wäre ein anderes Produktmerkmal und benötigt weiterhin einen neuen ausdrücklichen Auftrag. Sie wurde weder entworfen noch implementiert. Wiederaufnahme von F058 erst mit neu belegtem unterstütztem Sendepfad und gesonderter erlaubter Geräte-/Empfängerabnahme. **Keine Home-Anbindung.**
