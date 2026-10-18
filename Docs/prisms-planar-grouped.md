# Planare Prismen: native Glasschicht unter scharfen Inhalten

18. Oktober 2026 · [FACE-11 / #20](https://github.com/Olli0103/homeview/issues/20) bleibt offen.

Eigene geneigte, abgeschrägte Prismenflächen ersetzen das vorherige wellige Relief.
Die sechs nativen Linsen bleiben erhalten. Ihre öffentlichen Layout-Anker werden
in einer gemeinsamen `GlassEffectContainer(spacing: 0)`-Materialschicht aufgelöst;
Texte und Bedienelemente liegen darüber und werden nicht mitgerastert.
Neue Intercom-Zeichen, Schriftkorrekturen, Nachtfilter und andere Face-Körper bleiben erhalten.

[Eigene Vorher-/Nachher-Bilder](screenshots/goal-20261018/prism-grouped-own-before-after.jpg) ·
[Quellen und Nachweise](verification/prisms-planar-grouped.json) ·
[eigene Bilder und Hashes](screenshots/goal-20261018/prism-grouped-manifest.json).
Keine privaten Referenzraster, extrahierten Konturen oder Originalshader eingebettet.

## Warum nicht nur den fehlgeschlagenen Test wiederholen?

Das ursprüngliche Fehlerpaar der **eigenen** App wurde auf unverändertem Code exakt
reproduziert: 7.256 geänderte Pixel, 7.857 Kanäle, maximal zwei RGB-Stufen. Beide
Zustände kamen auch bei Einzel-Kaltstarts vor; Parallelität allein erklärte sie nicht.
Ohne native Glasschicht blieben 64 Bilder über acht Kaltstarts exakt gleich, aber
die sichtbaren Linsen fehlten. Echter System-Reduce-Motion änderte die Glasoptik,
erzielte im einzelnen Pilot jedoch keine exakte Standbildgleichheit. Der
Simulator-Schalter wurde auf den belegten Ausgangszustand aus zurückgestellt.

Eine gemeinsame Gruppe um die **gesamten** Kachelinhalte war zwar in 64 Bildern
stabil, machte Schrift und Symbole sichtbar weicher. Deshalb wurde sie nicht
übernommen. Der Material-only-Kontrollversuch behielt dagegen alle 29.653 deckenden
Ziffernkern-Pixel exakt. Im selben Binärpaket: alte Komposition 52 Fehlerzustand-A /
12 Fehlerzustand-B mit drei Wechseln; getrennte Materialschicht 64/64 Standbilder
über acht Kaltstarts vollständig pixelgleich, bei sichtbarer Bewegung im Positivfall.
Das stützt die eigene Kompositionskorrektur, behauptet aber keine interne UIKit-Ursache.
Der alte zurückgehaltene Quellstand und seine fehlgeschlagene Prüfung bleiben historisch erhalten.

## Aktueller integrierbarer Stand

**166 Modelltests, 16 gezielte UI-Ausführungen und fünf SDK-Builds bestanden.**
Null UI-Fehler, Skips oder XCTest-Runtime-Warnungen. Die 142 Quellen und das
vollständige 19-Dateien-App-/Runner-/Testpaket blieben während der nativen Prüfung
unverändert; Quellen gegen Feature- und Integrationscommit geprüft. Modelltests
nach beiden Commits erneut. Kein neuer vollständiger UI-Suiten-PASS.

Neue strenge Regression: je Gerät vier Kaltstarts mit acht Bildern. Alle 32
Standbilder sind nicht nur im bisherigen inneren 80-Prozent-Vergleich, sondern
auch als ganze dekodierte Viewports und PNG-Dateien exakt gleich. Bewegte
Positivkontrolle verschieden; bisherige Bewegungs-, Nacht- und Touch-Assertions
unverändert. Keine RGB-Fehlertoleranz und kein Wiederholen bis Grün.

154 eigene PNGs dekodiert; 70 repräsentative Ansichten auf sechs Kontaktbögen
wirklich gesichtet. Sechs volle Nachtansichten enthalten null falsche Primärfarben.
30 Vergleichspaare aus nicht geänderten Bereichen sind pixel- und PNG-bytegleich:
Home-Rasterzustände, lokale Intercom-Zielseiten und neun weitere Atlaszustände je Gerät.
Deckende Temperatur-Ziffernkerne bleiben ebenfalls exakt erhalten. Simulatoraktionen
betätigten nur synthetische Thermostat-/Szenen-/Navigationselemente; keine Durchsage.

## Offene Abnahmen

Der direkte private Vergleich mit UI07 und der perspektivischen UI45-Aufnahme
zeigt weiter Abweichungen bei Prismenlage, Licht, Randbrechung und Zeigerdetails.
Die Bildfolge ist keine Original-Animationsrekonstruktion. Echter System-Reduce-Motion war zum Prüfzeitpunkt dieses Pakets noch offen.
Der spätere [begrenzte Systemschalter-Zusatznachweis](prisms-system-reduce-motion.md)
belegt diesen Home-Modular-Zustand auf beiden Simulatoren. Physische Leistung/Energie,
Hardware und vollständige Accessibility bleiben getrennt offen; der CLI-Testmodus
wird nicht als vollständige Systemabnahme ausgegeben.
visionOS und Macs vor Version 26 behalten den ausdrücklichen öffentlichen
Materialfallback, nicht behauptete identische Optik. Keine echte HomeKit-Verbindung.

Öffentliche Grundlage: [Apple: Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
(abgerufen 18. Oktober 2026). Die empfohlene Gruppierung ist keine Zusage pixelgenauer
Deterministik. Dieses Paket ist ein weiterer überprüfter Schritt, kein Abschluss des HomeView-Goals.
