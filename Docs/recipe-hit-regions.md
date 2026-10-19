# Rezept- und Kochsteuerung: native Trefferflächen

20. Oktober 2026 · Teilfix für [#73](https://github.com/Olli0103/homeview/issues/73), Produktcommit `4c932da`. Das umfassende Issue bleibt offen.

## Reproduktion und Korrektur

Der öffentliche XCTest-Audit `.hitRegion` wird getrennt auf Rezeptcover, Zutatenliste und Kochschritt ausgeführt. Jeder Befund wird gesammelt und unverändert gespeichert; anschließend muss die gesamte Liste leer sein. Keine Ausnahmen oder ausgefilterten Controls.

Vorher meldete der iPhone-Simulator sechs etwa 18 Punkte hohe Zutaten-Buttons sowie zwei zu kleine Kochaktionen: Handoff (139,44 × 13,65 Punkte) und Timer (150,15 × 16,8 Punkte). Beide Simulatoren meldeten außerdem die winzige, passive Fortschrittsanzeige. Das Cover bestand schon vorher; dessen Controls wurden nicht geändert.

Die Zutatenzeilen und die beiden Kochaktionen erhalten jetzt mindestens 44 native Punkte Höhe. Die tatsächliche Referenz-Canvas-Skalierung wird über die Umgebung übergeben; `ceil(44 / scale)` verhindert ein Unterschreiten durch Layout-Rundung. Die Zutatenliste wird dadurch auf dem iPhone länger und bleibt scrollbar. Der Checked-/Unchecked-Zustand ist zugänglich. Die dekorativen Punkte werden als nicht interaktive Canvas-Zeichnung dargestellt; der vollständige Fortschritt „Step N of M“ gehört zum vorhandenen Schritttext. Keine Information entfällt.

Der erste Kandidat scheiterte noch: gemessene Höhen von 43,78/43,89 Punkten und ein leerer kleiner Accessibility-Knoten trotz `accessibilityHidden`. Diese vier Fehler bleiben dokumentiert. Die Korrektur rundet die Canvas-Höhe nach oben und ersetzt die Punkt-Viewgruppe durch die Zeichnung. Die Frame-Assertion bleibt unverändert (nur 1e−6 Punkt numerische Toleranz); der öffentliche Audit wird nicht gelockert.

## Gegenprüfung

| Prüfung | Ergebnis |
| --- | --- |
| Drei vollständige Flächen-Audits je Gerät | alle sechs Befundlisten leer |
| Erste Zutat | oberer Rand schaltet ein, unterer Rand wieder aus |
| Letzte Zutat | vollständig ins Scrollfenster gebracht, unterer Rand schaltet ein |
| Kochaktionen | Flächen mindestens 44 Punkte hoch, keine gegenseitige Überschneidung |
| Timer-Rand | startet tatsächlich einen eigenen lokalen Fünf-Minuten-Timer; Liste zeigt Schritt 1, Vordergrundstatus und positiven Countdown bis maximal 300 Sekunden |
| Handoff-Rand | öffnet den eigenen Angebotsdialog; kein Angebot abgesendet, keine tatsächliche Übergabe |
| Fortschritt | vorhandener zugänglicher Text aktualisiert sich von „Step 1 of 3“ auf „Step 2 of 3“ |
| SDKs | iOS, macOS, tvOS, visionOS und watchOS gebaut; Watch nutzt seine separate Oberfläche |
| Rezeptcover | ganzer Referenzviewport unverändert: iPad 1592 × 1592, iPhone 1134 × 1134; null andere RGB-Pixel/Kanäle und identische PNGbytes, ohne Maske/Toleranz |

Final acht UI-Ausführungen bestanden, vier Fälle je Gerät. Gesamte Historie: 22 Ausführungen, 15 erfolgreich und sieben dokumentierte frühere Fehler; keine Skips oder Runtime-Warnungen. 200 Quelldateien, je 28 kompilierte Eingaben und die installierten Appbytes sind gebunden. Drei externe Archive vollständig zurückgelesen. 50 PNGs dekodiert, sechs Übersichten gesichtet; 18 ausgewählte eigene Bilder im [Messbericht](verification/cooking-hit-regions.json). Die Bilder bestätigen lesbaren Schritttext und die scrollbar vergrößerten Zutatenzeilen. Für Zutaten-/Kochlayout wird ausdrücklich keine Pixelgleichheit behauptet.

70 Core-/Coretest-Dateien bytegleich zum früheren Lauf mit 297 erfolgreichen Modelltests bei `6c69a68`. Kein neuer Core-Lauf für diese UI-Änderung. Keine neuen Abhängigkeiten oder Dienstanbindungen.

## Grenzen

Dies ist keine tatsächliche VoiceOver-, Voice-Control-, Switch-Control-, AssistiveTouch-, Zoom-, Dynamic-Type- oder Kontrastabnahme. Fokus, Ansagen, Originaltreue und physische Geräte bleiben offen. Andere Ansichten und der geöffnete Handoff-Dialog sind nicht Teil dieser drei Audits. Keine reale Zwei-Geräte-Übergabe behauptet. Ursprüngliche Kriterien und F103 ohne Parity bleiben unverändert.

Nur synthetische eigene Rezept-/Timerdaten. Keine echten Konten, Kamera, Mikrofon, Systemalarme oder neuen System-Live-Activities. **Keine Home-Anbindung.**
