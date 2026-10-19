# Öffnen des eigenen Assistenten per App Shortcut

20. Oktober 2026 · Teilimplementierung von [#74](https://github.com/Olli0103/homeview/issues/74). **Keine Siri-/OS-Shortcut- oder Geräteauthentifizierungs-Abnahme.**

## Begrenzter Einstieg

`OpenHomeViewAssistantIntent` deklariert einen parameterlosen App Intent für iOS/iPadOS, macOS und visionOS. Der Provider bietet **Open Assistant** mit der Phrase **Open ${applicationName} assistant** an. Die Aktion öffnet ausschließlich das Eingabefeld der eigenen HomeView-Oberfläche. Keine Aufnahme, kein Senden, kein Antwort-Vorlesen und kein Entsperren persönlicher Inhalte werden angestoßen. tvOS und Watch stellen diesen Einstieg nicht bereit.

Die deklarierte Policy ist **requiresLocalDeviceAuthentication**. Laut Apple verlangt sie ein entsperrtes Gerät, auf dem der Intent läuft — anders als `requiresAuthentication`, bei der unter Umständen ein anderes beteiligtes Gerät entsperrt sein kann. Diese Systemprüfung wird nicht durch HomeViews Demo-Profilauswahl ersetzt. In der nativen Probe wird der Intent-Body direkt aufgerufen: Sie führt die OS-Authentifizierung ausdrücklich **nicht** aus.

Ab OS-Version 26 wird `supportedModes = .foreground(.immediate)` verwendet. Für die frühere unterstützte macOS-Deploymentversion bleibt `openAppWhenRun = true` deklariert. Der beobachtete Native-Lauf ist kein macOS-15-Gerätetest.

## Übergabe an die Oberfläche

Der Body prüft Task-Abbruch und legt nur eine payloadfreie RAM-Anfrage ab. Keine Nutzereingabe, Adresse oder persönliche Kennung wird übertragen oder gespeichert. Eine aktive RootView beansprucht sie einmalig; inaktive Ansichten warten bis zur Rückkehr. Nach 30 Sekunden, bei rückwärts liegendem oder nicht endlichem Zeitwert wird nicht geöffnet. Monotone Uptime statt Kalenderzeit begrenzt die Gültigkeit. Neue Anfragen ersetzen eine noch ausstehende Anfrage.

Der Footer-Button und der Shortcut verwenden dieselbe Öffnungsaktion: Demo-Türklingel schließen, eigene Assistentenroute wählen und Texteingabe fokussieren. Ein vorhandener ungesendeter Entwurf bleibt erhalten. Bestehende Sperr-/Hintergrundregeln bleiben maßgeblich. Mehrfenster-Zielauswahl wird nicht als abgenommen behauptet.

## Getrennte Nachweise

- **SDKs:** fünf Plattformen gebaut; eigenes Intent-/Provider-Metadatum in iOS-, macOS- und visionOS-Bundles. Genau eine Aktion ohne Parameter, explizite lokale Authentifizierung, Vordergrundmodus und genau ein Shortcut mit Phrase. Kein eigener Eintrag in tvOS-/Watch-Produkten.
- **Native Probe:** tatsächlicher AppIntent-Body, RootView und AppModel mit eigenem UUID-Speicher und injizierter ScenePhase. Anfrage vor dem Aufbau der RootView, warmer Zustand, inaktiv/aktiv, einmaliger Verbrauch, Ablauf-/Zukunfts-/Nichtendlich-Grenzen, vorab abgebrochener Task und erneutes Einhängen der RootView bestehen insgesamt 20 Bedingungen. „Vor der RootView“ ist kein echter Prozess-Kaltstart durch das OS.
- **UI-Regression:** vier bestehende Ausführungen auf iPad/iPhone: Tastaturgeometrie/ungesendete Rotation und Entwurf über Navigation beziehungsweise Löschen bei Hintergrund ohne implizites Senden. Sie betätigen nicht Siri oder die Shortcuts-App.
- **Bilder:** sechs eigene Eingabe-/Entwurfszustände dekodiert, zwei Übersichten gesichtet; keine Original- oder statische Countdown-Pixelabnahme.

[Quellen-/Binär-/Metadatenbericht und eigene Bilder](verification/assistant-app-shortcut.json). 198 Quellinputs, native Kompilation/Ausführung, kompilierte UI-Eingaben und installierte Appbytes sind gebunden. SDK-Metadaten und die zugehörigen drei Executables sind extern archiviert und byteweise zurückgelesen. Core und Coretests bleiben unverändert: 291 historische Tests bei `5f12a7f`, 68 bytegleiche Dateien, kein neuer Core-Lauf.

## Offene Abnahme

#74 bleibt offen. Noch nicht ausgeführt: echter Systemaufruf per Siri/Shortcuts, echter Prozess-Kaltstart darüber, gesperrtes Gerät/Authentifizierungsdialog, physische oder akustische Sprachbedienung, ältere macOS-Version, Mehrfenster-Zielwahl und sämtliche weiteren OS-Hilfsmittel aus der [Plattformmatrix](speech-feature-boundaries.md). Compiler-Metadaten und ein direkt ausgeführter Intent-Body sind keine vollständige Systemintegration. F104/F105 bleiben ohne Parity.

Keine realen Konten, Mikrofon-/Kameraaufnahme, Anrufe/Nachrichten, Systemalarme oder neuen System-Live-Activities. **Keine Home-Anbindung.**

## Öffentliche Verträge

Am 20. Oktober 2026 gelesen, jeweils die genannten Hauptabschnitte, nicht sämtliche verlinkte APIs:

- [Apple: App Shortcuts](https://developer.apple.com/documentation/appintents/app-shortcuts): Provider, Aktionen und Compilermetadaten.
- [Apple: supportedModes](https://developer.apple.com/documentation/appintents/appintent/supportedmodes): unmittelbarer Vordergrundmodus vor `perform()`.
- [Apple: requiresLocalDeviceAuthentication](https://developer.apple.com/documentation/appintents/intentauthenticationpolicy/requireslocaldeviceauthentication): Entsperren des ausführenden Geräts.
- [Apple: requiresAuthentication](https://developer.apple.com/documentation/appintents/intentauthenticationpolicy/requiresauthentication): ausdrücklich abweichende Mehrgerätebedingung; hier nicht als Policy verwendet.
