# Kalender im tatsächlichen OS-App-Umschalter

29. Oktober 2026 · begrenzter Nachweis zu [#67](https://github.com/Olli0103/homeview/issues/67). **Issue bleibt offen. Produkt unverändert gegenüber `449a3ea`.**

## Beobachtetes Ergebnis

Vier finale UI-Ausführungen bestehen: je Simulator der neue App-Umschalter-Fall und die vorhandene Kalender-Hintergrund-/Fresh-Unlock-Regression. Der Ausgangskalender zeigt ausschließlich „Device fixture meeting“, eine synthetische Quelle und einen eigenen UUID-Teststore.

Der neue Fall öffnet durch eine native Geste den tatsächlichen SpringBoard-Umschalter. Er verlangt `SBSwitcherWindow:Main`, `AppSwitcherContentView`, die eigene HomeView-Kartenkennung und die **vollständig sichtbare** Karte. Falls nötig wird die Karte durch eine tatsächliche horizontale OS-Geste zentriert. Kein nachgebildeter App-Umschalter und kein künstliches ScenePhase-Overlay als Ersatz für diesen Nachweis.

| Simulator / iOS 27.0 | Inaktiv, kompletter Karten-Schwarzanteil | Nach Home-Hintergrund | Sichtprüfung |
|---|---:|---:|---|
| iPhone 18 Pro | 98,27 % | 98,27 % | Schwarzer Schutz mit „HomeView locked“, kein sichtbarer Kalenderinhalt |
| iPad Air 11-inch (M4) | 99,00 % | 98,91 % | Schwarzer Schutz mit „HomeView locked“, kein sichtbarer Kalenderinhalt |

Der deklarierte Pixelguard zählt RGB unter 20 und verlangt mindestens 98 %. **Er allein ist keine Datenschutzabnahme.** Alle 16 finalen PNGs wurden dekodiert; zwei Übersichten und zwei einzelne vollständige Karten wurden tatsächlich gesichtet. Die vier HomeView-Karten zeigen keinen sichtbaren Termin, Zeitpunkt oder Kalenderdetailtext. Das rechteckige Karten-Crop enthält an den abgerundeten Außenecken etwas OS-Hintergrund; beim iPad kann die eigene App-Kennung am unteren Rand liegen. Diese Bereiche werden nicht als App-Inhalt oder als perfektes Schwarz ausgegeben. Rohbilder des OS-Umschalters, fremde App-Karten und native Bäume bleiben privat.

## Inaktiv ist nicht Hintergrund

Beim ersten Umschalter-Aufruf meldet XCTest Appzustand 4, nach echtem Home-Hintergrund Zustand 3. Die Rückkehr durch Berühren der tatsächlichen Karte darf nach bloßer Inaktivität den zuvor entsperrten Kalender erhalten. Nach Home-Hintergrund zeigt sie dagegen die gesperrte Route; beim erneuten Kalenderaufruf ist eine frische Entsperrung nötig. Erst danach erscheint die synthetische Besprechung wieder. Beide Pfade wurden je Simulator ausgeführt.

Die ersten zwei Aufnahmeversuche scheiterten an der falschen Testannahme, ein inaktiver Umschalter müsse bereits die persönliche Sitzung widerrufen haben. Zusätzlich war die iPhone-Karte nur teilweise sichtbar. Diese Fehler bleiben unter eigener Testquelle erhalten. Keine Produktänderung oder neue Fehlerursache daraus erfunden; der neue Test prüft den tatsächlichen Hintergrund separat und verschärft die Sichtbarkeit auf die ganze Karte.

## Quellenbindung und Grenzen

225 finale Quell-/Testeingaben vor und nach Ausführung unverändert. Vier ausgeführte Archive vollständig zurückgelesen, einschließlich der beiden Fehlversuche; installierte Appdateien je Lauf geprüft. Alle **19 gebauten Produktdateien** sind zum veröffentlichten Stand bytegleich. Nur der UI-Test ist neu; keine neuen Core- oder fünf SDK-Läufe daraus behauptet. Der letzte UI-Testbuild war vor der koordinierten Gateway-Wartung fertig; die finalen Ausführungen starteten erst nach ausdrücklicher Bereitschaftsmeldung.

Finaler Quelldigest: `48ab560e689cc42f62587193e9443da200c2e23e8c606eb3a8f6920a3137211c`.
Finales Eingabearchiv: `e6b7144cf2f6079440e1ec0d053ff9fe1f22ca3f14f1fe4f362220cfb135fcc5`.

[Messungen und getrennte Läufe](verification/app-switcher-calendar.json) · [beide ausgeführten Quellenvarianten](verification/app-switcher-calendar-source.json) · [eigene synthetische Appbilder](screenshots/app-switcher-calendar).

**Nur der verbundene synthetische Kalender auf den genannten Simulatoren ist hier geprüft.** Andere persönliche Routen, offene System-/App-Dialoge, echte Unterbrechungen, physische Snapshots, Geräteauthentifizierung, Präsenz und vollständige Medienpolicy bleiben getrennte Kriterien. Keine universelle oder physische Snapshot-Garantie, kein Original-Parity-PASS. F095 bleibt partial/parity=false; #67 bleibt OPEN. Geräte-/Signing-Abnahmen bleiben auf Eigentümerwunsch pausiert, Apple Home bleibt gesperrt.
