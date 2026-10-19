# Benanntes Control für den ruhenden Timer

19. Oktober 2026 · Teilkorrektur von [#73 / SYS-10](https://github.com/Olli0103/homeview/issues/73). **Keine vollständige Abnahme von VoiceOver oder anderen Hilfsmitteln. Issue bleibt offen.**

## Änderung

Nach dem Ausblenden der Timersteuerung gab es bisher nur einen unbenannten Flächentipp. Die neuen gezielten UI-Fälle scheitern gegen den unveränderten Produktstand `3069ff7` auf iPad und iPhone am fehlenden benannten Accessibility-Control; Countdown und ausgeblendete Steuerung waren dabei korrekt.

`9ce13b5` ergänzt einen regulären SwiftUI-Button **„Show timer controls“** mit aktuellem Countdown als Accessibility-Wert und einem Hinweis auf Pause/Fortsetzen/Löschen. Er liegt nur im ausgeblendeten Zustand über der bisherigen Tippfläche. Sein transparenter Inhalt zeichnet keine neue sichtbare Oberfläche. Countdown und vorhandene Identifier bleiben erhalten; sichtbare Steuerelemente werden nicht überlagert. Button und bisheriger Flächentipp verwenden dieselbe Aktion zum Einblenden und Zurücksetzen der Interaktionsfrist.

Das ist ein ausdrücklich benanntes Software-Control statt einer ausschließlich anonymen Geste. Es ist **kein** Nachweis einer vollständig bedienbaren VoiceOver-, Voice-Control-, Switch-Control- oder AssistiveTouch-Sitzung und keine neue Behauptung über deren Fokusverhalten.

## Quellengebundene Prüfung

| Lane | Beobachtung |
| --- | --- |
| Baseline `18acc63`, Produkt unverändert `3069ff7` | ein neuer Fall je Gerät, beide scheitern am fehlenden benannten Button |
| Final `9ce13b5` | derselbe Fall sowie die vorhandenen realen Idle-/Touch-Tests, drei Fälle je Gerät: sechs erfolgreiche Ausführungen |
| Wert/Aktion | benannter Button mit „10:56“; Aktivierung zeigt Resume/Delete; Löschen führt zur Einrichtung |
| Bisheriges Verhalten | tatsächliche Vier-Sekunden-Ausblendung, erneuter Touch setzt Frist zurück; laufender Timer zählt verborgen weiter und pausiert nach Touch |
| SDKs | iOS, macOS, tvOS, visionOS und watchOS gebaut; Watch verwendet seine separate WatchRoot, nicht diesen TimerView |
| Statisches Bild | ganze eingefrorene ruhende Viewports: iPad 1592×1592, iPhone 1134×1134; auf beiden **null veränderte RGB-Pixel und Kanäle**, ohne Maske/Toleranz. Auch die PNG-Digests sind jeweils gleich |

Die Bildmessung gilt nur für diese pausierte 10:56-Referenz, nicht für ein Originalgerät, andere Zustände oder eine aktive Hilfsmitteldarstellung. 197 Eingaben pro Checkpoint, 26 kompilierte App-/Widget-/Test-/Launch-Eingaben und installierte Appbytes sind gebunden und unverändert. Insgesamt acht UI-Ausführungen: sechs erfolgreich, zwei historische Baselinefehler, keine Skips oder Runtime-Warnungen. 36 PNGs dekodiert; vier Kontaktübersichten und die beiden eingeblendeten Steuerungs-Viewports gesichtet. [Zehn ausgewählte eigene Bilder und Digests](verification/accessible-timer.json).

Core und Coretests sind unverändert. Die 291 früheren Modelltests bei `5f12a7f` bleiben historische Ergebnisse mit 68 bytegleichen Core-/Coretest-Dateien; kein neuer Core-Lauf wird daraus gemacht. Kein reales Konto, Kamera-, Mikrofon-, Alarm- oder Home-Zugriff und keine neue System-Live-Activity in diesen Tests.

## Begrenzte native AX-Vorbereitung

Eine getrennte, eigene offscreen AppKit-/NSHostingView-Probe kompilierte, erreichte mit ihrem gewählten `NSAccessibilityProtocol`-Traversal jedoch nur den Root-AXGroup-Knoten und brach nach fünf Sekunden ab. **Null Assertions und kein `accessibilityPerformPress` ausgeführt.** Die Ursache dieser Vorbereitungsgrenze ist nicht bestimmt; sie sagt weder, was ein echter Accessibility-Client sehen würde, noch belegt sie einen Timer-Produktfehler. Es wurden keine macOS-Hilfsmittel oder Berechtigungen eingeschaltet. Diese Lane wird nicht als bestanden bezeichnet.

[Gesamtbericht](verification/accessible-timer.json) · [statische Bildmessung](verification/accessible-timer-pixels.json) · [AX-Vorbereitungsgrenze](verification/accessible-timer-native-preparation.json). Die beiden UI-Archive und das native Vorbereitungsarchiv wurden vollständig byteweise zurückgelesen; Inventare stehen im Bericht. Rohlogs, private Originalreferenzen und SDK-Header werden nicht veröffentlicht.

Die übrigen Kriterien bleiben unverändert offen: tatsächliche Hilfsmittel, Fokus/Reihenfolge/Ansagen, Zoom/Dynamic Type, Kontrast und die weiteren zentralen Flows. Keine Original-/Hardwaregleichheit und **keine Home-Anbindung**.
