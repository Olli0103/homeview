# App-Umschalter: neun weitere Eingaberouten

29. Oktober 2026 · Teilumfang [#67](https://github.com/Olli0103/homeview/issues/67), keine vollständige Datenschutz-/Original-/Geräteabnahme.

## Unveränderte Vorher-/Nachher-Matrix

Je Route wird ein eigener synthetischer Entwurf eingegeben, der tatsächliche OS-App-Umschalter geöffnet und die vollständige HomeView-Karte geprüft. Nach Rückkehr muss der genaue Feldwert unverändert bleiben. Keine Senden-/Anrufen-/Hinzufügen-/Suchen-/Laden-Aktion in diesen neun Fällen.

| Route | iPhone vorher | iPad vorher | iPhone / iPad nachher |
|---|---|---|---|
| Demo-Nachricht | Tastaturebene sichtbar | bereits geschützt | geschützt / geschützt |
| FaceTime-Empfänger | Tastaturebene sichtbar | bereits geschützt | geschützt / geschützt |
| Demo-Intercom | Tastaturebene sichtbar | bereits geschützt | geschützt / geschützt |
| Weltuhr-Suche | Tastaturebene sichtbar | bereits geschützt | geschützt / geschützt |
| Lokale Erinnerung | Tastaturebene sichtbar | bereits geschützt | geschützt / geschützt |
| Podcast-Feed-URL | Tastaturebene sichtbar | bereits geschützt | geschützt / geschützt |
| Verbundene synthetische Musiksuche | Tastaturebene sichtbar | bereits geschützt | geschützt / geschützt |
| Wetterstadt in Einstellungen | Tastaturebene sichtbar | bereits geschützt | geschützt / geschützt |
| Lokale Browseradresse | Tastaturebene sichtbar | bereits geschützt | geschützt / geschützt |

**Enger Befund:** Auf dem iPhone waren Tastatur und generische Vorschläge über dem vorhandenen schwarzen Schutz sichtbar. Der eingegebene Sentinel-Entwurf selbst war bereits verdeckt; daraus wird kein Textleck behauptet. Alle neun iPad-Vorherfälle bestanden. Die ersten iPhone-Fälle stoppen jeweils an der Schutzprüfung; deren Rückkehr wird daher nicht als Vorher-PASS ausgegeben. Navigationsfehler bleiben fatal, jede Route ist eine eigene Testmethode.

## Korrektur und aktuelle Prüfungen

Nur der jeweilige SwiftUI-Eingabefokus wird bei Inaktivität gelöst. Vorhandene FocusStates werden wiederverwendet oder pro Ansicht ergänzt; keine globale Responder-Manipulation, kein Löschen der Entwürfe. Der Browser behält seine bestehende Stop-/Importabbruch-Policy bei. Quellenverbindungen, Berechtigungen, Sendepfade und Datenmodelle werden nicht erweitert.

- **18/18 aktuelle neue Snapshot-Ausführungen**: alle vollständigen Karten erfüllen die unveränderte Schwarzgrenze; alle neun genauen Feldwerte bleiben auf beiden Geräten erhalten.
- **16/16 bestehende Regressionen**: explizite synthetische Kommunikationsübergabe, Musik/Wetter, Zonenwahl/Entfernung, Podcastfehler/Entfernung/Hintergrundpause, Erinnerungs-CRUD, lokale Browsernavigation sowie frühere Assistenten-/verbundene Reminder-Entwürfe. Zusammen **34 aktuelle UI-Ausführungen, 17 Methoden**, null Fehler/Skips/strukturierte Laufzeitwarnungen.
- **Fünf arm64 SDK-Builds** erfolgreich. Das sind keine neuen Mac-/TV-/Watch-/Vision-Runtime-Abnahmen; eine separate native TV-Probe wird unabhängig dokumentiert.
- Alle **225 Quellen**, App-/Testbytes und sechs Ausführungsarchive vollständig zurückgelesen. Aktueller Quelldigest `c9f84685ce31a5b69fbfee5c2bdfad4baecc0de9d3034c17e9fd0c4572bc559d`; alle vier aktuellen Ausführungen nutzen identische kompilierte Eingaben, Archiv-SHA `8cd75e8c22fa360d80b14bf9c79ff31f8446d54f68fcd997658858db1cf6774f`. Installierte Appbytes jeweils geprüft. Vorher-Appdateien entsprechen dem veröffentlichten `d9ad8e3`.
- **88 Core-/Paket-/Testeingaben unverändert**, kein neuer Core-Lauf. **73 SDK-Produktdateien** archiviert und vollständig zurückgelesen. 169 PNGs dekodiert, zehn tatsächliche Übersichtsbilder gesichtet; zwölf eigene Vordergrund-/Rückkehrbilder veröffentlicht, fremde OS-Karten bleiben privat.

[Ergebnisse / Snapshots / Bilder](verification/app-switcher-root-fields.json) · [Quellenvarianten](verification/app-switcher-root-fields-source.json) · [SDK-Produkte](verification/app-switcher-root-fields-platforms.json). Private Rohbelege: `research/homeview-root-fields-20261029` auf dem externen Artefaktspeicher.

## Grenzen

Native MessageUI-Composer, Alerts/weitere Präsentationsarten, echte physische OS-Snapshots, Präsenz und vollständige Medien-/Mikrofon-/Kamerapolicy bleiben bei #67 offen. Nur synthetische persönliche Daten, MockHome und lokale Browserfixture; keine echte Nachricht, kein Anruf, keine neue Systemalarm-/Live-Activity-Aktion oder Home-Anbindung. Geräte-/Signing-Hold bleibt bestehen und pausiert nicht die übrige Softwarearbeit.
