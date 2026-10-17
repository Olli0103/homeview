# Öffentliche Kopie: Prüfung

Stand 17. Oktober 2026. Frische Prüfung der öffentlichen Quellen nach Austausch der Referenzassets und Ziffernkonturen.

- 32 Modelltests bestanden, keine Fehler.
- Fünf SDK-Builds erfolgreich: iOS-Simulator, macOS, tvOS-Simulator, visionOS-Simulator und watchOS-Simulator.
- Gezielte UI-/Rendererprüfung dieser öffentlichen Kopie läuft noch. Keine neue vollständige UI-Suite behauptet.
- Keine physische Hardware- oder persönliche Accountabnahme. Apple Home bleibt gesperrt.

Quelldigest: `226a53b5c6c3a984495617f2174c44eab2593d07060529391e5202ab1caa6e12`. Dateiliste und Einzelhashes in [source-manifest.json](source-manifest.json).

Ein parallel gestarteter erster Testbundle-Build kollidierte mit dem Plattformbuild auf derselben Xcode-Build-Datenbank. Dies war ein Build-Orchestrierungsfehler. Die Wiederholung läuft erst nach Abschluss der Plattformbuilds. Die fünf SDK-Builds und Modelltests sind abgeschlossen.

Historische private Screenshots oder Testzahlen zertifizieren diese veränderte öffentliche Kopie nicht. Rohlogs mit lokalen Pfaden werden nicht veröffentlicht.
