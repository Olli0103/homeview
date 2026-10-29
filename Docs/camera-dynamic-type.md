# Demo-Kamera: Systemschrift, Scrollraster und unveränderte Normalbilder

29. Oktober 2026 · Teilumfang von [#73](https://github.com/Olli0103/homeview/issues/73), weiterhin offen. Ausgangsstand `e0fc7e0e834a48fbe0cdc4b2b9c42410a9bc8ba1`. [Quellen, Ausführungen und Einzelmessungen](verification/camera-dynamic-type.json).

## Begrenzte Produktänderung

Nur `Sources/App/CameraAndCommunication.swift` ist als Produktdatei geändert; 164 andere Produkt-/Ressourceninputs bleiben gleich. Neun lokale `ScaledMetric`-Eigenschaften skalieren App-Kopfzeile, Rasterumschalter/-namen, Detailtitel/-status/-zeit und Offlinehinweis. Die Accessibility-Anordnung verwendet ein einspaltiges Scrollraster; Detailinformationen können über den festen unteren Controls scrollen. Bei normaler Schrift bleiben Anordnung und Bilder gleich.

Das Kamera-Zifferblatt behält ausdrücklich seine ursprünglichen Zeilenhöhen, Abstände und festen Bildbeschriftungen. Der sichtbare DEMO-Badge bleibt unverändert und vor Accessibility verborgen. Diese Bildbewahrung ist keine größte-Schrift-Abnahme des Faces.

Die endlichen vier/neun Accessibility-Zeilen werden vollständig bereitgestellt. Der erste Kandidat hatte auch dafür ein Lazy-Raster verwendet: Der neunte Slot war bei der unveränderten namentlichen AX-Abfrage noch nicht vorhanden. Vier große-Schrift-Ausführungen scheiterten daran. Nur die große endliche Liste wurde auf eager `VStack`/`ForEach` umgestellt; normale/Face-Raster behalten `LazyVGrid` und denselben gemeinsam genutzten Kachel-Renderer. Die ursprüngliche Zielprüfung bleibt bestehen. Die frühere Abwesenheit beweist nicht, dass ein physischer Scrollweg grundsätzlich unmöglich gewesen wäre.

Mock-Szene/Badge, Intercom, Nachrichten und Anrufoberflächen außerhalb der beiden Kamera-Views bleiben bytegleich. Der gesamte ursprüngliche Detail-Controlblock einschließlich Talkback-/Close-/Grid-Callbacks ist bytegleich. Kein Stream, Kamerazugriff, Mikrofon, Audio, HomeKit, Konto oder echte Türklingel. Talkback ändert nur lokalen Zustand und den Hinweis; das Overlay verwendet das vorhandene synthetische Türklingel-Fixture.

## Aktuelle Ergebnisse

| Prüfung | Beobachtet |
|---|---|
| Native UI | 22 akzeptierte Ausführungen, sieben Methoden auf iPhone/iPad; 16 Normal-/XXXL-Ausführungen und sechs bestehende Rand-/Nacht-Regressionen |
| Native Textausdehnung | 46/46 Bedingungen wachsen statt vorher 46×1,00; 36 Textframe- und zehn statische Status-Label-Bedingungen einschließlich Symbol |
| Höhenverhältnis | 1,986–5,639 einschließlich Umbruch; kein isolierter Fontfaktor |
| Fehlende Textknoten | Vier Umschalter-Textchild-Bedingungen bleiben mit der AX-Textframe-Methode unbewiesen, nicht als PASS aus gepolsterten Button-Bounds ersetzt |
| Separate Buchstabenmessung | Vier qualifizierte Paare „Show 9“/„Show 4“: etwa 2,72–2,91-fache Ink-Höhe, drei Schwellen je Paar; vorher überall 1,00 |
| Pixelbewahrung | 20 normale Kamera-Paare und zwei zusätzliche große eingefrorene Face-Paare exakt RGBA-gleich: null veränderte Pixel/Kanäle, keine Maske/Toleranz/Registrierung |
| SDKs/Tooling | Fünf aktuelle SDK-Builds, 73 Produktdateien bytegeprüft; sechs Tooling-Tests bestanden |
| Core | 89 Inputs wie im Ausgangsstand; 405 frühere Tests, kein neuer Core-Lauf |
| Präferenzen | Beide Simulatoren nach den Größenprüfungen wieder `large` |

Die großen Raster zeigen nicht alle neun Motive gleichzeitig. Der tatsächlich erreichte letzte Slot, Detailöffnung, Talkback ein/aus, Raster-Rückkehr, drittes Motiv und Close-Rückkehr werden getrennt geprüft. Vierzehn bestehende native Zwei-Punkte-Randaktionen verlangen weiterhin die ursprünglichen Mindestflächen und konkreten Folgezustände. Der komplette kurze Offlinehinweis wird zusätzlich innerhalb seines tatsächlichen Scrollclips nachgewiesen. Alle 46 gemessenen großen Text-/Label-Frames liegen vollständig in ihrem jeweiligen Clip; das ist keine universelle Kontrast- oder Hilfsmittelabnahme.

## Quellenbindung und erhaltene Fehler

Die fünf aktuellen SDKs und die erste finale UI-Matrix binden 233 Inputs mit Digest `62757c368c664ba4175b40a5ee9b6cff835891e4ab6787ad12d26e6c6e8a045f`. Der gelieferte Teststand `5fda816b67ab02168b37cc001fe388891ba90f71e6f37304e19d62b0cd5af9ea` unterscheidet sich ausschließlich durch die UITest-Datei: 232 andere Inputs und die kompilierten UI-App-Bytes sind exakt gleich. Testbundles unterscheiden sich. Es wird kein SDK-Neulauf nach einer reinen Testdiagnostik behauptet.

Die aktuelle Abnahme verwendet 15 erfolgreiche Ausführungen der ersten finalen Matrix, eine gezielte instrumentierte iPhone-Wiederholung und sechs Regressionen am diagnostischen Testpin. Die ursprüngliche vollständige Main-Methode ist bytegleich. Schleifenlimit, Sichtbarkeitsprädikat, Gap-/Distanzformel, Gutterkoordinaten, Eingabe und Aktions-/Rückkehrassertionen bleiben gleich. Die Diagnose ergänzt Positionen und Bilder, nicht eine schwächere Erfolgsvoraussetzung.

Ein erster iPhone-Lauf erreichte den dritten Slot nach der Raster-Rückkehr nicht in 16 Gutterdrags. Die gezielte Wiederholung erreicht ihn nach elf beobachteten Positionen; diese Spur zeigt auch nichtmonotone Zwischenpositionen. Der alte Fehllauf hat keine Schrittspur. Diagnoseabfragen/-attachments können den Beobachtungsaufwand verändern: Die ursprüngliche Ursache bleibt unbewiesen, kein Produktfix oder universell stabiler Scrollablauf wird aus dem späteren Erfolg erfunden.

Die vollständige Historie umfasst 59 UI-Ausführungen: 50 bestanden, neun frühere Fehler erhalten – vier mehrdeutige Overlay-Textselektoren, vier Lazy-AX-Zielverfügbarkeitsfehler des ersten Kandidaten und dieser eine ungeklärte iPhone-Scrollfehler. Die Vorhermatrix enthält 16 qualifizierte Erfolge bei 20 rohen Ausführungen, zusammengesetzt aus acht ausdrücklich wiederverwendeten Main-/Positivfällen und acht ergänzenden Overlay-/Ink-Fällen. Zwei Vorher-Testpins verwenden bytegleiche Produktquellen/Apps. Unbeschränktes „Front Door“ traf Overlay und darunterliegendes Face; der vorhandene Overlay-Container löst die Messung eindeutig. Keine Aussage über tatsächliche VoiceOver-Ausgabe aus dieser bloßen Hierarchieabfrage.

Fünf erfolgreiche SDKs des ersten, später korrigierten Kandidaten sind separat historisch archiviert. Ein SDK-Controller-Versuch stoppte vor jedem SDK-Prozess an einem bereits vorhandenen historischen Tooling-Log; die Korrektur verwendet einen eigenen finalen Lognamen. Kein Archiv wurde dafür überschrieben und kein gestarteter Compilerlauf verschwiegen.

## Mess- und Sichtungsgrenze

Die AX-Messung verwendet tatsächliche Textframes bzw. die ausdrücklich benannte statische Status-Label-Ausdehnung, nicht die Größe eines Buttons. Die vorhandene semantische Positivkontrolle wächst auf beiden Geräten etwa fünffach.

Der Umschalter hat keinen eigenen Textchild. Seine separate Ink-Messung ist vor Produktänderung deklariert: exakter eigener weißer Schriftzug auf unverändertem schwarzen Hintergrund, aus tatsächlichem Control-/Viewport-Frame abgeleitete ROI mit drei nativen Punkten Außenraum, nicht zusätzliches Produktpadding. Drei RGB-Schwellen (170/200/230), mindestens 100 Kernpixel, zwei Pixel Ink-Abstand und mindestens 99% schwarzer ROI-Rand müssen jeweils bestehen. Der ursprüngliche engere ROI-Entwurf ist erhalten; der unabhängige Samplingrand wurde noch vor der ersten Messung festgelegt. Keine Übertragung auf die heterogenen Fotos und keine photometrische Kontrastbehauptung.

19 UI-Archive sowie beide getrennten SDK-Archive sind mit tatsächlichen Eingaben, Installations-Read-back und unveränderten Laufinputs bytegeprüft. 266 native PNGs sind dekodiert; 29 native Kontaktbögen wurden erzeugt, davon vier tatsächlich gesichtet. Zusätzlich gesichtet: sechs adaptive Übersichten, zwei Ink-Übersichten und sechs volle Aufnahmen (zwei erster Kandidat, vier final). Vierzehn eigene Viewport-PNGs sind veröffentlicht. Normale finale Bilder werden zusätzlich über 22 exakte RGBA-Vergleiche an die tatsächlich gesichteten normalen Übersichten des ersten Kandidaten gebunden; das sind keine 22 neuen Sichtungen. Rohlogs/volle OS-Screens bleiben privat.

## Eigene Belegbilder

| Zustand | iPhone | iPad |
|---|---|---|
| Raster normal | [vorher](screenshots/camera-dynamic-type/baseline-phone-normal-grid-four.png) · [aktuell](screenshots/camera-dynamic-type/final-phone-normal-grid-four.png) | [vorher](screenshots/camera-dynamic-type/baseline-ipad-normal-grid-four.png) · [aktuell](screenshots/camera-dynamic-type/final-ipad-normal-grid-four.png) |
| Detail normal | [vorher](screenshots/camera-dynamic-type/baseline-phone-normal-front-door.png) · [aktuell](screenshots/camera-dynamic-type/final-phone-normal-front-door.png) | [vorher](screenshots/camera-dynamic-type/baseline-ipad-normal-front-door.png) · [aktuell](screenshots/camera-dynamic-type/final-ipad-normal-front-door.png) |
| Großes Scrollraster | [aktuell](screenshots/camera-dynamic-type/observed-phone-large-grid-nine.png) | [aktuell](screenshots/camera-dynamic-type/final-ipad-large-grid-nine.png) |
| Ganzer Offlinehinweis | [aktuell](screenshots/camera-dynamic-type/final-phone-large-offline-warning-visible.png) | [aktuell](screenshots/camera-dynamic-type/final-ipad-large-offline-warning-visible.png) |
| Simuliertes Overlay | [aktuell](screenshots/camera-dynamic-type/final-phone-large-doorbell.png) | [aktuell](screenshots/camera-dynamic-type/final-ipad-large-doorbell.png) |

**#73 bleibt OPEN/F103 partial.** Foto-/Offlinefarbkontrast, tatsächliche VoiceOver-/Voice-Control-/Switch-Control-/AssistiveTouch-/Zoom-Bedienung, reduzierte Bewegung, weitere Flows sowie physische/Originalabnahme sind damit nicht abgeschlossen. Reale Dienste, Home-Einrichtung und die Eigentümerpause für Geräte/Signing bleiben unverändert. Die übrige Backlog-Arbeit wird fortgesetzt.
