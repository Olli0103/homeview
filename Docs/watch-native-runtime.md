# Native Watch: installierbarer reduzierter Umfang und unabhängige Schaltflächen

29. Oktober 2026 · Teilumfang [#79](https://github.com/Olli0103/homeview/issues/79). **Echte watchOS-Laufzeit**, keine Übertragung eines Mac-Hosts oder bloße SDK-Abnahme.

## Laufzeit und gefundener Installationsfehler

Offizielles Xcode-Download/Install-Verfahren: watchOS 27.0 / **24R362**, arm64,3,83 GB. Export/QA-Artefakte extern, installierte Laufzeit in Apples verwaltetem internem Speicher. Eigener ungepaarter Series-12-46mm-Simulator `95999C8D-EF9F-4233-B232-1E61B557F2AD`, keine persönlichen Konten oder echte Watch.

Der bis dahin erfolgreiche SDK-Build war **nicht installierbar**: Die App deklarierte `WKRunsIndependentlyOfCompanionApp`, aber weder `WKWatchOnly` noch eine Companion-App-ID. Der native Installer lehnte sie ausdrücklich ab. Ein erster Kandidat mit beiden Unabhängigkeits-Keys wurde ebenfalls als mehrdeutig abgewiesen; dieser Fehlstand bleibt archiviert.

Die reduzierte App ist jetzt eindeutig **Watch-only**: `WKWatchOnly = true`, weder `WKRunsIndependentlyOfCompanionApp` noch `WKCompanionAppBundleIdentifier`. Der Generator setzt diese Metadaten; keine erfundene iPhone-Paarung oder WatchConnectivity-Synchronisierung. Nativer Installations-/Startaufruf erfolgreich, alle zehn installierten Appdateien bytegeprüft. Auch der aktuelle integrierte UI-Lauf installiert und startet die tatsächliche Watch-App.

„Begleitumfang“ bezeichnet hier die reduzierte eigenständige Oberfläche, nicht ein eingerichtetes persönliches Geräte-Paar oder geteilte Haushaltsidentität.

## Ein tatsächlicher Tap löste zwei Aktionen aus

Im nativen Watch-Test blieb „+“ auf68°. Der zurückgelesene **eigene synthetische UUID-Store** belegt die Ursache: Ein Tap schrieb erst `Thermostat set to 67°`, dann `Thermostat set to 68°`. Die beiden automatischen SwiftUI-Listenzeilen-Buttons führten beide Aktionen aus. Ihre beobachteten Schaltflächen waren nur ungefähr9,5×20,5 Punkte groß.

Nur die Temperaturzeile geändert: zwei explizite44×44-Punkte-Label-/Trefferflächen, gemeinsamer `.buttonStyle(.plain)` für getrennte Aktionen. Kein neuer Home-Adapter, keine Modell-/Berechtigungs-/Speicheränderung. Die native Prüfung sieht69° nach Erhöhen und68° nach Senken, danach genau eine Lichtumschaltung; der eigene gespeicherte Audit bestätigt diese drei Aktionen.

Die **identische eingefrorene Zweiermatrix** besteht vorher1/2 (Temperaturfehler; Timer bereits grün) und nachher2/2. Der Timer-Vorherfall war erst durch Testkorrekturen korrekt erreichbar: tatsächlicher Listenscroll und führende Null in `05:00`. Die frühere fehlgeschlagene Selektorprüfung wird nicht als Produktfehler ausgegeben; der Timer war laut eigenem Store bereits korrekt angelegt.

## Aktueller integrierter Nachweis

Das bestehende `HomeViewWatch`-Scheme enthält jetzt ein eigenes `HomeViewWatchUITests`-Target; [zwei native Tests](../Tests/WatchUITests/HomeViewWatchUITests.swift). Abhängigkeiten im Projektgenerator sind je Testtarget benannt und zeigen ausdrücklich auf die richtige App, nicht pauschal auf die iPad-App.

```sh
python3 Scripts/generate_project.py
xcodebuild test -project HomeViewReplica.xcodeproj -scheme HomeViewWatch \
  -sdk watchsimulator -destination 'id=<eigener-Watch-Simulator>' \
  CODE_SIGNING_ALLOWED=NO
```

- **2/2 aktuelle native Watch-Methoden bestanden**, null Fehler/Skips/strukturierte Runtime-Warnungen. Temperatur/Licht ausschließlich MockHome; lokaler5-Minuten-Timer und echter System-Home-/Hintergrund-/Vordergrundwechsel. Countdown sichtbar04:59 →04:58; kein300-Sekunden-Ablauf-/Ton-PASS daraus.
- **Fünf aktuelle arm64 SDK-Builds bestanden**; andere Plattformen wurden dadurch nicht erneut nativ abgenommen.88 Core-/Paket-/Testinputs unverändert, kein neuer Core-Lauf.
- **228 tatsächliche Quellen**, alle neun eingefrorenen UI-/Installationsarchive und installierte Appbytes geprüft. Quelldigest `7a2ea04d176f3d70bf7733447c20451f9bfbfce7591edc1f79e0cd97e63773f3`;73 SDK-Produktdateien archiviert/vollständig zurückgelesen.
-19 XCTest-PNGs dekodiert, sechs Übersichten tatsächlich gesichtet, sechs eigene Bilder veröffentlicht. Gesamte UI-Historie11 Ausführungen:5 bestanden,6 frühere Fehler. Nur die letzten zwei sind die aktuelle integrierte Abnahme.

[Quellen-/Installations-/Audit-/Ergebnisbindung und Bilder](verification/watch-native-runtime.json). Private Rohdaten: `research/homeview-watch-runtime-20261029` auf externem Artefaktspeicher.

## Grenzen

Keine volle quadratische HomeView-/Face-/Assistenten-/Medienoberfläche auf Watch. Keine tatsächliche Home-Anbindung, persönliche Freigabe, Watch-/iPhone-Paarung oder Geräteauthentifizierung hinzugefügt. Geschützte Szenen und fehlende Dienste werden dadurch nicht freigegeben.

Keine physische Watch, Always-on-/Wrist-down-/Dimmabnahme, Energie-/Framezeitmessung, Hintergrund-Refresh, Komplikationen, akustische Timer-/Systemalarmausgabe oder Sprach-/Hilfsmittelabnahme. Ein tatsächlicher Hintergrund-/Rückkehrfall beweist nicht jede Suspendierungsart. [Der frühere Mac-basierte Pulse-Befund](watch-pulse.md) bleibt separat datiert, keine nachträgliche Umbenennung zur Watch-Messung.

**#79 und #81 bleiben offen** für ihre übrigen Kriterien. Geräte-/Signing-Hold und Home-Sperre bleiben bestehen; die übrige Softwarearbeit läuft weiter.
