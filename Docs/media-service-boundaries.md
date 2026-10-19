# Weitere Medien: erreichbare APIs und klare Systemgrenzen

19. Oktober 2026 · [MEDIA-04, #60](https://github.com/Olli0103/homeview/issues/60). Recherche und SDK-Oberflächenprüfung, **kein neuer Medienanschluss**. F084/F085 werden nicht als Original-Parität ausgegeben.

## Angebote und Rechte

| Angebot | Öffentlicher Pfad | Erforderliche Rechte / Grenze | Tatsächlicher Appstand |
|---|---|---|---|
| Hörbücher | `MPMediaQuery.audiobooks()` kann freigegebene Medienbibliotheksobjekte liefern. `assetURL` ist optional; `hasProtectedAsset` und `bookmarkTime` sind öffentlich. Zugängliche, berechtigt nutzbare Dateien können über AVPlayer laufen. | Explizite Medienbibliotheksfreigabe und echte vorhandene Items nötig. Kein daraus abgeleiteter Zugriff auf den gesamten Apple-Books-Store, private Books-Synchronisation oder DRM-Schlüssel. Fehlende/nicht nutzbare URL ist kein Demo-Erfolg. | Eigener Bibliotheksadapter und Hörbuch-UI **noch nicht implementiert**, obwohl ein öffentlicher Teilpfad existiert. Kein pauschales API-Verbot. Bestehende RSS-Audiowiedergabe ersetzt keine Books-Bibliothek. |
| Classical Music | MusicKit sucht und spielt verfügbare `Song`-Einträge des Apple-Music-Katalogs; der SDK-Typ bietet unter anderem `composerName`. Klassische Titel sind keine besondere App-Einbettung. | MusicAuthorization, passende App-Service-Provisionierung und tatsächliche Subscription-Fähigkeiten prüfen. Kein zusätzlicher Kauf oder Preis wird angenommen. Dies ist kein nachgewiesener Zugang zur privaten Oberfläche/gesonderten Sammlung von Apple Music Classical. | Allgemeiner expliziter MusicKit-Pfad vorhanden. Eigene Werk-/Satzansicht oder Classical-App-Import fehlt; echte Kontowieder­gabe nicht durch die synthetischen Tests abgenommen. |
| News | Öffentliche Artikel-HTTPS-URLs können nach ausdrücklicher Aktion an Browser/geeignete empfangende App übergeben werden. Die geprüfte **Apple News API** veröffentlicht und verwaltet Artikel eigener Publisher-Kanäle. | Publisher-API ist kein privater Leser-/News+-Kontozugang. Inhalte und Rechte kommen vom jeweiligen Anbieter; ein Link ist keine Leserbibliothek und kein Abo. | Keine eingebettete News-/News+-Bibliothek. Vorhandener Browser ist nur ein expliziter allgemeiner URL-Pfad, kein News-Import. |
| TV / Video | AVPlayer unterstützt eigene/berechtigt zugängliche lokale Medien und HLS. Das SDK kennt außerdem Legacy-Medientypen `movie`/`tvShow` und generische MediaPlayer-Filter. | Keine Ableitung eines universellen Apple-TV-/TV+-Kontokatalogs, fremder DRM-Lizenzen oder Kaufrechte. Die Legacy-Query ist nicht gleichbedeutend mit einer vollständigen aktuellen TV-App-Bibliothek. Reale Items/Streams und gegebenenfalls Anbieterrechte bleiben Voraussetzung. | Eigene Video-UI und Bibliotheksadapter **nicht implementiert**; öffentliche AVFoundation-Softwarearbeit ist möglich. Die neue Podcast-Ansicht akzeptiert ausdrücklich Audio, nicht Video. |
| Drittanbieter-Audio/-Video | Apples aktuelle CarPlay-Seite nennt Audio-/Video-Apps und ausdrücklich deren Unterstützung auf Apple HomeView. `CPTemplateApplicationScene` ist im iOS-SDK vorhanden. | Das ist der Entitlement-/Template-/Systemhost-Pfad der jeweiligen App, kein Recht unserer gewöhnlichen iPad-App, andere Apps einzubetten oder deren privaten Zustand auszulesen. Entitlement, unterstützte App, passender Host und echte Geräteprüfung bleiben nötig. | Kein freier App-Store-/Universalhost und keine eingebetteten Drittanbieter-Apps. Anbieter-APIs oder dokumentierte Links wären jeweils separat zu integrieren; kein Icon wird als Integration gezählt. |

MediaPlayer-Bibliotheksqueries sind im geprüften Header nicht auf macOS, tvOS oder watchOS verfügbar. Der erfolgreiche Probe ist deshalb **iOS-Simulator arm64**, kein Universal-Featurebeleg. Andere Plattformen brauchen ihren eigenen öffentlichen/autorisierten Pfad oder bleiben ausdrücklich nicht unterstützt.

## Start, Remote-Wiedergabe, Einbettung und Handoff sind verschieden

- **App-/Linkstart:** Das Betriebssystem übergibt eine ausdrücklich gewählte URL an einen passenden Handler. Ohne passenden Handler ist „nicht verfügbar“ korrekt; es gibt keine Garantie für eine bestimmte Drittanbieter-App oder die Wiederaufnahme eines bestimmten Titels. Kein undokumentiertes URL-Schema wird vorausgesetzt.
- **Eigene eingebettete Wiedergabe:** AVPlayer spielt berechtigt zugängliche Assets; MusicKit spielt unterstützte Musikinhalte unter seinen Voraussetzungen. Das bettet weder fremde App-Oberflächen noch deren gesamten Account ein.
- **Remote-Wiedergabe:** Der vorhandene eigene Player oder ein dokumentierter Anbieterpfad ist nötig. Öffentliche eigene Now-Playing-/Remote-Command-APIs sind kein universeller Zugriff auf jeden anderen iPhone-Player. Apple-HomeView-Systemweiterleitung ist mit einer gewöhnlichen iPad-App nicht automatisch verfügbar.
- **Handoff:** `NSUserActivity` kapselt den Zustand **unserer** App und ihrer vereinbarten Aktivitätstypen. Ein selbst definierter Typ überträgt nicht beliebig Apple-Books-, TV- oder andere fremde private Sitzungen. Erfordert eine kompatible empfangende Implementierung und echte Gerätekonfiguration/-abnahme. Der eigene Rezept-Handoff bleibt die separate Arbeit #56.

## Nachweise und verbleibende Softwarearbeit

Am 19. Oktober direkt gelesene öffentliche Quellen:

1. [MusicKit](https://developer.apple.com/documentation/musickit): Katalog, Autorisierung, Subscription-Fähigkeiten und Playback.
2. [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer): lokale/remote Assets und HLS.
3. [CarPlay](https://developer.apple.com/carplay/): Audio-/Video-Kategorien, Entitlementanfrage und aktuelle HomeView-Kompatibilitätsaussage.
4. [NSUserActivity](https://developer.apple.com/documentation/foundation/nsuseractivity): eigener Appzustand und Aktivitätstypen.
5. [MPMediaQuery.audiobooks()](https://developer.apple.com/documentation/mediaplayer/mpmediaquery/audiobooks()) und [MPMediaItem.assetURL](https://developer.apple.com/documentation/mediaplayer/mpmediaitem/asseturl): eingeschränkter Bibliotheks-/Assetpfad.
6. [Apple News API](https://developer.apple.com/documentation/applenewsapi): Publisher-Artikel, keine daraus belegte private Leserkontobibliothek.

Die zusätzliche vermutete URL `MPMediaQuery.movies()` lieferte404. Daraus wird **keine API-Abwesenheit** abgeleitet: der tatsächlich im SDK vorhandene generische Filter über `MPMediaType.movie`/`tvShow` wurde stattdessen geprüft.

[Compile-only-Probe](verification/media-api-surface.swift) wurde mit Xcode27.0 (27A266a), iPhoneSimulator27.0 und Ziel arm64/iOS26.1 erfolgreich typgeprüft. Die Funktion wurde **nicht ausgeführt**: keine Berechtigungen, Bibliotheken, Käufe, Konten oder Geräte berührt. Keine SDK-Header oder Originalreferenzbilder werden redistribuiert. [Prüfbeleg](verification/media-service-boundaries.json).

Damit ist die öffentliche Zugriffsmatrix recherchiert. Die nicht implementierten Hörbuch-/Video-Adapter und speziellen Ansichten werden nicht zu angeblichen Hardwareblockaden umetikettiert: sie bleiben mögliche weitere Softwarearbeit. Ein öffentlicher API-Teilpfad oder eine recherchierte Systemgrenze ist keine funktional/visuell gleichwertige Original-App. F084/F085 bleiben entsprechend bilanziert. Apple Home wird nicht verbunden.
