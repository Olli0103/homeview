# Persönliches Apps-/Wetterraster und Gesten

17. Oktober 2026 · #9 bleibt offen.

Das dritte profilgebundene Preset ergänzt den sichtbaren Aufbau aus der UI41-Sequenz.
Die Quelle ist eine gescrollte persönliche Ansicht, kein Beleg für eine vollständige
Neugestaltung der globalen App-Übersicht: vor dem Scrollen stehen links Music/Podcasts
und Safari/FaceTime, rechts die Wetterkarte über beide Reihen; darunter folgen die
vier App-Spalten. Der globale AppDrawer bleibt unverändert. Reihenfolge und Layout
bleiben pro Demo-Profil gespeichert. Der Editor zeigt drei auswählbare Presets.

Die Wetterkarte verwendet denselben quellenmarkierten Cache wie die Wetter-App.
Fehlende oder fehlgeschlagene verbundene Werte werden nicht durch die Referenz-Demo
ersetzt. Explizite Demo bleibt gekennzeichnet; die Karte öffnet die eigenständige
Wetter-App. Die Musikansichten verwenden ein eigenes prozedurales Demo-Cover, keine
fremden Albumdaten und keinen Plus-Platzhalter.

## Reale Gestenfehler im Simulator

Der erste iPad-Lauf bestand; auf dem iPhone wurde ein normaler Inhaltsswipe als
Home-Geste fehlgedeutet. Die Messung zeigte Start y315 bei dargestellter Kante378:
der bisherige untere17%-Bereich war zu breit, nicht die Skalierung falsch.
Ein enger Bereich allein reichte nicht: Elternansicht und unterer Streifen waren
doppelt zuständig. Jetzt besitzt jede Route genau einen unteren Handler. Der
persönliche Scrollinhalt wird nicht mehr zu einer globalen Navigation umgedeutet.

Die neue Prüfung echter oberer Rand-Swipes zeigte außerdem eine Zielüberschreibung:
die Geste wurde erkannt, anschließend öffnete der darunterliegende Kamera-Button
sein Detail. Face-Drags haben jetzt Vorrang vor solchen Button-Taps; persönliche
Inhalte behalten ihren normalen Scrollpfad. Die Tests verlangen nach echten
Bildschirmkoordinaten-Swipes die tatsächlichen Ziele, nicht nur AX-Hittable oder
numerische Schwellwerte. Diese Gestengrenzen sind unsere Bedienungsanpassung,
keine als vermessen ausgegebenen Apple-Parameter. Frühere Fehlläufe bleiben als
private Diagnose erhalten und werden nicht zu PASS umetikettiert.

## Noch offen

Genaue originale Widgetgrafiken, Fotos, alle Layoutvarianten/Übergänge und
Lichtdetails sowie echte Mehrnutzeridentität, Accounts und physische Abnahme
bleiben offen. Keine neue Home- oder Kontofreigabe. Kein Abschluss des Gesamtgoals.

## Integrierter Nachweis

`754890a`, zusammengeführt mit Fade in `5efd09f`: 104 Modelltests, elf gezielte
UI-Fälle je iPad/iPhone (22 Ausführungen) und fünf SDK-Builds bestanden. Null
UI-Fehler/Skips oder von XCTest gemeldete Runtime-Warnungen. 116 Quellen vor/nach
Prüfung und gegen den Mergecommit identisch. Nach dem Featurecommit erneut
104 Modelltests; die Integration wurde nach ihrem Mergecommit geprüft.

Die Auswahl umfasst Wetterraster/Scroll/Unavailable, Medienlayouts mit Neustart
und Profiltrennung, explizite Wiedergabe/Navigation, Standardpersonalansicht,
Face-Editor, vier tatsächliche Randgestenziele, Fade-Phasen/Reduce Motion und
alternative Home-Uhr/Thermostat. Keine neue vollständige UI-Suite. Eigene Bilder
beider Größen gesichtet. Im Medienpreset ist die Artist-Zeile anfangs noch teilweise
abgeschnitten; diese sichtbare Layoutabweichung wird als Folgeschritt korrigiert,
nicht durch den funktionalen PASS als erledigt erklärt.

[Quellen und Ergebnisse](verification/layouts-fade-integrated.json) ·
[eigene Bilder und Digests](screenshots/goal-20261017/weather-grid-manifest.json).
