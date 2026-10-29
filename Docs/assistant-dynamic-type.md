# Assistententexte an Systemschriftgröße anpassen

29. Oktober 2026 · begrenzte Korrektur zu [#73](https://github.com/Olli0103/homeview/issues/73), keine vollständige Accessibility-/Originalabnahme.

## Native Vorhermatrix statt bloßer Einstellungsmeldung

Auf den eigenen iPhone-/iPad-Simulatoren wurde die tatsächliche öffentliche `simctl ui … content_size`-Einstellung von `large` auf `accessibility-extra-extra-extra-large` geändert, jeweils vor/nach dem Lauf zurückgelesen und in `finally` auf den ursprünglichen Wert zurückgestellt. Die Tests verwenden dieselben wörtlichen lokalen Nachrichten-/On-device-Fixtures, ungesendeten Eingaben, feste Zeit und gleiche Viewport-/Scrollcontainerbreite. Keine Host-/physischen Hilfsmittel- oder Kontoeinstellungen verändert.

Der vorhandene semantische Caption-Text wächst tatsächlich: sein natives Texthöhenverhältnis beträgt 14,26 auf iPhone und 7,07 auf iPad einschließlich Umbruch. Die lokalen Antworttexte bleiben dagegen exakt gleich hoch. Eine vor jeder Produktänderung erweiterte Matrix zeigt dasselbe für Frage und Antwort im synthetischen On-device-Modus. Die bloße Bestätigung des Einstellungsbefehls wäre dafür kein Nachweis.

Zusätzlich misst das native AX-Rechteck des Done-Buttons in den Vorleseeinstellungen bei Normalschrift nur etwa 40,3 × 20,3 beziehungsweise 40,5 × 20,5 Punkte. Der mittige native Tap funktioniert bereits vorher; kein unbedienbarer Button behauptet. Bei größter Schrift ist dieses Rechteck schon vorher größer als 44 × 44. Die unabhängigen Mindestgrößenprüfungen dürfen nach erfolgreicher Navigation fortsetzen, damit tatsächliche Done-Rückkehr und Sprachstatus trotzdem geprüft werden.

Alle 165 Produkt-/Ressourceneingaben entsprachen vor den beiden reinen Testneubauten exakt `8457538`. Erste Zweimethodenmatrix: acht Ausführungen, sechs bestanden/zwei Done-Methoden fehlgeschlagen. Erweiterte Dreimethodenmatrix: zwölf Ausführungen, zehn bestanden/zwei Done-Methoden fehlgeschlagen. Sechs getrennte Textrollen-/Gerätevergleiche erfüllen die vorab festgelegte Vergrößerungsgrenze nicht; dies sind Messvergleichsergebnisse, keine zusätzlich erfundenen fehlgeschlagenen UI-Methoden.

## Zwei Produktdateien

`AssistantView` verwendet öffentliche SwiftUI-`ScaledMetric`-Werte für lokale Antwort (35 Punkte), On-device-Frage (19 Punkte) und -Antwort (24 Punkte); ihre ursprünglichen Größen bleiben bei Normalschrift erhalten. Die zugehörige ausstehende Frage nutzt dieselbe Fragenrolle. `AnswerSpeechSettingsView` legt das Minimum von 44 × 44 Punkten und eine rechteckige ContentShape innerhalb des Done-Labels fest. Keine neue Abhängigkeit, Modell-/Aktions-/Sprachfreigabe oder Änderung der Face-Renderer.

Die unveränderte erweiterte Matrix zeigt danach wachsende Texthöhen bei weiterhin positivem semantischem Kontrolltext:

| Native Texthöhe, größte/Normalkategorie | iPhone | iPad |
| --- | ---: | ---: |
| Lokale Antwort | 2,73 | 2,56 |
| On-device-Frage | 8,36 | 2,78 |
| On-device-Antwort | 9,39 | 5,61 |

Dies sind Textrechteck-Höhen mit Umbruch, **keine gemessenen reinen Schriftgrößenfaktoren**. Done misst bei Normalschrift auf beiden Geräten 44 × 44 Punkte; mittiges Öffnen/Schließen funktioniert weiterhin. Separate Außenrand-Taps oder vollständige assistive Bedienung werden daraus nicht behauptet.

Eine erste Auswertungsannahme verlangte auch ein unverändertes intrinsisches AX-Antwortrechteck in der Breite. Sie scheitert am iPhone: 307,3 → 310 Punkte, bei unverändert 378 Punkte breitem Scrollcontainer und unverändertem 34-Punkte-Seitenabstand. Das AX-Textrechteck umschließt umbrochene Zeilen, nicht den SwiftUI-Layoutwrapper. Der ursprüngliche Guardfehler bleibt dokumentiert; die qualifizierte Auswertung verlangt denselben Text, unveränderten Container/Seitenabstand und darin liegende Textrechtecke. Die vorab festgelegte Höhenvergrößerung von mindestens 1,25 und die strikte Normal-Pixelprüfung bleiben unverändert. Keine Produktänderung oder rückwirkend umdeklarierte UI-Ausführung für diese Analysekorrektur.

## Aktueller Prüfstand

**18 aktuelle UI-Ausführungen, sechs eindeutige Methoden:** zwölf Normal-/XXXL-Ausführungen (drei Methoden×zwei Kategorien×zwei Geräte) plus sechs vorhandene Normalregressionen für ausdrückliches Read/Stop/Kartenwechsel, synthetischen On-device-Dialog ohne Aktionen und drei tatsächliche App-Switcher-Sheet-Grenzen samt Entwurfserhalt. Null aktuelle Fehler/Skips/strukturierte Runtimewarnungen. Die vier normalen Antwort-Viewports sind vor/nach **vollständig RGBA-pixelgleich, null abweichende Kanäle**; zwei bereits vor der Produktänderung wiederholte Normalaufnahmen liefern ebenfalls null Unterschiede. Keine Toleranzmaske oder Aussage über Originalpixel eingeführt. Das normale Einstellungsblatt darf sich durch die bewusst vergrößerte Done-Zeile ändern.

Fünf frische SDK-Builds und sechs bestehende Tooling-Tests bestanden. 233 aktuelle Quellen, identische kompilierte aktuelle Eingaben, installierte Apps und 14 UI-Eingabearchive aller Stände geprüft/zurückgelesen. 73 SDK-Produktdateien einschließlich vollständiger iOS-Metadaten separat archiviert. 163 andere Produktinputs unverändert. 89 Core-/Package-/Core-Testeingaben bytegleich zum vorherigen 405-Test-Stand, kein neuer Core-Lauf. Gesamte UI-Geschichte: 38 Ausführungen: 34 erfolgreich/vier historische Done-Methodenfehler; keine 38er-Erfolgssuite.

118 PNGs dekodiert, 18 Übersichten und sechs volle Einzelbilder tatsächlich gesichtet; 16 eigene Bildkopien bytegeprüft. Rohe OS-/Fremdkarten der Snapshot-Regression bleiben privat.

[Quellen, Kategorien-/Rückstellbelege, Messdaten, Pixelpaare, Historie und Bildmanifeste](verification/assistant-dynamic-type.json) · [eigene synthetische Bilder](screenshots/assistant-dynamic-type). Bei größter Schrift übersteigt der Text den Scrollausschnitt; die iPhone-On-device-Aufnahme liegt durch die bestehende automatische Positionierung am Antwortende. Nicht alle Texte sind gleichzeitig sichtbar. Aus diesen Aufnahmen wird weder vollständiges Durchscrollen jedes langen Texts noch VoiceOver-Lesbarkeit abgeleitet.

**#73 bleibt OPEN, F103 partial/parity=false.** Nur diese drei Textrollen, zwei Kategorien und das gemessene Done-Rechteck sind geprüft. Andere Header-/Eingabe-/App-Flows, feste Face-Darstellung, Zoom, tatsächliche VoiceOver-/Voice-Control-/Switch-Control-/AssistiveTouch-Sitzungen, vollständiger Kontrast/Fokus und physische Geräte bleiben separat. Geräte-/Signing-Pause und Home-Sperre unverändert; keine echten Konten, Home, Aufnahme, Wiedergabe oder Nachrichten/Anrufe. Gesamtbacklog läuft weiter.
