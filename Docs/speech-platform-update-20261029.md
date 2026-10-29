# Sprache: aktuelle Plattformgrenzen und einzelne Live-Speech-/RTT-Pfade

29. Oktober 2026 · [#74](https://github.com/Olli0103/homeview/issues/74). Ergänzt den [datierten Befund vom 20. Oktober](speech-feature-boundaries.md), ohne dessen alte Belege umzudatieren. **Recherche, keine neue akustische Hilfsmittel-, Telefonie- oder Hardwareabnahme.**

**Spätere native Runtime-Inventur:** [TV-/Vision-Settings ohne Feature-Aktivierung](os-speech-settings-inventory-20261029.md). Vision Live Speech ist jetzt tatsächlich sichtbar belegt, weiterhin Off. Die lokale Suche findet auch diese bekannte Funktion nicht; TV lässt die offiziell dokumentierte VoiceOver-Funktion ebenfalls aus. Diese konkreten Gegenkontrollen verbieten einen OS-Negativschluss für die weiterhin ungeklärten TV-/Vision-RTT-Zellen. Keine Produktdatei geändert oder neue Hilfsmittel-Nutzbarkeit behauptet.

## Neue positive OS-Belege

| Ziel / Funktion | Tatsächlich dokumentierter OS-Pfad | Konkrete verbleibende Grenze |
|---|---|---|
| iPhone RTT/TTY [N2] | Software RTT/TTY in Telefon; zeichenweises oder bewusst gebündeltes Senden; Hardware-TTY ist eine andere, optionale Variante | Passender Anbieter/Region/Netz, eingerichtete Telefonie und ausdrücklich autorisierter RTT-Gegenpart fehlen. HomeView besitzt keinen eigenen RTT-Kanal. |
| iPad RTT [N1] | FaceTime-App, Software RTT unter Bedienungshilfen; WLAN-Telefonie über ein iPhone vorausgesetzt | Kein verbundenes, eingerichtetes Telefonie-Paar/Gegenpart im accountfreien Prüfumfang. Das eigene FaceTime-Empfängerfeld ist kein RTT. |
| Watch RTT [N3] | Cellular-Watch kann RTT abseits des iPhone verwenden; Einrichtung in der Watch-App, Gespräch in Telefon | Cellular-/Anbieter-/Region-/Gegenpartabnahme nicht vorhanden; ein Simulator oder WatchRoot-Timer ersetzt sie nicht. |
| Vision Pro Live Speech [N5] | Einstellungen → Bedienungshilfen → Live Speech; Aktivierung über dreifache Digital-Crown-Betätigung; Ausgabe an der Gegenseite eines Anrufs | **Nur innerhalb von Anrufen, nicht außerhalb.** Keine autorisierte echte Gesprächssitzung/Gegenseite oder physische Vision-Abnahme. Eigener AVSpeechSynthesizer hat keinen Telefonie-Uplink. |
| Apple TV Live Captions [N4] | Apple TV 4K, Einstellungen → Bedienungshilfen → Live Captions **in FaceTime**; auch Gesprächssteuerung | Keine allgemeinen HomeView-/Umgebungsuntertitel daraus. FaceTime-Sitzung/Gegenpart und passende Hardware fehlen; Sprache/Region gesondert. |
| Watch Live-Listen-Untertitel [N6] | Nahe gekoppelte Watch zeigt Transkription, die das **iPhone** aus dessen Mikrofon erzeugt; Live-Listen-Fernsteuerung im Hörkontrollfenster | Gleiches Apple-Konto, gekoppeltes nahes iPhone, bewusste Hör-/Aufnahmeeinrichtung und passende Audiohardware nicht verbunden. Kein eigenständiger Watch-ASR-Nachweis. |
| Apple TV Type to Siri / Diktieren [N7, N8] | Systemeinstellung Type to Siri; Bildschirm-/Bluetooth-/iPhone-/iPad-Tastatur. Diktieren durch Halten der Siri-/Suchtaste | Das eigene Assistentenfeld ist nicht Siri. Kein Sprach-/Siri-Dienstlauf, keine gekoppelte Tastatur/physische Remote-Audioabnahme daraus. |
| Vision Pro Vocal Shortcuts [N9] | Nutzer wählt Aktion und spricht eigene Phrase mehrmals ein; Beispiele Lautstärke, Neuzentrieren, Bedienungshilfen | Nutzertraining und akustischer Aufruf auf echter Hardware fehlen. Kein HomeView-eigenes Wakeword oder automatisch trainierter Shortcut. |

N1 und N3 sind positive spezialisierte iPad-/Watch-Anleitungen. N2 enthält zugleich den allgemeinen Hinweis „Continuity features aren’t available for RTT and TTY support“. Das wird nicht zu einem pauschalen Verbot der separat dokumentierten iPad-/Mac-Pfade erweitert. Die tatsächliche konkrete Kombination muss am passenden eingerichteten Gerät geprüft werden.

## Vollständige Live-Speech-/RTT-Bilanz der sechs Ziele

| Ziel | Live Speech | RTT | HomeView / nächste belegbare Grenze |
|---|---|---|---|
| iPhone | OS dokumentiert [S1 im älteren Bericht]; damalige Modellliste bleibt historisch | Positiver aktueller OS-Pfad [N2] | Kein eigener Live-Speech-Telefonie-Uplink/RTT-Transport; Geräte-/Anbieter-/Gesprächsabnahme offen. |
| iPad | OS dokumentiert [S1]; aktuelle Modell-/Sprachprüfung nicht daraus ableiten | Positiver aktueller OS-Pfad [N1] | Persönliche Telefonie/WLAN-Anrufe nicht eingerichtet; eigene TTS ist kein OS-Live-Speech-PASS. |
| Mac | OS dokumentiert [S1], Apple-Silicon-Bedingung dort | OS-Mac-Anleitung [S6 im älteren Bericht], gekoppeltes iPhone/WLAN-Telefonie | Kein RTT-Kanal oder Telefonie-Uplink im Appcode. Zusätzlich Mac-UI-Runner an unverändertem Developer-Tools-Status blockiert; [separater Befund](mac-runtime-boundary.md). |
| Apple TV | Kein positiver Live-Speech-Pfad in den ausgewerteten Guides; **nicht als OS-unmöglich bewiesen** | Kein positiver RTT-Pfad in diesen Guides; **nicht als OS-unmöglich bewiesen** | App bietet weder eigene TTS noch RTT. N7 beschreibt Type to Siri und N4 FaceTime-Captions; beides ist kein Ersatz. OS-Pfad bleibt eine konkrete offene Recherche-/Runtimezelle. |
| Vision Pro | Positiv, aber **Anrufe-only** [N5] | Kein positiver RTT-Pfad in diesen Guides; **nicht als OS-unmöglich bewiesen** | Eigene TTS bleibt lokal. Autorisierte Gesprächsumgebung fehlt; RTT-OS-Pfad bleibt offen statt einer erfundenen API-Sperre. |
| Apple Watch | OS dokumentiert [S1]; tatsächliche Watch-Bedienung nicht geprüft | Positiver aktueller Cellular-Pfad [N3] | WatchRoot hat keinen Assistenten/TTS/RTT; keine eigene App-Shortcut-Registrierung dort. Geräte-/Telefonieabnahme offen. |

Alle zwölf Live-Speech-/RTT-Zellen sind damit **einzeln bilanziert**, nicht alle nutzbar oder abgenommen. Die nicht positiv geklärten TV-/Vision-Zellen werden nicht allein durch fehlende Hardware zu „erledigt“ erklärt. #74 bleibt für diese Zellen und die vollständige je-Hilfsmittel-Nutzbarkeitsabnahme offen; F104/F105 bleiben ohne Parity.

## Katalog ist kein negativer Beweis

Der aktuelle Apple-Accessibility-Katalog wurde nur teilweise extrahiert (100.000 Zeichen, als gekürzt markiert). Seine Live-Speech-Karte nennt iPhone/iPad/Mac/Watch, nicht Vision Pro. Die spezielle Vision-Anleitung N5 dokumentiert Live Speech trotzdem ausdrücklich. Auch die separaten TV-FaceTime- und Watch-Live-Listen-Untertitel dürfen nicht aus einer allgemeinen Plattformkarte ausgeschlossen werden. Listenabwesenheit und gekürzte Suche beweisen keine Nichtverfügbarkeit.

## Eigene Software und verfügbare Nachweise

- [App-Shortcut](assistant-app-shortcut.md) für iOS/iPadOS, macOS, visionOS: ausschließlich eigene Eingabe öffnen. [Echte OS-Kalt-/Warmaufrufe](assistant-os-shortcut.md) auf iPhone/iPad bereits belegt; nicht erneut als aktueller Sprachlauf ausgegeben.
- [Podcast-Quelluntertitel](podcast-source-captions.md): tatsächliche Legible-Cues/Auswahl, keine ASR oder fremden Liedtexte. WatchRoot exponiert diesen Player nicht. TV-Legible- und physische Bedienung sind nicht durch einen iPhone-Lauf mitabgenommen.
- Eigenes On-device-Capture nur iOS/iPadOS/Mac; eigener Antwort-Synthesizer nur iOS/iPadOS/Mac/Vision. Weder eine System-Diktatoberfläche noch Type to Siri, Live Speech oder RTT entstehen dadurch.
- Keine OS-Hilfsmittel aktiviert/trainiert, keine Mikrofon-/Kameraaufnahme, Konten, Anrufe, Nachrichten oder Home-Anbindung. Keine neuen Build-/UI-PASSes aus dieser Dokumentationsänderung. Die unabhängig laufende native TV-Prüfung bleibt ein eigener Beleg.

## Neue Quellen

Apple-Guide-Haupttexte am 29. Oktober 2026 mit HTTP 200, ungekürzt extrahiert und gehasht, N1–N4/N6–N8 zeigen Version 27. N5/N9 enthalten im extrahierten Haupttext keine eigene Versionswahl; keine daraus erfundene Versionsgarantie. [Abruf-/Quell-/Appcode-Digests](verification/speech-platform-update-20261029.json). Erste normale Web-Abrufe enthielten zu viel Navigation; ein Suchdienst lieferte 429. Die anschließenden Haupttext-Abrufe sind gesonderte erfolgreiche Belege.

- **N1:** [iPad RTT](https://support.apple.com/guide/ipad/set-up-and-use-rtt-ipad9ef850fd/ipados).
- **N2:** [iPhone RTT und TTY](https://support.apple.com/guide/iphone/set-up-and-use-rtt-and-tty-iph3e2e47fe/ios).
- **N3:** [Watch RTT](https://support.apple.com/guide/watch/set-up-and-use-rtt-apde82d406d1/watchos).
- **N4:** [TV Live Captions in FaceTime](https://support.apple.com/guide/tv/turn-on-live-captions-in-facetime-atvb5bca1813/tvos).
- **N5:** [Vision Pro Live Speech](https://support.apple.com/guide/apple-vision-pro/live-speech-tan9351d794e/visionos).
- **N6:** [Watch steuert Live Listen auf iPhone](https://support.apple.com/guide/watch/control-live-listen-apd4f5b634f3/watchos).
- **N7:** [TV-Bedienungshilfen-Übersicht](https://support.apple.com/guide/tv/accessibility-features-at-a-glance-atvbaeff85db/tvos).
- **N8:** [TV Type to Siri](https://support.apple.com/guide/tv/speech-atvbde2d59d3/tvos).
- **N9:** [Vision Pro Vocal Shortcuts](https://support.apple.com/guide/apple-vision-pro/use-vocal-shortcuts-tan268d29519/visionos).
- **N10:** [Apple-Accessibility-Katalog](https://www.apple.com/accessibility/features/), gekürzter Abruf, kein Negativbeweis.
