# Mac-Runtime: Prüfaufbau vorhanden, Bediennachweis weiter offen

29. Oktober 2026 · [#79 / QA-04](https://github.com/Olli0103/homeview/issues/79). **Kein neuer Mac-UI-PASS und keine nachgewiesene App-Tastaturfehlfunktion.**

Der nächste Prüffall sollte klären, ob das bestehende eigene Menükommando **All Apps / Cmd+A** mit nativem **Select All** im fokussierten Assistenten konkurriert. Ohne tatsächlichen Bedienbefund wird dieses Kürzel nicht geändert.

## Aufbau und beobachtetes Ergebnis

Die unveränderten 225 Produkt-/Ressourcen-/Testinputs von `065cacf` wurden durch eine externe Variante des vorhandenen Projektgenerators verwendet. Nur der Prüfaufbau unterscheidet sich: macOS-XCTest statt des UIKit-Testtargets, absolute Quell-/Plistreferenzen, eigene Diagnose-App-ID und ein neuer synthetischer UUID-Store. Kein Reset des normalen Stores. [Genauer kompilierter Probequelltext](verification/mac-runtime-probes/MacProbeTests.swift.txt) — **Prüfabsicht, keine ausgeführte oder bestandene Methode**.

- Erste Projektvorbereitung scheiterte vor Tests an Scheme-/Projektwurzelauflösung. Der ursprüngliche Aufbau bleibt archiviert.
- Danach zwei erfolgreiche native Mac-Testbuilds. Mach-O meldet `MACOS`, arm64, SDK27.0, nicht Catalyst. Host macOS27.0.1 (26A434), Xcode27.0 (27A266a).
- Erster Startversuch mit dem unsigniert konfigurierten Build: eigener Runnerprozess vorhanden, aber innerhalb 150 Sekunden keine Testmethode beobachtet. Begrenzter Besitzerlauf endete124; ausschließlich dessen exakt identifizierter Runner beendet und Verschwinden geprüft.
- Zweiter Aufbau mit gewöhnlicher lokaler Xcode-Ad-hoc-Signatur (`CODE_SIGN_IDENTITY=-`), ohne Zertifikat/Team-ID. Strikte Bundleprüfung bestanden. Auch danach innerhalb75Sekunden keine beobachtete Testmethode, Besitzerlauf124. Exakte eigene Prozessbereinigung bestätigt keine verbliebenen Prozesse.
- Für beide abgebrochenen Besitzerläufe kann `xcresulttool` keine abgeschlossene Testzusammenfassung lesen. **Das sind keine zwei gescheiterten App-Testmethoden und kein Beleg einer Cmd+A-Fehlfunktion.**

225 Repositoryinputs, fünf bzw. sechs Prüfeingaben und 37 bzw.40 kompilierte/Launcheingaben wurden vor/nach jedem Versuch gebunden, vollständig archiviert/zurückgelesen und nicht verändert. Beide Archive bleiben getrennt. [Ergebnisse, Digests, Anpassungen und fehlende Aussagen](verification/mac-runtime-boundary.json).

## Konkrete Hostgrenzen, keine erfundene Ursache

Die separate rein lesende Prüfung meldet **„Developer mode is currently disabled.“** Der Gateway-Computerzugang meldet **„Gateway computer is unavailable; enable its computer provider and desktop session“**, kein verbundener Computer-Node ist verfügbar. Öffentliche Session-Lock-/Consolewerte blieben unbekannt; eine Displaygröße ist kein Interaktionsnachweis.

Diese beobachteten Grenzen erklären nicht bewiesen allein den Runner-Timeout. Es wurden weder Developer-Sicherheitsmodus, TCC-/Desktopberechtigungen, Gateway/Plugins noch Hostkonfiguration verändert oder umgangen. Ad-hoc-Signaturen betreffen ausschließlich die eigenen Prüfbundles, nicht die pausierte physische iPad-Signierung.

**Produktquellen und Cmd+A bleiben unverändert.** Kein neuer Core-/iOS-/Gesamtplattform-PASS, keine realen Konten, Sensoren, Audio-/Nachrichten-/Anruf-/Home-Aktionen. #79 bleibt offen. Der native Bedienpfad kann fortgesetzt werden, sobald ein autorisierter funktionierender interaktiver Prüfumfang vorhanden ist; diese beiden Startversuche werden nicht blind wiederholt. Andere Software- und Originalreferenzarbeit läuft unabhängig weiter, ohne erneut nach iPad oder Team-ID zu fragen.
