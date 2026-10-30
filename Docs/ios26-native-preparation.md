# iOS 26.1: native Vorbereitung, keine Picker-Abnahme

30. Oktober 2026 · #67 bleibt offen. **Null ausgeführte native App-Tests.**

Der iOS-27-Fotosuchfix gilt weiterhin nur für seinen tatsächlich geprüften Pfad.
Für die unterstützte Mindestversion iOS 26.1 wurde deshalb die offizielle arm64-
Runtime 23B80 vorbereitet, ohne Produktcode oder Deploymentziel zu ändern.

## Nachgewiesen

Der offizielle Xcode-Systemdownload blieb nach 653 Sekunden nahe 1,3 %. Eine
begrenzte HTTPS-Gegenprobe am exakten Apple-CDN-Ziel war schnell. Nach Ende dieses
eigenen Downloadprozesses wurde dasselbe offizielle MobileAsset einmal direkt
geladen: 8.321.499.136 Bytes in 160,129 Sekunden, vollständiger SHA-256-Abgleich
gegen Apples Katalog. Keine bewiesene Ursache der Transportdifferenz behauptet.

Apples vorhandener `aa`-Assetextraktor und der normale CoreSimulator-Import wurden
verwendet, ohne neue Abhängigkeit, unsichere Importoption, Ressourcenänderung oder
Signatur-Override. Alle vier Restore-Komponenten stimmen mit Apples SHA-384-
Manifest überein. Auch die tatsächlich systemverwaltete 8.346.526.729-Byte-
Runtimekopie stimmt vollständig damit überein. Import meldet Ready/Verified;
alle vier früheren Runtime-Identitäten bleiben vorhanden.

**Zusätzliche Verifierprüfung ausdrücklich FAIL:** `simctl runtime verify`
meldet -67054; `codesign --verify` meldet obsolete custom omit rules. Beide
Fehler treten identisch auch an der bereits vorhandenen offiziellen iOS-27-
Runtime auf. Keine allgemeine Ursachenbehauptung und kein Reverify-PASS.

## Native Ausführungsgrenze

Ein frisches, ausschließlich synthetisches iPhone 17 Pro wurde angelegt.
`bootstatus` meldet nach 43 Sekunden Finished, aber:

- Der einmalige eigene Canary-Import erreicht seine 120-Sekunden-Grenze.
- Die native Fotos-App startet innerhalb der vorgesehenen 45 Sekunden nicht.
- Die native Screenshot-Abfrage erreicht ihre 30-Sekunden-Grenze ohne Bilddatei.
- Auch die Installation für einen unveränderten Demo-ohne-Mediathek-Kontrolltest
  hängt noch nach beobachteten 62 Sekunden und wird gezielt unterbrochen. Der
  Test startet nicht; nach Shutdown ist kein Appbundle installiert.

Die sechs ursprünglichen OS-Beispieldateien sind anschließend bytegleich;
kein Canary angekommen, nichts ausgewählt, kein automatischer Importretry.
Der neue Simulator ist heruntergefahren, nicht gelöscht; das geplante iPad
wurde nicht angelegt. Am ausgewählten Xcode ist keine Simulator-GUI-App am
Standardpfad vorhanden. Keine Host-, Sicherheits-, Desktop- oder Dienständerung.

**Keine Produktfehlerdiagnose, kein Datenschutz-/Mindest-OS-PASS und keine
Behauptung einer fehlenden öffentlichen Picker-API.** Die genaue native
Start-/Transportursache bleibt offen. Die tatsächlichen iOS-26-Pickerfälle
müssen weiterhin mit sichtbarer eigener Canary und unverändertem ganzen
98%-Karten-/Rückkehrvertrag ausgeführt werden.

## Bindung und Fortsetzung

Alle [253 bestehenden Quellen](verification/tv-media-focus-source-20261030.json)
stimmen vor/nach mit `ace70de3e93bf94da748f0ba597d19ec41ee6872` überein.
Der Build-for-testing besteht; alle 33 kompilierten Inputs unverändert und aus
bestehenden Archiven rekonstruierbar, null neu duplizierte Binärdateien. Das ist
kein ausgeführter UI-Test und keine neue Fünf-SDK-/Core-Suite. 65 private
Belegdateien/2.270.322 Bytes versiegelt und vollständig zurückgelesen; bewegliche
Downloads extern, erforderlicher Runtime-Speicher systemverwaltet. Keine Löschung.

[Getrennte Ergebnisse und Hashes](verification/ios26-native-preparation-20261030.json).
Weitere unabhängige Softwarearbeit läuft weiter. Home-/Geräte-/Signing-Pause,
F095 partial/parity=false und alle ursprünglichen Issuekriterien bleiben erhalten.
