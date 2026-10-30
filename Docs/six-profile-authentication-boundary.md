# Sechs Demo-Profile und getrennte Gerätefreigabe

30. Oktober 2026 · ursprünglicher synthetischer Isolations-/Freigabevertrag von [#66](https://github.com/Olli0103/homeview/issues/66). Keine sechs Personen erkennende Anmeldung, Partnergeräte-Identitätsbindung oder Original-Parity.

## Geprüfte öffentliche Authentifizierungs- und Partnergrenze

Aktuell am 30. Oktober gelesene Apple-Dokumente:

- [LAContext](https://developer.apple.com/documentation/localauthentication/lacontext) evaluiert Richtlinien/Zugriffskontrollen. `evaluatePolicy` liefert Erfolg/Misserfolg und gegebenenfalls Fehler, **keinen Namen aus sechs Haushaltsprofilen**. Die App verwendet `deviceOwnerAuthentication` und prüft das Ergebnis; Demo-Auswahl ersetzt diesen Aufruf nicht.
- [deviceOwnerAuthenticationWithCompanion](https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthenticationwithcompanion) ist eine tatsächlich dokumentierte öffentliche Möglichkeit, den **Geräteinhaber** durch ein gekoppeltes Begleitgerät zu authentifizieren (iOS/iPadOS18+, macOS15+). Ohne verfügbares gekoppeltes Gerät ist `LAErrorCompanionNotAvailable` dokumentiert. Das ist nicht der Nachweis einer benannten HomeView-Haushaltsperson oder einer App-eigenen Zuordnung beliebiger persönlicher Geräte. Diese alternative Richtlinie ist hier **nicht aktiviert oder zur Laufzeit getestet**.

Beide Seiten HTTP200, vollständige Extraktion ohne Tool-Trunkierung, Abrufzeit/Extrakt-Digests im [Receipt](verification/six-profile-authentication-boundary-20261030.json). Die frühere [plattformgetrennte SDK-/Secure-Identity-Prüfung](secure-identity-boundary.md) bleibt separat: insbesondere kein nativer tvOS-Unlock. Neue native Mac-Kompilation ist keine erfolgreiche Sensor-/Companion-Authentifizierung. Keine Behauptung, damit jede zukünftige/private API untersucht zu haben.

Es wurde keine eigene Kamera-/Stimmregistrierung oder neue Pairing-/Identitätsdienst-Infrastruktur hinzugefügt. F093/F094/F096 behalten ihren dokumentierten unvollständigen/blockierten Originalumfang. Das Issue wird am ausdrücklich synthetischen Sicherheitsvertrag bewertet, nicht durch Umbenennen von Demo-Namen in erkannte Personen.

## Zustände und Auswege

| Zustand/Aktion | Tatsächliche Bedeutung |
| --- | --- |
| Alex, Jamie, Sam, Taylor, Casey, Morgan auswählen | Bewusste Auswahl fiktiver lokaler Profile. Nur deren eigene synthetische Nachrichten/Reminder und Konfiguration anzeigen; keine Geräteauthentifizierung. |
| OS-Store-Freigabe | Von Geräteauthentifizierung getrennt. Darf noch gesperrt angefragt werden, löst dort aber keinen persönlichen Datenabruf aus. |
| Persönliche Gerätequelle verbinden/lesen | Expliziter eigener Quellenpfad plus gültige Gerätefreigabe; erfolgreiche Berechtigung allein reicht nicht. Die Gerätedaten gehören zum OS-Konto, nicht zu sechs durch die App erkannten Menschen. |
| Profil wechseln, dasselbe Profil erneut wählen oder abmelden | Gerätefreigabe widerrufen, persönliche Caches leeren/Ansichten verbergen, Antwort und Entwürfe bereinigen; Generation wechseln. Lokale synthetische Datensätze nicht löschen. |
| Neustart | Kein Profil-/Authentifizierungstoken wiederhergestellt. Gespeicherte Demo-Datensätze bleiben getrennt; erneute bewusste Auswahl/Freigabe erforderlich. |
| Nicht verfügbare persönliche Geräteanmeldung | Keine angeblich erfolgreiche Companion-/Gesichtsanmeldung. Unterstützten manuellen Geräte-Unlock anbieten oder Nichtverfügbarkeit stehenlassen. |
| Lokalen App-Inhalt vor Geräteweitergabe entfernen | Vorhandenes Reset-Verfahren: eigene frische Geräteauthentifizierung, separate exakte `RESET`-Bestätigung und aktiver Kontext. Abbruch, Ablehnung/Hintergrund löschen nicht. Das entfernt weder Apple-ID/OS-Konten noch Kalender/Fotobibliothek oder deren Systemberechtigungen. Eine reale Eigentümer-/Kontenübergabe bleibt getrennte bewusste Geräteeinrichtung, hier nicht ausgeführt. |

Bewusst öffentlich freigegebene Kalenderkarten/Gast-Musik sind eine eigene [Gastpolitik](guest-policy.md), keine versteckte Haushaltsidentität. Dieser Prüfblock erteilt keine neue Freigabe und schließt die übrigen App-Umschalter-/Präsenz-/Medienkriterien von #67 nicht.

## Neue native synthetische Matrix

[Opt-in-Probe](../Tests/NativeProbes/SixProfileAuthenticationBoundary.swift) gegen **tatsächliches AppModel und DeviceConnections**, keine ersetzte Produktmethode. Nur ein Store-URL-Getter wird der externen Modellkopie hinzugefügt; neue UUID-Teststores, keine Systemalarme oder gebündelte Audioressource. Ein kompilierter nativer Treiber wird unverändert zweimal ausgeführt: erlaubte und verweigerte Fixture-Authentifizierung.

**394 Bedingungen je Ausführung, 788 insgesamt, null verletzt.** Je Ausführung alle36 geordneten Profilwechsel einschließlich der sechs Selbstwechsel. Eigene Änderungen/alle Geschwisterdatensätze, Widerruf/Cache-/Entwurfsleerung, unbekanntes Profil, Persistenz und neuer Modellstart geprüft. Positive Kontrollen müssen tatsächlich gefüllte synthetische Geräte-Caches zeigen; im verweigerten Lauf bleiben sie leer.

Zusätzlich ein gesteuerter nativer Provider: vorhandene OS-Berechtigung ohne Lesen, abgelehnte/späte Authentifizierung, Freigabe nach Sperre, verspätete Kalender-/Reminder-Erfolge und Fehler während einer neuen Anfrage. Alte Antworten dürfen weder Daten wiederherstellen noch den neuen Busy-Zustand löschen. Alle kontrollierten Continuations terminal; null Provider-Schreib-/Playbackaufrufe. Kein Systemprovider/LA-Sensor oder echtes Konto angesprochen.

245 Quell-/Test-/Ressourcen-/Buildeingaben eingefroren und nachher identisch, Digest `23a086407661ef4e47051bf1566e92afcd258b5e04c55558443f7234671ec5cc`. Gegenüber der vorherigen244er-Grenze ist ausschließlich die neue opt-in Testdatei hinzugekommen. Die bisherigen244 Eingaben bleiben bytegleich. Vorhandene native Compilerwarnungen bleiben in den Rohlogs; kein neuer Produktfix oder vollständiger Core-/Release-Gate-PASS behauptet.

## Mobile Abnahme

Die sieben bestehenden Methoden je iPhone/iPad prüfen lokale Reminder-Isolation, neue Kalender-/Reminder-Freigabe nach Gastwechsel, getrennten Assistentenverlauf, verweigerte Foto-Katalogfreigabe ohne Berechtigungs-/Katalog-/Bildlesen sowie separaten Reset/Abbruch/Hintergrund/Neustart ausschließlich eigener UUID-Fixtures.

**14 aktuelle UI-Ausführungen / sieben Methoden auf beiden Simulatoren bestanden**, null Fehler/Skips/strukturierte Runtime-Warnungen. Alle32 App-/Runner-/Test-/Launchinputs vor/nach unverändert; tatsächliche installierte App vor/nach und Runner/Tests nachher auf beiden Geräten bytegeprüft. Die vorher versiegelten Eingaben vollständig aus den bestehenden Archiven zurückgelesen und wiederverwendet, kein neuer SDK-Build und keine doppelte Eingabevollkopie pro Gerät. Native245er-Inputs mit einer37.549-Byte-Ergänzung gegen die bestehende244er-Quellablage vollständig rekonstruiert. Beide neuen Ergebnisbundles terminal gespeichert/gehasht, nicht nochmals voll kopiert. Kein neuer Core-Lauf; die früheren fünf SDKs/73Produktdateien bleiben ausdrücklich frühere Belege bei unveränderten Produktbytes.

42native PNGs vollständig dekodiert, alle26zustandsgetrennten Ansichten auf vier gebundenen Kontaktbögen tatsächlich gesichtet. Zehn eigene ausgewählte PNGs samt[Digestmanifest](screenshots/six-profile-authentication-20261030/manifest.json) veröffentlicht. Sichtbar sind erneute Freigabe statt geerbter Kalender-/Reminderansicht, unabhängige Jamie-Antwort und explizite Reset-/Ablehnungszustände. Lange Richtlinientexte zeigen je Scrollpose nur einen Ausschnitt; keine gleichzeitige vollständige Lese-/Accessibility-/Kontrast- oder physische Snapshotabnahme daraus.

Damit sind die unveränderten ursprünglichen Aufgaben von#66 im ausdrücklich synthetischen Isolations-/Freigabevertrag erfüllt. Die Geräte-/Personenerkennung bleibt in der Funktionsmatrix blockiert statt als implementiert zu verschwinden. Keine pauschale Original-/Gerätefreigabe.

Home bleibt gesperrt. Reale Sensor-/Companion-/Geräteauthentifizierung und physische Snapshot-/Eigentümerabnahmen sind nicht aus Fixture-Erfolg ableitbar; Geräte-/Signing-Pause unverändert.
