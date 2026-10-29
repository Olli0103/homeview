# Erfolgreich kompilierte, aber unvollständige Shortcut-Pakete erkennen

29. Oktober 2026 · begrenzte Softwarekorrektur zu [#74](https://github.com/Olli0103/homeview/issues/74). Kein neuer OS-Sprach-/Hilfsmittel-PASS.

## Kontrolliert reproduziert

Der [TV-/Foto-Build](tv-camera-photos.md) enthielt nach einer inkrementellen iOS-Kompilierung nur noch zwei statt fünf generierte AppIntents-Dateien. Ich habe das in einem getrennten, explizit aus dem veröffentlichten `eb81e22` angelegten Checkout und eigenem Buildverzeichnis geprüft; keine Quellen unter laufenden UI-Tests geändert.

| Standardaufruf | Quellenänderung gegenüber frischem Build | Compiler | AppIntents-Dateien |
| --- | --- | --- | --- |
| Frischer `xcodebuild … build` | keine | Erfolg | alle fünf |
| Inkrementeller Build | nur angehängter Swift-Kommentar | Erfolg | nur `extract.actionsdata` und `version.json` |
| Identischer weiterer Build | keine weitere Änderung | Erfolg | weiterhin nur zwei |
| `xcodebuild … clean build` | exakt dieselben kommentierten Quellen | Erfolg | alle fünf wiederhergestellt |

Die fehlenden Ausgaben sind `root.ssu.yaml`, `nlu/nlu.lzfse` und die `nlu/*.version`-Datei. Im Quelländerungsbuild läuft `ExtractAppIntentsMetadata` für die App erneut, aber kein neuer `AppIntentsSSUTraining`-Schritt steht in diesem Log. Frischer und Clean-Build enthalten beide Schritte. Das ist ein reproduzierter Output-/Buildschritt-Unterschied, **kein bewiesener interner Xcode-Cache-Root-Cause**. Die Kommentare bleiben ausschließlich in der privaten Probe, nicht im Produkt. Info.plist, AppIntent und Projektdateien wurden dafür nicht verändert.

## Bestehenden öffentlichen Buildweg abgesichert

[Scripts/build_platforms.py](../Scripts/build_platforms.py) verwendet weiterhin ausschließlich das installierte öffentliche `xcodebuild`. Nach erfolgreichem iOS-Build prüft es die erwarteten nichtleeren Dateien, den eigenen Intent in den Action-Metadaten, eine Metadatenversion und App-/Intent-Einträge im SSU-Text. Alle vorhandenen Metadaten werden mit Größe und SHA-256 im Buildbericht geführt.

Nur bei erfolgreicher Kompilierung mit unvollständigen/ungültigen Metadaten folgt **ein** normaler `clean build` für dasselbe iOS-Ziel. Beide Versuche bleiben mit getrennten Logs, Befehlen, Compilerstatus und Artefaktbefunden im Bericht. Compilerfehler werden nicht wiederholt. Bleibt die Ausgabe nach dieser einen Wiederherstellung unvollständig, schlägt der Gesamtbuild fehl, obwohl der Compiler selbst Erfolg melden kann. Extraktion oder SSU-Training werden weder deaktiviert noch durch private Apple-Werkzeuge ersetzt. Die übrigen Plattformen behalten ihre bisherigen SDK-Buildbefehle; dieser zusätzliche Artefaktguard gilt ausdrücklich nur dem aktuellen iOS-Simulatorpaket.

## Tatsächliche Prüfung und Grenzen

Sechs Tooling-Tests prüfen kompletten Build ohne Retry, einmalige Wiederherstellung mit erhaltenem Erstbefund, dauerhaft unvollständige Compilererfolge, unverändert gemeldeten Compilerfehler ohne Retry, unveränderten Nicht-iOS-Weg und vorhandene, aber falsche/leere Metadaten. Eine weitere echte kommentierte inkrementelle Probe erzeugt erneut das Zweierpaket. Daran erkennt die tatsächliche neue Buildfunktion den unvollständigen normalen Build und stellt mit genau einem Clean-Build wieder alle fünf Dateien her. Erstpaket und Wiederherstellung sind separat archiviert und zurückgelesen.

Fünf aktuelle frische SDK-Builds über das geänderte Skript bestehen ohne Wiederherstellungsversuch; alle 73 Produktdateien und Quellen separat archiviert/zurückgelesen. Alle 165 App-/Ressourceneingaben sind exakt zum veröffentlichten Alert-Fix `376a4bd`, ebenso die 88 Core-/Package-/Core-Testeingaben zum vorherigen 398-Test-Stand. Keine Produktänderung, kein neuer Core-/UI-Lauf: die zwölf nativen Alert-Ausführungen von `376a4bd` bleiben ausdrücklich ein vorheriger Teststand. [Quellen, fünf kontrollierte Probe-Builds, zwei echte Guard-Versuche und fünf aktuelle SDKs](verification/shortcut-package-completeness.json).

Die komprimierte NLU-Datei wird nicht unabhängig decodiert; Dateipräsenz, Struktur und Hashes beweisen keinen Systemaufruf. Frühere echte iPhone-/iPad-Aufrufe aus Kurzbefehle bleiben separat in [ihrem eigenen Bericht](assistant-os-shortcut.md). Andere SDK-/Xcode-Versionen brauchen eine erneute Prüfung des erwarteten Paketformats statt eines stillen Akzeptierens anderer Ausgaben.

**#74 bleibt OPEN, F104/F105 ohne Parity.** Übrige OS-Hilfsmittel-/Sprach-/RTT-/Plattform- und physische/gesperrte Geräteabnahmen sind nicht mitabgenommen. Geräte-/Signing-Pause und Home-Sperre bleiben bestehen; keine echten persönlichen Konten, Nachrichten, Anrufe oder Aufnahme.
