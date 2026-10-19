# 44-Punkte-Trefferflächen für die Footer-Navigation

20. Oktober 2026 · Teilkorrektur von [#73](https://github.com/Olli0103/homeview/issues/73). Das umfassende Accessibility-Issue bleibt offen.

## Fehler und Korrektur

Der öffentliche XCTest-Accessibility-Audit `.hitRegion` meldet im sichtbaren Timerzustand auf iPad und iPhone vier zu kleine Trefferflächen: **Faces, Apps, Assistant und Control Center**. Ihre gemessenen Flächen lagen bei etwa 17–22 × 17–19 Punkten. Der vollständige Sammellauf behält jeden Befund und verlangt anschließend eine leere, ungefilterte Liste; es werden keine Controls ausgenommen.

Produktcommit `e6a7c54` gibt den vier Footer-Symbolen native **44 × 44 Punkte** große Frames mit rechteckiger Trefferfläche. Der Abstand beträgt acht Punkte, die Flächen überlappen nicht. Der äußere Layout-Slot bleibt 30 Punkte hoch: Die zentrale Appfläche wird nicht verschoben oder verkleinert. Symbolgröße, Timer-Zeichnung und Core bleiben unverändert. Die Footer-Symbolpositionen ändern sich geringfügig; eine unveränderte gesamte Bildschirmaufnahme wird nicht behauptet.

## Gegenprüfung

| Prüfung | Ergebnis |
| --- | --- |
| Vollständiger öffentlicher Flächen-Audit | keine Befunde auf beiden Simulatoren |
| Geometrie | vier 44 × 44-Punkte-Flächen, paarweise ohne Überschneidung |
| Tatsächliche Rand-Taps | oben auf Control Center und Faces, rechts auf Apps, unten auf Assistant; jeweiliges eindeutiges Ziel erreicht |
| Überlauf über den Layout-Slot | obere/untere Taps liegen außerhalb des beibehaltenen 30-Punkte-Slots und funktionieren |
| Ganze eingefrorene Timerfläche | iPad 1592 × 1592, iPhone 1134 × 1134: null veränderte RGB-Pixel oder Kanäle, ohne Maske/Toleranz; auch PNGbytes identisch; Position und Größe im vollständigen Screen zusätzlich byteweise zugeordnet und identisch |
| SDKs | iOS, macOS, tvOS, visionOS und watchOS gebaut; Watch verwendet seine separate Oberfläche |

Die finalen vier UI-Ausführungen bestehen: zwei Fälle je Gerät. Frühere Fehlläufe bleiben erhalten: zwei anfängliche Auditfehler, zwei vollständige Auditfehler mit jeweils allen vier Footer-Befunden sowie zwei iPhone-Geometriemessfehler vor den Rand-Aktionen. Letztere kamen von konvertierten Gleitkomma-Frames knapp unter 44 Punkten. Ein einzelner darstellbarer Zahlenschritt genügte nicht; der endgültige Test verlangt Gleichheit zu 44 mit nur einem milliardstel Punkt numerischer Toleranz. Der automatische Audit und sämtliche Rand-/Ziel-/Überschneidungsassertionen wurden nicht gelockert.

Insgesamt 16 UI-Ausführungen: zehn bestanden, sechs historische Fehler, keine Skips oder Runtime-Warnungen. Fünf SDKs wurden am unveränderten Produktcode gebaut; die beiden späteren Commits ändern ausschließlich die Testmessung. 197 Quelldateien, je 26 kompilierte App-/Widget-/Test-/Launch-Eingaben und installierte Appbytes sind gebunden. Fünf externe Archive vollständig zurückgelesen. 28 PNGs dekodiert, zehn Kontaktübersichten gesichtet; zehn ausgewählte eigene Bilder im [Messbericht](verification/timer-hit-regions.json).

Core und Coretests bleiben bytegleich: 291 frühere Modelltests bei `5f12a7f`, 68 unveränderte Dateien. Das ist kein neuer Core-Lauf. Die statische Pixelmessung gilt ausschließlich für den pausierten 10:56-Referenzzustand. Sie ist keine Original-/Hardwareabnahme.

## Weiter offen

Andere Ansichten und verborgene Zustände sind durch diesen Audit nicht abgedeckt. Tatsächliche VoiceOver-, Voice-Control-, Switch-Control-, AssistiveTouch- und Zoom-Sitzungen, Fokus/Reihenfolge/Ansagen, Dynamic Type/Kontrast und physische Geräte bleiben gesondert offen. Keine realen Konten, Kamera, Mikrofon, Systemalarme oder neuen System-Live-Activities genutzt. **Keine Home-Anbindung.**
