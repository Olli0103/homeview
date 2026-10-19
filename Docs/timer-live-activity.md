# Eigene Timer als Live Activity

19. Oktober 2026 · Teilumsetzung von [#51 / DAY-05](https://github.com/Olli0103/homeview/issues/51). **Issue bleibt offen; F066 ist nicht als vollständige Original-/Hardwaregleichheit abgenommen.**

## Was implementiert ist

Unter **Settings → Timer Live Activities** lässt sich eine eigene gemeinsame Timeranzeige ausdrücklich einschalten. Eine WidgetKit-Erweiterung stellt Lock-Screen- sowie kompakte, minimale und erweiterte Dynamic-Island-Ansichten bereit. Der öffentliche ActivityKit-Adapter startet nur nach einer aktuellen Vordergrundaktion: Einschalten, Timer starten/fortsetzen oder „Show timer activity“. Ein Prozessneustart allein erzeugt keine neue Aktivität; eine bereits bestehende eigene Aktivität kann weiter aktualisiert werden.

Die Anzeige erhält ausschließlich laufende/pausierte Anzahl, früheste Frist und kleinste pausierte Restzeit. **Keine Titel, Timer-IDs, Profile, Nachrichten, Kalender- oder Kontodaten.** Sie darf deshalb nach einer persönlichen Sitzungssperre als bewusst freigegebene allgemeine Timeranzeige weiterlaufen. Fremde Aktivitäten, Intercom, Siri und Apple Home werden nicht gesteuert. Es gibt keine Push-Token, Server, zusätzlichen Hintergrundmodi oder Alert-/Soundanforderungen.

Die Projektion übernimmt nur erfolgreich gespeicherte Timeränderungen. Ein fehlgeschlagenes Hinzufügen wird nicht veröffentlicht. Ausschalten widerruft die Zulassung sofort im Arbeitsspeicher und veranlasst das asynchrone Beenden eigener Aktivitäten unabhängig vom Präferenz-Save. Scheitert dieser Save, zeigt die Oberfläche ausdrücklich **„Off for this app session“** und eine getrennte Speicherwiederholung. Ein erfolgreicher Retry speichert das dauerhafte Aus; ein fehlgeschlagener Save wird nicht als dauerhaft behauptet.

Ein serialisierter Writer verarbeitet den jeweils neuesten Zustand. Spätere Ergebnisse dürfen keinen neueren Status ersetzen; ein wartender Start darf nach Widerruf/Hintergrund nicht mehr an die öffentliche Request-API übergeben werden. Bereits übergebene OS-Updates werden nicht als atomar rückgängig gemacht behauptet. Nach deren Abschluss gleicht der Writer den neuesten Zustand ab. Entfernen, gespeicherter Ablauf, Abschalten und erfolgreicher lokaler Reset bereinigen eigene Aktivitäten.

## Plattform- und Ablaufgrenzen

| Ziel | Umfang dieses Standes |
| --- | --- |
| iPhone, iOS Simulator 27.0 / iPhone 18 Pro | Tatsächlicher Registry-Read-back für Start, Pause, Fortsetzen und Cleanup; eigene kompakte Dynamic Island außerhalb der App sichtbar |
| iPad Simulator 27.0 | Derselbe tatsächliche Registry-/Cleanup-Pfad bestanden; stabiler Home Screen aufgenommen, dort keine Aktivitätsdarstellung sichtbar. **iPad-Lock-Screen-Darstellung nicht geprüft** |
| macOS, tvOS, visionOS, watchOS | Eigene SDK-Builds bestanden; hier kein nativer ActivityKit-Request-Adapter. Automatische iPhone-Spiegelung auf gekoppelte Geräte ist keine hier geprüfte native Integration |
| Physische Geräte | Nicht abgenommen; kein Signieren, Pairing oder Accountzugriff für diese Prüfung |

Dies ist **eine Anzeige, kein Alarm**. Die laufende Frist wird als System-Texttimer dargestellt. Wenn die früheste Frist während suspendierter App veraltet, zeigt die Stale-Darstellung „Check timers / Open HomeView for current timers“. Sie ist keine garantierte Hintergrundbeendigung, Alarmzustellung oder sekundengenaue Bereinigung bei suspendiertem Prozess. Apple dokumentiert maximal acht aktive Stunden und anschließend gegebenenfalls bis zu vier weitere Stunden auf dem Lock Screen. Ein 24-Stunden-Timer garantiert deshalb keine 24 Stunden Live Activity.

Öffentliche Grundlage: [Apple: Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities), am 19. Oktober 2026 gelesen; [Quellenreceipt](verification/timer-activity-public-source.json). Verwendet wird die vorhandene öffentliche ActivityKit-/WidgetKit-Lösung, keine zusätzliche Bibliothek und keine private API.

## Getrennte, eingefrorene Prüfläufe

| Lane | Beobachtetes Ergebnis |
| --- | --- |
| Core `5f12a7f` | 291 Tests, null Fehler; neun neue Fälle. Alle 68 Core-/Coretest-Dateien sind im Lieferstand bytegleich; kein neuer vollständiger Lauf aus späteren Testkorrekturen behauptet |
| Tatsächliches AppModel `4160310` | 25 Assertions bestanden, einschließlich echter eigener Store-Schreibfehler, ungespeicherter Projektion, Session-Widerruf, Retry, Neustart, Pause, gespeichertem Ablauf und autorisiertem lokalen Reset. **Fixture-Backend, keine Systemaktivität oder Akustik in dieser Probe** |
| SDK `96f2d9a` | Fünf arm64-Builds bestanden. iOS enthält die echte eingebettete Widget-Erweiterung. Produkt-/Projekt-/Ressourcenbytes sind im Lieferstand unverändert; spätere Änderungen betreffen nur UITests |
| Funktionale UI `d7fc54e` | Zwei Fälle je iPad/iPhone, vier erfolgreiche Ausführungen für Opt-in/-out, Speicherung und ausdrücklich erneuten Start. Truthful Fixture-Backend, keine echte Systemaktivität |
| Tatsächliche System-UI | iPhone `1d2346f`, final betroffener iPad-Fall `377e76f`: je Start → Pause → Fortsetzen → Ausschalten, mit öffentlichem Registry-Read-back. Abschließend auf beiden **null eigene aktive/stale Aktivitäten** |

Jeder UI-Checkpoint bindet 197 Quellen/Projekt-/Test-/Ressourcendateien sowie 26 kompilierte App-/Widget-/Test-/Launch-Eingaben. Diese bleiben während des jeweiligen Laufs unverändert; die installierten App-/Widgetbytes wurden zurückgelesen. Die Testanbieter sind standardmäßig systemfrei. Nur ein ausdrücklich gesetztes Systemtestflag mit frischem UUID-Teststore aktiviert den echten Adapter für die eigenen synthetischen Simulator-Timer.

### Historische Fehler bleiben Teil der Bilanz

Insgesamt **13 UI-Ausführungen: acht erfolgreich, fünf fehlgeschlagen**, drei eindeutige Fälle; keine Skips oder Runtime-Warnungen. Das ist keine behauptete aktuelle vollständige Suite.

- Vier erste funktionale Ausführungen trafen die Mitte der breiten Accessibility-Zeile statt des sichtbaren Schalters. Der tatsächlich aufgezeichnete Touch lag bei x=201/y=210; das gesichtete Video zeigt den Schalter weiterhin auf Aus. Korrigiert wurde nur das Pointer-Ziel. Sämtliche Wert-, Speicher- und Statusbedingungen bleiben erhalten.
- Der erste echte Systempilot bestand auf beiden Geräten funktional, aber beide Außenbilder zeigten noch die Home-Animation. Sie wurden nicht als Sichtbarkeitsbeweis akzeptiert.
- Danach bestand der iPhone-Fall mit sichtbar laufendem Countdown. Auf dem iPad kam die Vordergrund-Assertion zu früh und brach vor dem Cleanup ab. Eine frische eigene Opt-out-Sitzung wurde gestartet; der finale betroffene Lauf wartet auf den tatsächlichen Zustandswechsel und verifiziert das Cleanup vor seiner abschließenden Assertion.
- Vor den Ausführungen scheiterten außerdem Test-/Buildvorbereitungen an Swift-Sichtbarkeit, Actor-Grenzen, der zunächst falschen Widget-Bundle-ID und einem XCTest-Argumentnamen. Zwei externe Probe-Vorbereitungen scheiterten vor jeder Fallausführung. Sie zählen nicht als reproduzierte Fehler eines vorher veröffentlichten Produkts. Compilerwarnungen in unveränderten Dateien bleiben dokumentiert, nicht als warnungsfrei umgedeutet.

24 exportierte PNGs wurden dekodiert, sieben Kontaktübersichten und vier vollständige Außenbilder gesichtet; zusätzlich ein historischer Fehler-Videoframe. [15 ausgewählte eigene Bilder samt Digests und Checkpoints](verification/timer-activity.json). Die iPhone-Dynamic-Island-Sichtung gilt nur für die kompakte Darstellung dieses synthetischen Zustands. Erweiterte/minimale Darstellung, Lock Screen, Originalgeometrie, weitere Größen/Accessibility-Einstellungen, echte Geräte, Energie, mehrere Fenster sowie die vollständige Force-quit-/Crash-/Berechtigungsentzugs- und Hintergrundablaufmatrix bleiben offen.

[Gesamtbericht](verification/timer-activity.json) · [native Gegenprobe](verification/timer-activity-native-probe.swift) · [native Ergebnisse](verification/timer-activity-native-results.json) · [UI-Checkpoint-Ergebnisse](verification/timer-activity-ui-results.json). Alle elf externen Archive wurden vollständig byteweise zurückgelesen; Inventare/Digests stehen im Bericht. Private Originalreferenzen und rohe Testlogs werden nicht veröffentlicht.

**Keine Home-Anbindung.** Eigene lokale Timer und allgemeine Systemanzeigen sind keine Umsetzung fremder Intercom-/Systemaktivitäten. Die ursprünglichen Abnahmekriterien bleiben unverändert, deshalb bleibt #51 offen.
