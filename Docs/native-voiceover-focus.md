# Native VoiceOver-Fokus und gemeldete Sprachausgabe

30. Oktober 2026 · Teilumfang von [#73](https://github.com/Olli0103/homeview/issues/73), weiterhin **OPEN/F103 partial**. [Einzelreceipts, Ausführungen und Quellenbindung](verification/native-voiceover-focus.json).

## Tatsächlicher nativer Nachweis

Die öffentliche `XCUIVoiceOverService`-API des SDK27 aktiviert VoiceOver auf den eigenen iOS27-Simulatoren. `currentSpeech`, `moveForward` und `moveBackward` liefern tatsächlich native Fokus-/Utterance-Ergebnisse. Das ist mehr als eine AX-Hierarchieabfrage, aber keine akustische Qualitätsabnahme. Längere Absätze erscheinen teilweise nur als Präfix im API-Ergebnis; vollständiges Vorlesen dieser Absätze wird nicht behauptet.

Zwölf qualifizierte Ausführungen bestehen: sechs Einstiegsansichten auf iPhone und iPad. Jede verlangt ihre vorher deklarierten gesprochenen Werte, Rückwärts/Vorwärts-Konsistenz am letzten Fokus und unveränderten UI-/Modellzustand. Die Schleife ist auf96 Vorwärtsschritte/70Sekunden beschränkt. Kein Timer wird gestartet, kein Dienst verbunden und keine Authentifizierung oder Rezeptaktion ausgelöst.

| Ansicht | Beobachteter Teilumfang | iPhone | iPad |
|---|---|---|---|
| Kamera, vier Motive | Show9 und alle vier Raumnamen, Demoquelle ausdrücklich benannt | [Bild](screenshots/native-voiceover-focus/iPhone-camera.png) | [Bild](screenshots/native-voiceover-focus/iPad-camera.png) |
| Lokale Sperransicht | Front Door, Locked, Mock lock, Authenticate Device | [Bild](screenshots/native-voiceover-focus/iPhone-lock.png) | [Bild](screenshots/native-voiceover-focus/iPad-lock.png) |
| Pausierter Timer |10:56,15MIN, Foreground timer, Resume/Delete | [Bild](screenshots/native-voiceover-focus/iPhone-timer.png) | [Bild](screenshots/native-voiceover-focus/iPad-timer.png) |
| Rezeptbibliothek | Recipes, Recent & Pinned, vorhandene Butternut Squash Soup | [Bild](screenshots/native-voiceover-focus/iPhone-recipe.png) | [Bild](screenshots/native-voiceover-focus/iPad-recipe.png) |
| Unverbundene Settings | Mock- und Systemgrenzen bis Calendar/Not connected | [Bild](screenshots/native-voiceover-focus/iPhone-settings.png) | [Bild](screenshots/native-voiceover-focus/iPad-settings.png) |
| Modular-Editor | Faces, Done, Top-left-Komplikation und Complications | [Bild](screenshots/native-voiceover-focus/iPhone-editor.png) | [Bild](screenshots/native-voiceover-focus/iPad-editor.png) |

Die Einrichtung einer Ansicht ist gewöhnliches XCTest-Routing **vor** dem nativen VoiceOver-Lesen, keine VoiceOver-Aktivierung. Der ausdrücklich test-only zugängliche Marker „HomeView Reference viewport“ bleibt im protokollierten Strom. Die Prüfung verlangt eine Wertemenge und lokale Rückkehrkonsistenz, keine vollständige Produktions-/Originalreihenfolge oder vollständige Bedienung aller Flows.

## Zwei Eingabewege bleiben nicht abgenommen

Der erste Pilot erreicht „Show9 Button“, sein eingespeister Off-target-Doppeltipp löst aber den Rastercallback nicht aus. Auch eingespeistes Control-Option-Space ändert den Rasterzustand nicht. Beide vollständigen UI-Ausführungen sind fehlgeschlagen und bleiben so erhalten. [Apples Tastaturhandbuch](https://support.apple.com/guide/iphone/use-voiceover-with-an-external-keyboard-iph6c494dc6/ios) dokumentiert VO-Space; der hier verwendete Injektions-/Modifierpfad ist dadurch nicht bewiesen.

Eine unabhängige UIKit-App mit unverändertem Standard-UIButton trennt die Ursachen: Ein normaler zielgerichteter Tipp erhöht den Buttonzähler von0 auf1. Nach nativer Aktivierung bestätigen Service **und** `UIAccessibility.isVoiceOverRunning` laufendes VoiceOver; die gemeldete Sprache fokussiert den Button. Der Off-target-Doppeltipp erhöht stattdessen den Hintergrundzähler von0 auf1, der Button bleibt1. Control-Option-Space ändert keinen Zähler. Dieser **Beobachtungstest** besteht; er ist kein erfolgreicher Roh-Touch-/Tastaturtest. Das Ergebnis widerspricht einer ausschließlich HomeView-/SwiftUI-spezifischen Ursache. Die eigentliche Ereignis-/Modifier-/Transportursache bleibt unbewiesen.

Die exakten [Explorationsquellen und SHA-Manifeste](verification/native-voiceover-input-probes/README.md) sind außerhalb des normalen Testtargets archiviert. Die normale Regression verlangt weder eine zusätzlich installierte Diagnose-App noch behält sie bekannte fehlgeschlagene Kalibrierungsexperimente als vermeintliche Akzeptanztests. Die ursprünglichen Hilfsmittelkriterien bleiben offen.

## Quellen, Fehler und Rückstellung

Alle165 Produkt-/Ressourceninputs bleiben exakt wie `d729685`; keine Produktänderung. Die Fokusmatrix bindet233 Inputs mit Digest `94305a6fcfa7982880f7b26d56f958ccb1473649280666695d6935dd50fd7035`. Zwei Rezeptfälle scheiterten an **meiner falschen Vorgabe** „Garden Tomato Pasta“: Die native Ausgabe nennt korrekt das bestehende Reset-Fixture „Butternut Squash Soup“. Kein Produktfehler. Der korrigierte Testpin `68e7ef08a8d0d7cf957b4c8811aca3d2c660617771bbb15af070769ae5b10432` ergänzt die Fixture-Vorbedingung und korrigiert nur diesen Namen.232 andere Inputs bleiben gleich; nur die beiden Rezeptfälle werden neu ausgeführt. Die ursprüngliche Testquelle und beide Fehler bleiben erhalten.

Gesamthistorie:17 native UI-Ausführungen,13 bestanden und vier fehlgeschlagen. Die13 umfassen zwölf qualifizierte Fokusfälle sowie die ausdrücklich getrennte UIKit-Beobachtung. Vier Fehler: zwei Roh-Eingabewege und zwei falsche Rezeptvorgaben. Ein früherer Compilefehler an der Swift-Whitespace-Syntax ist ebenfalls erhalten, keine UI-Ausführung.

Acht vollständige Inputarchive sind byteweise zurückgelesen. Alle22 kompilierten HomeView-Appdateien sind zwischen sämtlichen Archiven exakt gleich; Testbundles unterscheiden sich. Installierte Apps und unveränderte Laufinputs sind zurückgeprüft.26 native PNGs sind dekodiert, alle sechs erzeugten nativen Kontaktbögen tatsächlich gesichtet, zwölf eigene Viewportbilder veröffentlicht. Ein zunächst falscher PNG-Namensvergleich im Berichtgenerator scheiterte vor dem ersten Bild; korrigiert ist nur die eindeutig geprüfte Exportnamen-Zuordnung, keine Bild- oder Produktaussage.

Alle17 UI-Ausführungen stellen den ursprünglichen deaktivierten Simulator-VoiceOver-Zustand wieder her und lesen ihn zurück. Keine Host-VoiceOver-, TCC-, Konto-, Gateway- oder physische Geräteeinstellung wurde geändert. Die ursprünglichen Debugger-Lookup-/doppelten Accessibility-Loader-Warnungen bleiben in Rohlogs; die separaten `xcresult`-Warnungslisten stehen im Einzelbeleg.

Kein neuer SDK-/Core-Lauf für diese UITest-/Docs-Änderung: fünf SDKs/405Core-Tests aus dem vorherigen Produktstand sind historische, unveränderte Produktbelege, keine frisch ausgeführten Gates. Roh-Touch-/Tastaturaktivierung, akustische Qualität, andere Hilfsmittel, vollständige Flows sowie Geräte-/Originalabnahme bleiben offen. Die Backlog-Arbeit läuft weiter; der generische native „Connect Button“-Name ist der nächste gezielt zu prüfende Befund.
