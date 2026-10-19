# Assistent: Verfügbarkeit, Sprachen und Grenzen

19. Oktober 2026 · [AI-09, #41](https://github.com/Olli0103/homeview/issues/41).

## Was die App tatsächlich anbietet

Die Informationsansicht im Assistenten zeigt den vorhandenen lokalen Befehlsparser, nicht einen angeblich verbundenen Siri-/LLM-Dienst. Ausgewählte Timer- und Kochschrittbefehle sind Deutsch/Englisch; andere Aktionen haben nur begrenzte Schlüsselwörter. Antworten sind bislang Englisch. Das ist keine allgemeine zweisprachige Unterhaltung oder Allgemeinwissensauskunft.

Die vorhandene öffentliche Speech-Implementierung unterstützt auf iOS/macOS die Auswahl de-DE oder en-US, nur on-device und nur soweit das Gerät und seine Sprachressourcen dies zulassen. Mikrofon- und Speech-Berechtigungen werden erst beim ausdrücklichen Speak angefragt. Andere Plattformen bieten hier Texteingabe. Die Informationsansicht öffnet keine Aufnahme, startet keinen Provider und sendet keinen vorhandenen Entwurf.

Aufnahme höchstens 30 Sekunden, Transkript höchstens 1000 Zeichen. Ein Entwurf muss ausdrücklich gesendet werden. Der Timerparser akzeptiert einzelne explizite Dauern von einer Sekunde bis 24 Stunden in ganzen Sekunden und höchstens 300 Zeichen Timerauftrag. `AssistantLimits` liefert dieselben Werte an die tatsächlich begrenzenden Implementierungen und die Anzeige; die Änderung hebt keine Grenze an.

Es ist kein Cloud-KI-Anbieter, kein Cloud-Nutzungskontingent und kein KI-Abo konfiguriert. Daraus wird keine Gratiszusage und kein künftiger Preis abgeleitet. Apple Home bleibt getrennt.

## Referenzangaben sind keine eigenen Dienstzusagen

F052 bleibt eine **Referenz-/Dienstabhängigkeit**, keine abgenommene Siri-Parität. Direkt geprüft wurde der vorhandene Quellensnapshot vom **16. Oktober 2026**, nicht erneut live der aktuelle Dienst:

- P01: [Apple-Produktseite](https://www.apple.com/apple-homeview/), Veröffentlichung Oktober 2026, Snapshot 16. Oktober. Die gelesenen Angaben nennen zunächst Englisch und mögliche Nutzungslimits.
- P03: [Apple-Pressemitteilung](https://www.apple.com/newsroom/2026/10/meet-apple-homeview-a-new-way-to-enjoy-entertainment-and-manage-the-home/), datiert **13. Oktober 2026**, derselbe Snapshot. Die Fußnote nennt Beta in Software 27.2, tägliche Grenzen bestimmter serverbasierter Modelle und später kostenpflichtigen erweiterten Zugang. Sie enthält keine konkrete tägliche Zahl und keinen künftigen Preis.

Diese zeitgebundenen Referenzangaben werden nicht in unsere Sprachunterstützung, Preise oder Verfügbarkeitszusagen umgedeutet. Quelltexte und Originalmaterial bleiben im privaten Recherchebestand. Für die Informationsansicht sind vorhandene SwiftUI-/Speech-APIs ausreichend; es wird kein eigener Dienst oder SDK-Ersatz gebaut. Der eigentliche Anbieter-/Datenschutzentscheid aus #33 bleibt offen und ist keine Voraussetzung, um den jetzigen Nicht-Anschluss wahrheitsgemäß anzuzeigen.
