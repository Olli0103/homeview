# Gast-AirPlay und Peer-to-peer sind getrennte Nachweise

20. Oktober 2026 · [#62 / MEDIA-06](https://github.com/Olli0103/homeview/issues/62) · [Quellen-/Codebericht](verification/guest-airplay-boundaries.json)

**Voraussetzungen und OS-Rollen geklärt; F087 bleibt blockiert, parity=false.** Keine echte Gastsequenz oder eigene HomeView-Empfängerfunktion wurde nachgewiesen. Das ursprüngliche Recherche-Issue erlaubt ausdrücklich „echte Gast-Testsequenz … **oder weiter explizit blockiert**“. Sein Abschluss nimmt deshalb weder einen Empfänger noch Peer-to-peer, Audiozustellung oder Mehrraumwiedergabe ab. [#61](https://github.com/Olli0103/homeview/issues/61) bleibt für die tatsächliche Routenauswahl-/Wiedergabeabnahme offen.

## Vier unterschiedliche Fragen

| Frage | Bedeutung | Nicht daraus ableiten |
| --- | --- | --- |
| Gastberechtigung | Welcher Nutzer bzw. welches Gerät darf den OS-Empfänger ansprechen? | „Everyone“ beweist keinen bestimmten Funk-/Medienpfad. |
| Discovery | Wie wurde der Empfänger entdeckt: Bonjour, Bluetooth-IP-Anzeige oder Peer-to-peer? | Ein sichtbarer Empfänger beweist weder Authentifizierung noch hörbare Wiedergabe. |
| Transport | Läuft der Medienstrom über Infrastruktur-IP oder eine direkte Verbindung? | Auch Peer-to-peer-Discovery kann laut Apple zu einer Verbindung über den bevorzugten vorhandenen Netzwerkweg führen. |
| Empfängerrolle | Apple TV, macOS-AirPlay-Receiver oder eine gesonderte Anwendung empfängt Medien. | Ein Sender-Button, eine laufende HomeView-App oder ein Audio-Route-Observer macht HomeView nicht selbst zum AirPlay-Empfänger. |

## Öffentlich dokumentierte Voraussetzungen

[Apple Platform Deployment: Use AirPlay](https://support.apple.com/guide/deployment/use-airplay-dep9151c4ace/web) beschreibt die Wege getrennt:

- **Bonjour:** lokale Multicast-Discovery, im normalen Fall gleiches IP-Subnetz. Ein Gateway kann größere Netze unterstützen; statische DNS-Angaben allein ersetzen die benötigte lebende Discovery nicht. Hier wurde kein Gateway, Firewall- oder DNS-Eintrag geändert.
- **Bluetooth-IP-Anzeige:** Apple TV bewirbt eine IP-Adresse; nahe Geräte versuchen eine Sitzung über das **bestehende Netzwerk**. Gleiches WLAN ist dabei nicht grundsätzlich nötig, aber IP-Erreichbarkeit bleibt nötig. Das ist nicht schon der Nachweis einer direkten Medienverbindung.
- **Peer-to-peer:** Bluetooth-Advertisement führt zu einer temporären direkten Wi-Fi-Verbindung. Eine bestehende Infrastruktur-Netzwerkzuordnung ist dafür nicht erforderlich. Trotzdem können Geräte für die tatsächliche Verbindung den reaktionsschnellsten oder zuletzt benutzten Weg bevorzugen. **Discovery-Pfad und Medienpfad nicht gleichsetzen.**

Für Peer-to-peer-AirPlay nennt die Deployment-Dokumentation:

| Rolle | Genannte Voraussetzung |
| --- | --- |
| Apple-TV-Empfänger | Apple TV HD mit tvOS 9 oder neuer, oder Apple TV 4K mit tvOS 11 oder neuer |
| Apple-Sender | iPhone, iPad und Mac ab Ende 2012 mit aktueller Version ihres Betriebssystems laut Quelle; konkretes Modell und tatsächlich unterstützte OS-Version gesondert prüfen |
| Zugriff auf Apple TV | „Everyone“ erlaubt Peer-to-peer **oder** Infrastruktur; „Anyone on the same local network“ beschränkt auf das lokale Netz; „Off“ deaktiviert AirPlay |
| Authentifizierung | Peer-to-peer bleibt laut Apple durch „Require Device Authentication“ abgesichert; diese Einstellung ist nicht frei abschaltbar. Es wird kein passcodefreier oder unauthentifizierter Gastzugang versprochen. |

Das sind dokumentierte Voraussetzungen, **keine Prüfung eines vorhandenen Geräts**. Es werden weder unbekannte Hardwaremodelle als kompatibel eingestuft noch alte Geräte pauschal als heute mit der neuesten Hauptversion versorgbar bezeichnet. Die Apple-TV-Receiver-Liste wird nicht auf jeden Mac, HomePod oder ein iPad mit laufender HomeView-App übertragen.

## Mac und HomePod: andere Rollen und Regeln

### AirPlay zum Mac

Die aktuelle [Continuity-Anforderungsliste](https://support.apple.com/en-us/108046#airplaytomac) nennt:

- Sender: iPhone 7 oder neuer mit iOS 14+, iPad Pro ab 2. Generation, iPad ab 6. Generation, iPad Air ab 3. Generation oder iPad mini ab 5. Generation mit iPadOS 14+.
- Mac: macOS Monterey 12+, iMac Pro, Mac mini ab 2020, sonstige Macmodelle ab 2018 laut Liste.
- Ältere **sendende** Geräte können unter den genannten Bedingungen mit geringerer Videoauflösung funktionieren. Daraus wird keine pauschale Freigabe jedes älteren Macs als nativer Empfänger abgeleitet.

Die [macOS-Anleitung](https://support.apple.com/guide/mac-help/stream-video-and-audio-with-airplay-mchld7e543a0/mac) beschreibt den OS-Schalter AirPlay Receiver, die Zugriffsoptionen Current User / Anyone on the Same Network / Everyone und ein optionales Passwort. Ihr dokumentierter Standardablauf verlangt Wi-Fi und gemeinsames Netzwerk. Das steht nicht im Widerspruch zur separaten Apple-TV-Peer-to-peer-Beschreibung: Es sind unterschiedliche Empfänger-/Ablaufkontexte. Diese Anleitung ist **kein zusätzlicher Beweis für einen eigenen HomeView-Peer-to-peer-Receiver**. Keine dieser Einstellungen wurde geöffnet oder geändert.

### HomePod-Gäste

[Apple beschreibt](https://support.apple.com/guide/homepod/let-others-play-audio-apdb68d3dec5/homepod) Everyone, Anyone On the Same Network und Only People Sharing This Home sowie eine mögliche Passwortanforderung. Das sind Gast-/Zugriffsregeln. „Everyone nearby“ wird nicht unterschlagen, aber daraus wird hier weder der tatsächlich benutzte Medienpfad noch die Gleichheit mit den Apple-TV-Peer-to-peer-Voraussetzungen abgeleitet. Home-Zugehörigkeit ist eine andere Frage als Netztransport. **Keine Home-/HomePod-Einrichtung oder -Verbindung ausgeführt.**

## Vorhandene Option nicht als offizielle HomeView-Fähigkeit ausgeben

Die Quellenprüfung berücksichtigt [UxPlay am festgehaltenen Commit `4e95a9e`](https://github.com/FDH2/UxPlay/tree/4e95a9ec013c52d8555d88dbc55abe346e94d56e). Dessen README bezeichnet Version 1.74 als **Experimental** und dokumentiert eine direkte AWDL-Clientverbindung für macOS mit Bonjour. Diese positive Angabe wird nicht in „keine Drittanbieteroption“ umgedeutet. Die README sagt zugleich, dass AirPlay-2-Mehrraum-Audio nicht unterstützt wird.

Das ist eine separate quelloffene Empfängeranwendung, **keine in HomeView integrierte öffentliche Apple-Empfänger-API oder hier geprüfte Gastfunktion**. Sie wurde nicht heruntergeladen/installiert/gebaut/gestartet und nicht als Alternative ausgewählt. Weder ihre AWDL-Funktion noch Hostkompatibilität, Protokollverhalten oder Wiedergabequalität wurden abgenommen. Es gibt keinen neuen mDNS-/Bluetooth-Beacon, Receiverdienst oder privaten Framework-Import. Eine andere Produktalternative wurde nicht stellvertretend akzeptiert.

## Definierter OS-Übergang und verbleibende Abnahme

Der belegte **Systempfad** bleibt: ein ausdrücklich erlaubter Sender verwendet Apples AirPlay-/Routenauswahl; der Nutzer wählt einen bewusst konfigurierten passenden **OS-Empfänger**, bestätigt dessen vorgeschriebene Authentifizierung und beendet die Ausgabe wieder über den Systempfad. Für den Mac ist dies der dokumentierte macOS-Receiver, für direktes Apple-TV-Peer-to-peer gelten dessen eigene Voraussetzungen. Dies ist eine Definition des unterstützten OS-Bedienwegs, **kein behaupteter neuer HomeView-Button oder erfolgter Gerätestest**.

`AVRoutePickerView` ist laut [öffentlicher AVKit-Dokumentation](https://developer.apple.com/documentation/avkit/avroutepickerview) eine Auswahl nahegelegener Medienempfänger, nicht selbst eine Empfängerimplementierung. Der aktuelle HomeView-Code enthält keinen solchen Picker oder `MPVolumeView`. Er reagiert bereits auf `AVAudioSession.routeChangeNotification` mit Pause bei Verlust des bisherigen Geräts. Das ist eine lokale Audio-Lifecycle-Behandlung, **keine Gast-Discovery, Routenanzeige oder Mehrraumsteuerung**.

Für eine spätere separat erlaubte Gastabnahme fehlen weiterhin:

1. Konkrete Sender-/Empfängermodelle, OS-Versionen und bewusst erlaubte Gastidentität, ohne diese aus Olli-spezifischen Einstellungen zu erraten.
2. Nachweis von Zugriff und vorgeschriebener Bestätigung; kein Umgehen von Authentifizierung oder Aufweiten der aktuellen Freigaben.
3. Tatsächlicher Discovery- **und** Medienpfad in kontrollierten Bedingungen. Unterschiedliche SSIDs, ein gefundenes Gerät oder ein Bluetooth-Beacon allein reichen nicht als Peer-to-peer-Nachweis.
4. Hörbares eigenes Testmedium und tatsächlicher Routenstatus, danach Abbruch, fehlender/abgelehnter Empfänger und Rückkehr zur lokalen Route. Keine automatische Verbindung oder fremde Medien-/Accountnutzung.
5. Eigener Nachweis je Empfängerkategorie; Mac/HomePod/Apple TV nicht austauschbar bilanzieren. Mehrraum bleibt separat in #61 und wird nicht aus Einzelziel-Streaming gefolgert.

Diese Sequenz wurde **nicht** gestartet. Damit bleibt die Originalfähigkeit ausdrücklich blockiert. Normales WLAN-Streaming ist keine Ersatzabnahme.

## Nachweisumfang

Vier aktuelle offizielle Haupttexte, die öffentliche AVKit-Beschreibung und die gepinnte UxPlay-README wurden dokumentarisch geprüft. Vollständige gelesene Inhalte und Quellenbindung bleiben im externen Archiv; keine SDK-Header, Apple-Bilder oder Fremdbinaries werden in die App kopiert. Die vorhandene Option wird nicht als installierter oder funktionierender Receiver ausgegeben.

Alle 206 Quellen-/Test-/Ressourcen-/Projekt-/Scriptdateien bleiben bytegleich zum veröffentlichten Stand `34b95f0`. Keine neuen Builds, UI-/Modellläufe oder physischen Geräte-PASS-Behauptungen. Keine Discovery, App-/OS-Receiverinstanz, Funk-/Netzwerk-/Firewall-/DNS-/Kontenänderung, Route, Wiedergabe, Installation oder Berechtigungsänderung. **Keine Home-Anbindung.**
