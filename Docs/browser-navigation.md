# Browser-Navigation und externe Inhalte

17. Oktober 2026 · [DAY-08, #54](https://github.com/Olli0103/homeview/issues/54).

Der Browser nutzt das öffentliche WebKit und einen nicht persistenten Website-Datenspeicher. Es gibt keinen Script-Message-Handler, keine privilegierte App-Befehlsschnittstelle und keinen Import von Safari-Verlauf oder Passwörtern.

## Transport und Navigation

- Eingaben ohne Scheme werden zu HTTPS ergänzt. Ungültige Adressen, eingebettete Credentials, HTTP, lokale Dateien und fremde Schemes werden abgelehnt.
- Die Navigationsentscheidung gilt auch für Folgeseiten/neue Fenster und Antwort-URLs. Neue zulässige Fenster bleiben im eingebetteten Browser; keine automatische externe App-Übergabe.
- Die pauschale `NSAllowsArbitraryLoadsInWebContent`-Ausnahme ist entfernt. Betriebssystem-TLS und ATS bleiben aktiv. Es gibt keine Abschaltung der Zertifikatsprüfung.
- Zurück/Vorwärts, Stop, Ladefehler, abgebrochene Navigation und ein beendeter Web-Prozess haben explizite Zustände. Navigation weg vom Browser und eine inaktive App stoppen Ladevorgänge.
- Website-Text und strukturierte Rezeptdaten werden nur als Inhalt interpretiert, nicht als native Kommandos. Rezeptimport bleibt eine ausdrückliche Schaltfläche.

## Reproduzierbare lokale Prüfung

73 Modelltests, drei gezielte UI-Fälle je iPad/iPhone und fünf SDK-Builds bestanden. [Quellenbindung und Ergebnisse](verification/browser.json).

Die UI-Prüfung verwendet ausschließlich gebündeltes HTML beziehungsweise einen durch **zwei hostseitige Testflags** freigeschalteten In-Memory-`WKURLSchemeHandler`. Er liefert zwei lokale Seiten, einen deterministischen Offlinefehler und einen absichtlich wartenden Ladeversuch für Stop. Er kann weder Dateien noch Netzwerk oder native Befehle bedienen und ist im normalen App-Start nicht registriert. Die Core-Policy prüft zusätzlich, dass allein ein Website-/Fixture-Status diesen Testpfad nicht freischaltet.

Geprüft sind lokale Seitennavigation, Back/Forward, Offlinefehler, Stop, abgewiesene unsichere Adressen/externe Schemes und die bestehende DOM-Rezept-Übernahme bis Kochen/Anheften. Diese Testseiten sind kein Nachweis für die Erreichbarkeit beliebiger öffentlicher Websites oder alle realen Netzwerkfehler. tvOS und Watch erhalten weiterhin keinen behaupteten eingebetteten WebKit-Browser.

Das bounded Navigations-/Inhalts-Paket ist damit abgeschlossen; allgemeine Original-UI- und Geräteabnahmen bleiben getrennt.
