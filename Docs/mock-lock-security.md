# Mock-Schloss: Gerätefreigabe, separate Bestätigung und bestätigter Zustand

30. Oktober 2026 · [#25 / HOME-03](https://github.com/Olli0103/homeview/issues/25). Ursprünglicher **synthetischer Softwarevertrag**, kein betriebsbereites echtes Türschloss und keine Original-/Hardware-Parity.

Die ursprüngliche Abnahme lautet unverändert:

> Nur Mock-/Testheim-Sicherheitsfälle, kein echtes Schloss in automatischen Tests. Abgebrochene oder abgelaufene Autorisierung sendet keinen Befehl.

## Vier ursprüngliche Kriterien

| Kriterium | Umsetzung und Nachweis |
|---|---|
| Geräteauthentifizierung und explizite Bestätigung | Vorhandener öffentlicher `deviceOwnerAuthentication`-Pfad statt Demo-Profil. Jede Mock-Aktion benötigt zusätzlich einen eigenen RAM-Vorschlag mit UUID und30Sekunden monotoner Frist. Erst **Confirm Unlock/Lock** verbraucht ihn vor dem ersten Await. Native Tests prüfen echte separate Cancel-/Confirm-Callbacks. |
| Zustand, unbekannt, blockiert, Batteriefehler | Typisierte gelesene Zustände Locked/Unlocked/Unknown/Jammed, getrennte Batteriemeldung. Unbekannter Pegel bleibt unbekannt;0–100%validiert, niedriger Pegel gewarnt, expliziter Batteriefehler oder unkontrollierbarer Zustand blockiert. Native UUID-Fixtures prüfen Unknown/Jammed/Battery fault und niedrigen Pegel. |
| Hintergrund-/Profilwiderruf | Bestehender persönlicher Sitzungsgenerator, aktuelle Gerätefreigabe, tatsächlicher aktiver Lock-Viewport und interne Operationsgeneration werden vor/nach Await geprüft. Profil-/Abmeldelogik, Inaktivität/Hintergrund, Navigation, Anruf und Klingel verwerfen den Vorschlag. Corefälle prüfen späte Ergebnisse; nativer echter Hintergrund/Rückkehrfall prüft erneute Gerätefreigabe und unverändertes Mock-Schloss. |
| Keine erfolgreiche Öffnung vor Zustandsbestätigung | Vor dem Setzen frische, unveränderte Providerbeobachtung; Adapter prüft erwarteten Zustand nochmals vor atomarer lokaler Mutation. Erst passende erneute Beobachtung bestätigt das Ergebnis. Lock-Ansicht, Home-Raster und Face veröffentlichen keinen optimistischen geschriebenen Wert. Abgelehnte, widersprüchliche, verspätete oder nach dem Senden unterbrochene Ergebnisse bleiben **unverified**, ohne automatischen Retry. |

`LockActionSession` ist RAM-only und erhält keinen HomeKit-Manager. `MockLockDevice` verwendet ausschließlich den vorhandenen lokalen MockHome-Store. Direkter `command(.lock)` verweigert den alten Ein-Schritt-Pfad; Commit verlangt aktive Lock-Route, Gerätefreigabe und tatsächliche Sending-Phase. Ein echtes Schloss, Haushaltsmitglied oder Partnergerät wird weder erkannt noch angesprochen. Die echte Home-/Identitätsanbindung bleibt bei[#23](https://github.com/Olli0103/homeview/issues/23)/[#66](https://github.com/Olli0103/homeview/issues/66) gesperrt; F028 bleibt **partial/parity=false**.

Die bestehende geräteauthentifizierte Vordergrundsitzung ist Voraussetzung. Die zusätzliche kurzlebige Einmalbestätigung ist **keine Behauptung einer neuen biometrischen Authentifizierung pro Befehl**. LocalAuthentication meldet Geräteinhaberfreigabe, keinen benannten Haushaltsnutzer. Tests verwenden den eigenen Fixture-Provider und neue synthetische UUID-Stores, niemals einen realen Auth- oder Home-Provider.

## Tatsächliche Fehler und getrennte Prüfgeschichte

- Vor jeder Produktänderung scheiterte ein gezielter nativer iPhone-Fall: Nach dem ersten Unlock-Tipp stand das Mock-Schloss bereits aufUnlocked, statt separat zu bestätigen.235 Inputs gebunden; nur UI-Testdatei gegenüber dem veröffentlichten Stand verändert, alle Produktinputs unverändert. Dieser Vorherlauf enthält keinen PNG-Bildbeleg; der konkrete AX-Wert und Fehler bleiben archiviert.
- Ein später separat geschriebener externer Treiber zeigte trotz grüner früherer Tests einen weiteren echten Grenzfehler: `cancelProposal()` konnte ein bereits bestätigtes Ergebnis zu„kein Befehl gesendet“umetikettieren. Derselbe Probequelltext scheitert vor dem Pending-only-Guard und besteht danach. Verspätetes Cancel ist nun wirkungslos; ein nach bereits begonnenem Senden widerrufener Vorgang bleibt unbestätigt, nicht fälschlich folgenlos.
- Im tatsächlich archivierten alten App-Info fehlte `NSFaceIDUsageDescription`. Apples öffentliche Schlüsselbeschreibung und der SDK-Vertrag sind gebunden. Die Beschreibung ist nun in beiden Quell-Plists und tatsächlichen aktuellen App-Bundles vorhanden. **Kein physischer Face-ID-Absturz, Fallback oder Auth-Erfolg wurde beobachtet.**
- Vier frühere Großschrift-Ausführungen bleiben **Instrumentfehler**, keine umetikettierten Produktfehler: zuerst feste Fußaktionen fälschlich innerhalb der Inhalts-Scrollfläche plus40Punkte Rand verlangt; danach zusätzliche2Punkte Horizontalrand um einen exakt vollbreiten Button. Tatsächliche native Diagnose: Button340,200012 / Scroll340,2Punkte. Der korrigierte Test benutzt den vorhandenen Null-Horizontalrand für vollbreite Controls; tatsächlicher Clip, vertikaler Rand,44-Punkte-Grenzen und reale Callbacks bleiben erhalten. Ein Diagnose-PASS ist ausdrücklich keine funktionale Abnahme.

## Aktueller geprüfter Stand

**429Coretests, zwölf aktuelle native UI-Ausführungen und fünf aktuelle SDK-Builds bestanden**, plus sechs unveränderte Tooling-Tests. Externer quellgeleiteter Prüftreiber gegen den exakten committed Produktionscode: **1152Kombinationen /5775Bedingungen**, dazu die identische Terminal-Cancel-Gegenprobe. Das ist ein unabhängiger Prüftreiber, kein behaupteter zweiter menschlicher Reviewer.

Sechs native Methoden auf beiden Geräten: bestehender Gast-/Geräteauthentifizierungsfall, Vorschlag/Cancel, bestätigter Zustand mit niedriger Batterie und Neustart ohne persistierte Freigabe, echter Hintergrund, drei unverfügbare Zustände und größte Systemschrift mit Cancel→neuer Vorschlag→Confirm. Beide bestätigten Endzustände tatsächlich im sichtbaren Clip; vier große Cancel-/Confirm-Rechtecke≥44×44Punkte. Keine zusätzliche Randpunkt-/Hilfsmittelabnahme daraus.

Das tatsächlich geprüfte UI-App-Paket enthält19Dateien, der aktuelle Standard-iOS-Build22: drei SSU/NLU-Sprachmetadaten fehlen im inkrementellen UI-Build und sind im Standardpaket vorhanden. Diese bekannte Verpackungsgrenze bleibt bei#74 separat; kein neuer Siri-/OS-Shortcut-PASS. Die Face-ID-Beschreibung wurde dagegen ausdrücklich im aktuellen archivierten UI-App-Info und den SDK-Produkten zurückgelesen.

Historie insgesamt28UI-Ausführungen:23bestanden, fünf Fehler erhalten. Zu den23 gehören zehn frühere normale Fälle und eine reine Geometriediagnose; **nur die letzten zwölf zählen zur aktuellen funktionalen Abnahme**. Ein fehlgeschlagener AnyLayout-Vorbereitungsbuild hatte null UI-Ausführungen. Früher428Coretests/23gezielte Fälle werden nicht zu den aktuellen429 addiert. Zwei frühere Fünf-SDK-Wellen bleiben getrennt, kein15-SDK-Gesamt-PASS.

238 aktuelle Quellen,91 aktuelle Core-/Paket-/Testinputs, alle zwölf UI-Archive, drei getrennte SDK-Archive und aktuelle73SDK-Produkte vollständig zurückgelesen.90PNG insgesamt dekodiert, davon48aktuell; sechs aktuelle Übersichtstafeln tatsächlich gesichtet. Sieben Schriftpräferenz-Controller mit14Schreibvorgängen einschließlich Rückstellungen haben den Originalwert`large`zurückgelesen.16 unveränderte eigene native Viewportbilder veröffentlicht; gespeicherte Großschriftposen können Nicht-Zielprosa abschneiden und sind keine vollständige Satz-/Original-/Hilfsmittelabnahme.

[Quellen, Ergebnisse, Fehler und Archivbindung](verification/mock-lock-security.json) · [aktuelle238Quellinputs](verification/mock-lock-security-source.json) · [eigene native Bilder](verification/mock-lock-security-images.json).

Keine echten Schlösser, HomeKit-Einrichtung/Discovery, persönlichen Accounts, Nachrichten/Anrufe, Kamera/Mikrofon, Wiedergabe oder Systemeinstellungen außer den zurückgestellten Präferenzen der eigenen Simulatoren. Keine physische Geräteauthentifizierung, Signing-, Original-, Energie- oder Gesamt-Accessibility-Abnahme. Home-/Geräte-/Signing-Pause und Snoopy-Ausschluss bleiben unverändert.
