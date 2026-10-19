# Entfernte Oberfläche beendet die persönliche Sitzung

19. Oktober 2026 · Teilkorrektur von [#67 / SYS-04](https://github.com/Olli0103/homeview/issues/67). **Das Issue bleibt offen; F095 ist nicht als Originalgleichheit abgenommen.**

## Reproduzierter Fehler und Korrektur

Der Hintergrundwechsel sperrte bereits die persönliche Sitzung. `RootView.onDisappear` beendete hingegen Medien-/Handoff-/Displayaktivität, ohne die Entsperrung, den Kalendercache, das Profil oder Entwürfe zu widerrufen. Die App hält ihr `AppModel` oberhalb der Fensteroberfläche; das Entfernen der Oberfläche allein ist deshalb keine zuverlässige Speicherbereinigung.

Eine externe native Probe kompiliert die tatsächlichen App-Quellen und entfernt die tatsächliche `RootView` aus einem eigenen `NSHostingView`. Die ScenePhase wird gezielt **aktiv** gehalten, um diesen Pfad vom Hintergrundpfad zu trennen. Wrapper-Marker und die vorhandenen Foreground-Eigenschaften bestätigen, dass die echten Lifecycle-Handler gelaufen sind. Gegen den unveränderten Stand `cada125d3a10f22aa3e541aec28604f4e939a24b` scheitern sieben von 14 Assertions: Entsperrung, Cache, Profil, Nachrichten-/Assistentenentwurf, Sitzungsgeneration und persönliche Route bleiben erhalten.

Produktcode `a54e1dc5eaa6e1829de0a2526d97f846cfd7ce1c` ergänzt fünf Zeilen: die vorhandene `lockPersonalAccess()`-Bereinigung aufrufen und eine persönliche App-Route hinter die bestehende Datenschutzauthentifizierung zurückstellen. Es gibt keine neue Authentifizierungs-, Präsenz- oder Home-Integration. Gespeicherte lokale Inhalte werden nicht gelöscht. Bei einem gemeinsam verwendeten Modell ist die Sperre bewusst modellweit, nicht nur auf das entfernte Fenster begrenzt.

Die Gegenkontrolle wechselt die eingebettete RootView nur vorübergehend auf **inactive**, anschließend zurück auf active. Authentifizierung, Cache und Entwürfe bleiben dabei erhalten. Das ist wichtig, weil ein System-Authentifizierungsdialog die Scene vorübergehend inaktiv machen kann. Die bestehende deckende Inaktiv-Abdeckung wird nicht verändert; ihre physische Snapshot-Wirkung wird hier nicht abgenommen.

## Quellengebundene Prüfung

| Prüfung | Beobachtung |
| --- | --- |
| Tatsächliche native RootView, vorher | 14 Assertions, sieben fehlgeschlagen |
| Derselbe native Prüfcode, korrigierter Produktstand | 14 Assertions, keine fehlgeschlagen |
| Bestehende Kalender-/Vorlese-Hintergrundtests | zwei Fälle je iPad/iPhone, vier erfolgreiche Ausführungen; keine Fehler, Skips oder Runtime-Warnungen |
| SDK-Builds | iOS, macOS, tvOS, visionOS, watchOS erfolgreich; watchOS verwendet keine RootView |
| Eingabebindung | 190 Quellen/Test-/Ressourcen-/Projektdateien vor/nach gleich; 22 UI-Build-/Launch-Eingaben unverändert, installierte Appbytes zurückgelesen |
| Bilder | sechs eigene PNGs dekodiert, zwei Kontaktübersichten gesichtet; gesperrter Kalender und gesperrtes Vorlesen/leerer Entwurf sichtbar |

Die native Probe verwendet ausschließlich synthetische Fixture-Provider, einen frischen UUID-Teststore, eine eigene nicht aktivierte/offscreen AppKit-Oberfläche und kein Audioasset. Display-Wachhaltung ist ausgeschaltet. Keine echten Berechtigungsdialoge, Kalender, Bibliotheken, Nachrichten, Anrufe, Sensoren oder Homes wurden verwendet. Ein erster externer Prüfaufbau scheiterte an einem Leerzeichenfehler im Probe-Code, bevor ein Fall ausgeführt wurde; die korrigierte Baseline ist separat erhalten. Die nativen Compilerläufe enthalten bekannte Warnungen in unveränderten Quellen; sie werden nicht als warnungsfrei bezeichnet.

Core-Quellen und Coretests sind unverändert. Die 282 Modelltests des früheren Produktstands `987f6fd` bleiben ausdrücklich historische Ergebnisse; kein neuer Core-Lauf wird behauptet. Frühere gesteuerte Permission-/Stale-Completion-Prüfungen bleiben separat in [Sitzungsschutz](privacy-session.md) und [Quellenwiderruf](personal-source-revocation.md) gebunden. Die neue Probe prüft den tatsächlichen Aufruf der bestehenden Sperrbereinigung, nicht einen neu erfundenen Ersatz-Lifecycle.

[Maschinenlesbarer Bericht](verification/root-disappearance.json) · [Baseline](verification/root-disappearance-native-baseline.json) · [Gegenprobe](verification/root-disappearance-native-final.json) · [eigene native Probe](verification/root-disappearance-native-probe.swift).

Die externen Archive wurden vollständig byteweise zurückgelesen: native Baseline und Gegenprobe jeweils 290 Einträge, UI-Quellen/ausgeführte Eingaben 212 Einträge. Digests und Inventare stehen im Bericht. Die Baseline-Quelldatei der später geänderten RootView wurde aus dem eingefrorenen Git-Commit mit dem bereits vor der Ausführung aufgezeichneten Digest gelesen, nicht nachträglich neu erzeugt.

## Offene Grenzen

Die kontrollierte RootView-Entfernung mit künstlich gesetzter ScenePhase ist **keine** physische Fenster-/Scene-, App-Switcher-Snapshot-, LocalAuthentication- oder Präsenzabnahme. Die iOS-UI-Läufe prüfen vorhandene Hintergrundregressionen, nicht die künstliche RootView-Entfernung. Bilder gelten nur für die genannten Datenschutz-/Readout-Zustände, nicht als vollständige Assistenten-/Keyboard-Geometrie- oder Originalabnahme. Tatsächliches Weggehen, die übrige Medienpolicy und Hardware-Snapshots bleiben offen. Keine Home-Anbindung.
