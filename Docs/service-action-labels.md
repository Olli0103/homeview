# Verbindungsaktionen nennen ihren Dienst

30. Oktober 2026 · Teilumfang von [#73](https://github.com/Olli0103/homeview/issues/73), weiterhin **OPEN/F103 partial**. [Quellenbindung und Einzelbelege](verification/service-action-labels.json).

## Beobachteter Fehler und begrenzter Fix

Auf iPhone und iPad melden alle vier Hauptbuttons zunächst nur „Connect Button“. Die benachbarte Überschrift nennt zwar Calendar, Reminders, Apple Music bzw. Weather; der Aktionsname allein unterscheidet die Dienste nicht. Die vorab festgelegte Prüfung scheitert auf beiden Geräten: je vier AX-Namen und vier tatsächlich gemeldete native VoiceOver-Utterances, insgesamt 16 negative Namensbedingungen.

Eine einzige zusätzliche `accessibilityLabel`-Zeile in `ConnectionControls` ergänzt den jeweiligen Dienst. Sichtbarer Connect-/Disconnect-Text, Schrift, Geometrie, Disabled-Bedingung und vollständiger ursprünglicher Aktionscode bleiben bytegleich. 164 andere Produkt-/Ressourceninputs bleiben unverändert. Die native Prüfung ist vor und nach dem Produktfix exakt dieselbe.

Die tatsächlichen aktuellen VoiceOver-Namen lauten auf beiden Simulatoren:

- Connect Calendar Button
- Connect Reminders Button
- Connect Apple Music Button
- Connect Weather Button

Alle 16 Namensbedingungen bestehen. Der neue native Lesetest verbindet **keinen** Dienst und prüft unveränderte „Not connected“-Zustände sowie lokale Rückwärts-/Vorwärts-Konsistenz. Sechs VoiceOver-Ausführungen dieser gesamten Matrix stellen ihren ursprünglichen deaktivierten Simulatorzustand wieder her und lesen ihn zurück. Die übrigen funktionalen Ausführungen ändern diese Präferenz nicht.

Die bestehende synthetische Calendar-Regression prüft außerdem den AX-Namen „Disconnect Calendar“, konkrete Randaktionen und den Zustand nach dem Trennen. Für alle vier Disconnect-Zustände wird keine native Sprachausgabe behauptet. Der zusätzliche Disconnect-Button einer **abgelehnten Anfrage** ist nicht Teil dieses Produktfixes und behält vorerst seinen bisherigen Namen.

## Aktuelle Abnahme und unveränderte Bilder

Zehn akzeptierte aktuelle UI-Ausführungen: fünf Methoden auf beiden Geräten. Neben den vier nativen Connect-Namen bestehen die bestehende Settings-Fokusprüfung, synthetische Rand-/Connect-/Disconnect-Aktionen, Ablehnung und der vollständig qualifizierte spätere Wiederverbindungsfall. Kein echter Account, HomeKit oder Geräte-Setup; bestehende Callback-Tests verwenden den synthetischen Datenprovider.

Fünf SDK-Builds, sechs Tooling-Tests und 73 byteweise zurückgelesene Produktdateien bestehen. 58 Ressourcen und 17 Provenienzinputs sind geprüft; keine Assets geändert. 89 Core-Inputs bleiben gleich, 405 frühere Core-Tests sind historisch und wurden nicht neu ausgeführt.

Vier **vollständige RGBA-Paare** sind exakt gleich: normale Settings vor VoiceOver und fokussierter Weather-Button, jeweils iPhone/iPad. Null geänderte Pixel/Kanäle, keine Maske, Toleranz oder Registrierung. Die geänderten gesprochenen Namen erfordern keine sichtbare Umgestaltung.

| Zustand | iPhone vorher / aktuell | iPad vorher / aktuell |
|---|---|---|
| Normale Settings | [vorher](screenshots/service-action-labels/baseline-phone-before-voiceover.png) · [aktuell](screenshots/service-action-labels/final-phone-before-voiceover.png) | [vorher](screenshots/service-action-labels/baseline-pad-before-voiceover.png) · [aktuell](screenshots/service-action-labels/final-pad-before-voiceover.png) |
| Nativer Weather-Fokus | [vorher](screenshots/service-action-labels/baseline-phone-focused.png) · [aktuell](screenshots/service-action-labels/final-phone-focused.png) | [vorher](screenshots/service-action-labels/baseline-pad-focused.png) · [aktuell](screenshots/service-action-labels/final-pad-focused.png) |
| Qualifizierter Anfrage-Disconnect | [sichtbarer Trefferbereich](screenshots/service-action-labels/qualified-introduction-phone-ready.png) | [sichtbarer Trefferbereich](screenshots/service-action-labels/qualified-introduction-pad-ready.png) |

## Erhaltener Wiederverbindungsbefund

Die erste aktuelle Matrix besteht mit acht von zehn Ausführungen. Beide alten Introduction-Wiederverbindungsfälle scheitern beim Vergessen einer abgelehnten Calendar-Anfrage: „Access unavailable“ bleibt statt „Disconnected“. Ein separater iPhone-Lauf mit den **ursprünglichen kompilierten App-/Testbytes** aus dem Vorherarchiv reproduziert denselben Fehler. Die neue Labelzeile ist damit nicht die alleinige Erklärung.

Eine reine iPad-Beobachtung ergänzt Geometrie und Bild vor dem unveränderten Tap. Der Button liegt vollständig unter dem tatsächlichen Scrollclip, meldet `AX_hittable=false`; dennoch besteht dieser spätere vollständige Lauf. Die ursprünglichen drei Fehler haben keine solche Vor-Tap-Spur. Beobachtungsaufwand kann Auto-Scroll/Timing beeinflussen: Die genaue ursprüngliche Ursache bleibt unbewiesen, kein Produkt-Disconnect-Fix wird erfunden.

Die endgültige Testvorbereitung verwendet deshalb den vorhandenen Gutter-Scrollhelfer und verlangt danach vollständige tatsächliche Clip-Einschließung sowie native Hittability. Zielbutton, Tap, Disconnected-Assertion, Neustart, späteres Verbinden und erneutes Trennen bleiben erhalten. Beide so qualifizierten Fälle bestehen. Der spätere reine Beobachtungserfolg ist nicht in den zehn akzeptierten aktuellen Fällen enthalten. [Exakte ursprüngliche Methoden](verification/service-action-label-probes/manifest.json) bleiben archiviert.

Gesamthistorie: **16 UI-Ausführungen, 11 PASS und fünf erhaltene FAIL**. Die Fehler sind zwei native Namens-Vorherfälle, zwei erste aktuelle Wiederverbindungsfälle und die ursprüngliche App-Gegenkontrolle. Acht vollständige Inputarchive sind bytegeprüft; die Vorher-Appgruppe und die aktuelle Appgruppe sind jeweils intern exakt gleich. 46 native PNGs sind dekodiert, alle sieben erzeugten Kontaktbögen tatsächlich gesichtet; zehn eigene Viewports sind veröffentlicht. OS-Vollbilder und Rohlogs bleiben privat.

## Gelieferte Quellen und Grenzen

SDKs und erste aktuelle UI binden 233 Inputs mit Digest `d3504100d0538501de5cefdb4b18d145ba2df12dc6c931bfbe1e4d3793038007`. Der gelieferte qualifizierte Testpin `e425cad71150b27a30af88f846f38e1c78ed8c83145799763635ef9fe4d8559a` unterscheidet sich nur in der UITest-Datei: 232 andere Inputs und alle 22 kompilierten Appdateien bleiben gleich. Kein neuer SDK-Lauf nach reiner Testbeobachtung/-vorbereitung wird behauptet. Acht bestehende Label-Erwartungen wurden dienstspezifisch präzisiert, nicht ihre Status-/Callback-Bedingungen gelockert.

Native gemeldete Sprache ist keine akustische, vollständige Flow-/Produktionsreihenfolge-, Voice-Control-/Switch-Control-/AssistiveTouch-, physische oder Originalabnahme. Der test-only Viewportmarker bleibt ausdrücklich im Strom; gewöhnliche Fixture-Einrichtung ist keine Hilfsmittelaktivierung. Geräte-/Signing-Pause, reale Home-Grenze und Snoopy-Ausschluss bleiben unverändert. Die übrige Backlog-Arbeit geht mit den tatsächlichen OS-Reduce-Motion-Einstellungen weiter.
