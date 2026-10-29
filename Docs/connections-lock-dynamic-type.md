# Verbindungen und lokale Sperransichten: Systemschrift und Kontrast

29. Oktober 2026 · Teilumfang von [#73](https://github.com/Olli0103/homeview/issues/73), weiterhin offen. Ausgangsstand `fbbda1ce8621189fbf702b7d915794939ef897d5`. [Maschinenlesbare Belege](verification/connections-lock-dynamic-type.json).

## Änderung und Grenze

Settings, Verbindungs-/Freigabehinweise und die beiden lokalen Sperransichten verwenden jetzt skalierende Schriftrollen. Bei Accessibility-Schriftgrößen halten Mock-Schloss und Personal-access-Gate ihre Kopfzeile fest und scrollen den Inhalt. Die normale Anordnung bleibt bestehen. Zwölf graue Textrollen auf weißem Root-Hintergrund erhalten einen dunkleren Stil.

Nur drei Produktdateien sind geändert: `Controls.swift`, `ConnectedViews.swift`, `HomeScreens.swift`. Die übrigen 162 von 165 Produkt-/Ressourceninputs bleiben gleich. Es gibt 26 neue `ScaledMetric`-Eigenschaften; das ist nicht die Zahl der gemessenen Textrollen. Die Mock-Schloss-Command-/Berechtigungslogik und der Unlock-Taskblock sind unverändert. Auch die 112-Punkte-Schlosssymbole, Zustandsfarben und der übrige Inhalt von `HomeScreens.swift` sind unverändert. Das Assetmanifest aktualisiert lediglich diesen Quellherkunfts-Hash; keine der 58 Ressourcen und kein historischer Rechtebefund ist geändert.

Die neuen Inventuren verbinden keinen Dienst, veröffentlichen nichts und rufen den Unlock-Callback nicht auf. Ein separater bestehender Regressionstest verwendet ausdrücklich `FixtureDeviceDataProvider`: Demo-Profil allein genügt nicht, synthetische Authentifizierung allein öffnet das Mock-Schloss nicht, erst die zweite explizite Mock-Aktion tut dies. Das ist keine reale Geräteauthentifizierung oder HomeKit-Abnahme.

## Aktuelle Ergebnisse

| Prüfung | Befund |
|---|---|
| Native UI | 18 akzeptierte Ausführungen, sechs Methoden, iPhone und iPad; keine übersprungenen Tests |
| Textausdehnung | 62/62 Bedingungen, 31 tatsächliche Textrollen pro Gerät; vorher 60 Fehler und zwei bereits skalierende semantische Positivfälle |
| Ausdehnungsverhältnis | 1,697–8,438 einschließlich Umbruch; ausdrücklich kein Schriftgrößenfaktor und keine Messung gepolsterter Trefferflächen |
| Eigene Kontrastfälle | 48/48 qualifiziert, 7,005:1; vorher 44×3,261:1 und 4×4,004:1 |
| Schwarze Positivkontrollen | 16/16 mit 21:1 |
| SDKs | Fünf erfolgreiche Builds, 73 Produktdateien archiviert und zurückgelesen |
| Tooling | Sechs Tests bestanden; Backlog-/Assetprüfungen separat erhalten |
| Core | 89 Inputs exakt wie im Ausgangsstand, dort 405 Tests bestanden; kein neuer Core-Lauf behauptet |
| Gerätepräferenzen | Nach Normal-/XXXL-Prüfung auf beiden Simulatoren wieder `large` |

Die 18 aktuellen Erfolge stammen aus drei UITest-Quellständen. Der SDK-/erste UI-Stand hat Digest `cc17003b43d15da39c9a7d1eabd03e7aac0fa404c1fd1f1650bf07e00e07375a`, die erste Helferkorrektur `513d1fc66e5458418e8d7eaae1482fb2ccada8ba8d98672f8f0a26aeebf1212a`, der gelieferte Stand `40b242e63c987d4c807a703e2860b7be93c3014d9b037e3cf7f8543621db46ce`. Von 233 Inputs unterscheidet sich jeweils nur die UITest-Datei; alle Produktquellen und die kompilierten UI-App-Bytes sind gleich. Die SDK-Builds gehören zum ersten Stand, nicht zu einem erfundenen frischen Lauf nach der letzten Testkorrektur. Zwei bereits erfolgreiche größte semantische Positivfälle werden ausdrücklich wiederverwendet.

## Bild- und Messvertrag

Kontrast wird nur im tatsächlichen weißen Root gemessen: Textframe ∩ tatsächlicher Scrollclip ∩ Viewport, deklarierter Rand und Nachbarausschluss, mindestens 100 tatsächliche dunkle Kernpixel, Schwelle 4,5:1. Der größte zusammenhängende weiße Bereich mit gefüllten eingeschlossenen Löchern schließt die schwarze gerundete Außenfläche aus. Am Außenrand angeschnittene, mit Schwarz verbundene Glyphenteile sind nicht allgemein als erhalten garantiert; die deklarierten Messkerne liegen im qualifizierten Inneren. Farbprofil/PNG-sRGB und Masken sind protokolliert. Keine Übertragung auf Glas, Fotos, alle Antialiasing-Pixel oder physische Photometrie.

Lange Absätze sind lesbare Scrollausschnitte. Die gezielte iPhone-Prüfung erreicht den Anfang eines deklarierten 64-Punkte-Ausschnitts; sie behauptet nicht, dass ein ganzer Absatz gleichzeitig passt. Vollständige Unlock-Control-Sichtbarkeit und funktionale Kontrollprüfungen bleiben getrennt. Funktionale Mittelpunktaktionen sind keine neue 44-Punkte-Rand-/Hilfsmittelabnahme.

Von 46 normalen Bildpaaren haben 22 exakt gleiche Messposen: außerhalb der zwölf deklarierten Farbregionen null veränderte Pixel; vier ganze RGBA-Bilder sind gleich. Die anderen 24 Paare bleiben wegen verschiedener Scrollpositionen pixel-unqualifiziert. Bei 22 sind alle vorher sichtbaren gematchten Texte einheitlich vertikal verschoben, mit gleicher relativer Geometrie und festen Kopfzeilen. Bei zwei Paaren gilt dies nur für gemeinsame Nodes: drei frühere Viewport-Nodes fehlen im später auf sichtbare Nachbarn begrenzten AX-Satz; ihre ursprünglichen Frames werden nicht erfunden. Keine Bildregistrierung und keine Produktverschiebung zum Erzeugen eines PASS.

Eine anfängliche 0,5-Punkte-Pose-Toleranz hatte vier subpixelverschobene Paare fälschlich zugelassen (53.726 Außenpixel). Dieser Originalbefund bleibt erhalten. Die getrennte strengere Auswertung verlangt 0,01 Punkte, ohne Bilder oder Produkt erneut zu verändern.

## Erhaltene Versuche und Archive

25 UI-Archive mit kompilierten Eingaben, Installations-Read-back und unveränderten Laufinputs sowie das SDK-Archiv sind bytegeprüft. 554 native PNGs sind tatsächlich dekodiert; 61 native Kontaktbögen wurden erzeugt, nicht pauschal alle gesichtet. Tatsächlich gesichtet: sechs native Kontaktbögen, 16 adaptive Übersichten/Teilübersichten, vier volle aktuelle große Aufnahmen, acht Kontrast-Paarbögen (alle 48 eigenen Vorher-/Nachher-Paare) und zwei Oberflächenmasken. Zwei zunächst verlorene große Übersichtsausgaben zählen nicht als Sichtung; neue Teilübersichten sind separat geprüft. 24 eigene Viewport-PNGs sind veröffentlicht; private Logs und vollständige OS-Screens bleiben privat.

Die Historie enthält 51 rohe XCTest-Versuche: 38 erfolgreich, 13 fehlgeschlagen. Davon sind elf abgeschlossene Instrumentfehler und zwei kontrolliert gestoppte Versuche mit bereits bekannter ungültiger Rückkehrroute; keine 13 Produktfehler. Nach der Produktänderung: 23 Ausführungen, davon 18 akzeptiert und fünf erhaltene Instrumentfehler:

- Vier aktuelle Fehler verlangten einen positiven horizontalen Innenabstand für eine absichtlich volle Scrollbreite. Der Test korrigiert nur diese expliziten Lock-/Gate-Ziele auf null horizontalen Zusatzrand; vertikaler Abstand, tatsächlicher Clip, Enabled-/Callback-/Rückkehrbedingungen bleiben bestehen.
- Ein iPhone-Absatz pendelte beim Scrollen um die verlangte Vollframe-Pose. Der separate deklarierte Anfangsausschnitt prüft die tatsächlich beabsichtigte Lesepose, ohne Kontrollinteraktionsprüfungen zu lockern.
- Frühere lange XCTest-Stringsubscripts überschritten das 128-Zeichen-Limit; exakte Label-Prädikate ersetzen sie. Eine frühere Rückkehrhilfe verwechselte bereits sichtbaren persönlichen Home Screen und App-Raster. Beide Originalfehler bleiben dokumentiert.

## Eigene Bildbelege

| Pose | iPhone vorher / aktuell | iPad vorher / aktuell |
|---|---|---|
| Settings normal | [vorher](screenshots/connections-lock-dynamic-type/baseline3-phone-normal-settings-top.png) · [aktuell](screenshots/connections-lock-dynamic-type/current-phone-normal-settings-top.png) | [vorher](screenshots/connections-lock-dynamic-type/baseline3-ipad-normal-settings-top.png) · [aktuell](screenshots/connections-lock-dynamic-type/current-ipad-normal-settings-top.png) |
| Mock-Schloss normal | [vorher](screenshots/connections-lock-dynamic-type/baseline3-phone-normal-lock.png) · [aktuell](screenshots/connections-lock-dynamic-type/current-phone-normal-lock.png) | [vorher](screenshots/connections-lock-dynamic-type/baseline3-ipad-normal-lock.png) · [aktuell](screenshots/connections-lock-dynamic-type/current-ipad-normal-lock.png) |
| Große Systemschrift | [Settings](screenshots/connections-lock-dynamic-type/corrected-phone-large-settings-top.png) · [ganzer Unlock-Button](screenshots/connections-lock-dynamic-type/corrected-phone-large-unlock-control-visible.png) · [Schlosshinweis](screenshots/connections-lock-dynamic-type/excerpt-phone-large-lock-policy-visible.png) | [Settings](screenshots/connections-lock-dynamic-type/corrected-ipad-large-settings-top.png) · [ganzer Unlock-Button](screenshots/connections-lock-dynamic-type/corrected-ipad-large-unlock-control-visible.png) · [Schlosshinweis](screenshots/connections-lock-dynamic-type/corrected-ipad-large-lock-policy-visible.png) |

#73/F103 bleibt für weitere Flows, tatsächliche Hilfsmittel und Geräte offen. Keine realen Konten, Home-Geräte, Kamera-/Mikrofon-/Audio-, Nachrichten-/Anruf-, neuen Alarm-/Live-Activity- oder physischen/Signing-Abnahmen. Die bestehende Eigentümerpause bleibt bestehen; die übrige Backlog-Arbeit läuft weiter.
