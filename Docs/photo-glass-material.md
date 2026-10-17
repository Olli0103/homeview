# Eigenes Glasmaterial für die Foto-Uhr

Die Referenz UI04 zeigt keine deckende rosa Uhr. Der Nachbau verwendet deshalb
nun den ausgewählten Fotohintergrund auch innerhalb der Ziffern: ein eigener
öffentlicher SwiftUI-Layer-Shader leitet aus der laufzeitgerenderten Systemschrift
geglättete Maskennormalen ab, versetzt die Bildprobe leicht und ergänzt schmale
Licht-/Schattenränder. Bild und Durchsicht verwenden denselben Ausschnitt und
dieselbe Zielfläche. Es werden keine OS-Schriftkonturen gespeichert oder gebündelt.
Die Fototextur bleibt an die aktuellen ausgewählten Bytes gebunden; beim Wechsel
wird keine Textur des vorigen Fotos als neue Uhrfüllung dargestellt.

Die Anzeige verwendet getrennte Stunden-/Minutenblöcke ohne Doppelpunkt nach dem
belegten Foto-Face. Die gesprochene Accessibility-Zeit bleibt „h:mm“. Der eigene
Materialkörper und die kurze Ziffernhöhe sind keine Rekonstruktion der hohen
Originalschrift oder der vollständigen Apple-Lichtführung.

## Motivschutz bleibt getrennt

Glas ist keine Freistellung. Der bestehende Kopf-/Maskenschutz, automatische
Position und manueller Ausschnitt bleiben unverändert. Nur ein tatsächlich
verfügbarer Vordergrund darf Depth überlagern; im hier beobachteten Simulator
liefert Vision weiterhin Fehlercode 9. Das Material täuscht keinen ausgeschnittenen
Kopf vor. Der Grund für Fehlercode 9 und die Qualität auf echten Fotos/Geräten sind
nicht durch einen erfolgreichen Shaderlauf geklärt.

## Eigene Pixelkontrolle

Drei separate native Simulatoraufnahmen zeigen denselben statischen Demo-See:
ohne Uhr, mit deckender weißer Kontrollschrift und mit Glasmaterial. Eine vorher
festgelegte obere Uhrregion schließt Caption, Rundungen und Host-Chrome aus.
Weiße Innenpixel der unabhängigen Kontrollschrift bestimmen die Prüfstellen.
Mindestens 500 Stellen müssen vorliegen. Mindestens 80 Prozent der Glasstellen
müssen in jedem RGB-Kanal höchstens 45 Stufen vom tatsächlichen Fotohintergrund
abweichen; die deckende Positivkontrolle darf diese Bedingung nicht erfüllen.
Damit reicht bloße PNG-Ungleichheit oder eine andere flache Schriftfarbe nicht.

Der erste Prototyp bestand fünf gezielte UI-Fälle. 73.644 von 77.703 geprüften
Innenpixeln zeigten den Hintergrund innerhalb dieser Grenze; die deckende
Kontrollschrift null. Die tatsächliche Porträtaufnahme zeigte dennoch zu grobe
Brechungsstufen auf dem Hemd. Deshalb sind Maskenrand/Normalen geglättet und die
Verzerrung reduziert. Diese frühe Messung ist kein Nachweis für den danach
geänderten Quellstand. Erneute Material-, Bild- und vollständige Nachtprüfung
werden getrennt dokumentiert. Keine Original- oder Hardwareabnahme.

## Geglätteter Kandidat

Der getrennte Kandidat besteht vier gezielte UI-Fälle, 108 Modelltests und fünf
SDK-Builds. Vor-/Nach-Quellmanifest sind identisch. Bei unveränderter Pixelgrenze
zeigen 70.195 von 77.703 Innenpixeln den Hintergrund; die deckende Kontrolle null.
Die volle Nachtfläche hat 2.453.095 helle Prüfstellen und null unzulässige
Farbkanäle. Die tatsächliche Porträtaufnahme ist erneut gesichtet: Brechungsränder
sind nun geglättet, Kopf und Platzierungsrechtecke unverändert. Das ist noch kein
integrierter iPad-/iPhone-Nachweis und keine Originaltypografieabnahme.

## Integrierter Nachweis · 18. Oktober 2026

Feature `c3b6676`, Integration `9a26adc82aa081fcfe4ae3749f147ada7f394c2e`:
108 Modelltests, acht gezielte UI-Fälle je iPad/iPhone (16 Ausführungen) und fünf
SDK-Builds bestanden. Null UI-Fehler, Skips oder gemeldete Runtime-Warnungen.
128 Quellen vor/nach Prüfung und gegen Mergecommit identisch; nach dem
Featurecommit erneut 108 Core. Keine neue Vollsuite oder Hardwareabnahme.

| Tatsächlich geprüfte Bildpixel | iPad | iPhone |
|---|---:|---:|
| Glyphen-Innenpixel der Kontrollschrift | 77.703 | 37.076 |
| Durchsicht innerhalb unveränderter RGB-Grenze | 70.195 | 33.859 |
| Deckende Kontrollschrift: Hintergrundtreffer | 0 | 0 |
| Helle Pixel im vollen Nacht-Viewport | 2.453.095 | 1.244.921 |
| Unzulässige Nachtfarbkanäle | 0 | 0 |

Enthalten sind Material-/Positivkontrolle, Nachtfläche, tatsächliche Demo-
Porträtanalyse, Galerie-Rotation, Top-/Randmotive, dichte Maske, manuelle
Uhrposition mit Neustart/Reset sowie Ausschnitt/Reset. Die finalen Porträt-,
Galerie-, Material-, Nacht- und Ausschnittbilder beider Geräte wurden gesichtet.
Der Kopf bleibt frei; Quelle und Durchsicht passen auch im Ausschnitttest.

[Quellen und Ergebnisse](verification/photo-glass-material.json) ·
[eigene Bilder und Digests](screenshots/goal-20261017/photo-glass-manifest.json).
Native Freistellung, hohe Originalglyphen, genaue Lichtführung und physische
Lesbarkeit/Leistung bleiben getrennte offene Abnahmen.
