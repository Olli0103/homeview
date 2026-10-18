# Gemeinsamer Lauf aller vorhandenen synthetischen UI-Fälle

18. Oktober 2026. Quellenstand und App-/Testbundle werden vor dem Lauf eingefroren
und nach seinem Ende erneut geprüft. Dieser Nachweis wird erst mit terminalen
nativen Ergebnissen abgeschlossen, nicht mit vorläufigen Logzählern.

Die native Enumeration enthält 138 Fälle. 134 je iPad/iPhone sind aktiviert;
268 Gerätefälle sind geplant. Vier reale AlarmKit-Simulatorfälle sind bewusst
nicht Teil dieser Auswahl. Sie zählen weder als bestanden noch als übersprungen.
Dies ist der gesamte vorhandene synthetische Bestand, nicht die vollständige
Suite aller nativen Integrationen, eine Original- oder eine Hardwareabnahme.

Alle Starts tragen --uitesting. Persönliche Daten und Alben verwenden Fixture-
Provider; Sprachtests öffnen kein Mikrofon, der Mock-Spiegel keine Kamera.
Nachrichten-/FaceTime-Systemübergaben werden im Testmodus vor der Übergabe
abgebrochen. Browserfälle verwenden lokales HTML oder den Test-URL-Handler;
der einzige eingegebene Browser-Netzwerktext ist eine abzuweisende HTTP-Adresse.
HomeKit bleibt vollständig gesperrt. Speicherfälle verwenden neue eigene UUID-
Testordner, sonst flüchtigen Zustand; keine vorhandenen Benutzerdateien.

Die Modell- und fünf SDK-Ergebnisse des identischen Digest gehören zum zuvor
veröffentlichten Analog-Nachweis; keine weiteren fünf SDK-Builds werden allein
für diesen unveränderten Lauf behauptet. Frühere Teilsuiten werden nicht zu den
aktuellen Zählern addiert. Terminale Fehler, Skips, Runtime-Warnungen, tatsächliche
eigene Bildaufnahmen und fehlende Bildzustände werden getrennt ergänzt.

Die ausstehenden Original-/Geräte-/Livekonto-Gates und der zurückgehaltene
Prismen-Bewegungsprototyp bleiben unverändert. Keine neue QA-01-Schließung.

## Terminales Ergebnis und Bildgrenze

**268 bestanden**, je 134 pro Gerät; null Fehler, Skips und von XCTest gemeldete
Runtime-Warnungen. Quellenmanifest mit 142 Dateien sowie sechs eingefrorene
App-/Testbundle-/Auswahlartefakte nach Laufende unverändert.

724 eigene PNGs dekodiert; 242 repräsentative Aufnahmen tatsächlich über
28 Kontaktbögen gesichtet. Je Gerät haben 13 Fälle kein geeignetes Bild; die
[genaue Auswahl und Bildabdeckung](verification/all-synthetic.json) bleibt
explizit. Nicht jede Zwischenansicht ist bildlich abgenommen. Die Rohbilder
bleiben im lokalen Nachweis; öffentlich stehen die Kontaktbögen und die beiden
qualifizierten Querformataufnahmen.

**Offener Befund im ursprünglichen Lauf:** Beide Querformat-Appaufnahmen sind
verschoben/abgeschnitten, obwohl der schwache Existenztest bestanden hat. Sie
werden nicht als vollständige Bildabnahme akzeptiert. Der getrennte
[Rotationsnachweis](orientation-capture.md) untersucht App- gegen Bildschirm-
aufnahmen und tatsächliche Bedienung. Das ist ein eigener Quellenstand; seine
Versuche werden nicht nachträglich zu diesen 268 addiert.

166 Modelltests und fünf SDK-Builds des identischen Quellenstandes gehören zum
[vorherigen Uhrnachweis](modular-clock-detail.md), nicht zu neuen SDK-Läufen hier.
Keine neue QA-01-Schließung oder Original-/Hardwareabnahme.

[Eigene Kontaktbilder und Hashmanifest](screenshots/goal-20261018/all-synthetic-manifest.json).

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-1.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-2.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-3.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-4.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-5.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-6.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-7.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-8.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-9.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-10.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-11.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-12.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-13.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPhone-contact-14.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-1.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-2.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-3.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-4.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-5.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-6.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-7.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-8.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-9.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-10.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-11.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-12.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-13.jpg)

![Eigene repräsentative Testzustände](screenshots/goal-20261018/all-synthetic-iPad-contact-14.jpg)
