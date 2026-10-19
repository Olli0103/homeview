# Private Cloud Compute: öffentlicher Pfad, kein aktivierter Dienst

19. Oktober 2026 · Rechercheabschluss [SYS-07, #70](https://github.com/Olli0103/homeview/issues/70). **Die App verwendet weiterhin kein PCC.** Der Implementierungs-/Paritätsstatus von F099 bleibt blockiert; abgeschlossen ist die verlangte API-/Anbieterbilanz.

## Aktueller öffentlicher Pfad

Die pauschale Aussage „kein öffentlicher PCC-Zugang“ wäre für das aktuelle SDK falsch. Apple dokumentiert seit OS 27 den konkreten Typ [`PrivateCloudComputeLanguageModel`](https://developer.apple.com/documentation/foundationmodels/privatecloudcomputelanguagemodel), ein anderes Modell als `SystemLanguageModel`. Er kann ausdrücklich einer `LanguageModelSession` übergeben werden. Deklariert für iOS/iPadOS, macOS, visionOS und watchOS 27; tvOS ist ausdrücklich ausgeschlossen. Das ist keine Zusage für jedes einzelne Gerät oder jede Region.

Der API-Typ allein ist **keine Zugangsberechtigung**. [`com.apple.developer.private-cloud-compute`](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.private-cloud-compute) ist ein von Apple verwaltetes Entitlement, standardmäßig `NO`. Die aktuelle [Zugangsseite](https://developer.apple.com/private-cloud-compute/) nennt Teilnahme am App Store Small Business Program, weniger als zwei Millionen erste App-Downloads und ein dem Entwicklerkonto zugeteiltes PCC-Entitlement. Sie beschreibt App-Store-Verteilung sowie TestFlight/Ad-hoc-Tests für berechtigte Entwickler. Diese Kontovoraussetzungen und eine Zuteilung wurden hier **nicht geprüft, beantragt oder behauptet**. Eine Plist-Änderung oder ein erfolgreicher Compilerlauf ersetzt sie nicht.

Apple beschreibt für berechtigte Entwickler derzeit Nutzung ohne Cloud-API-Kosten innerhalb dieser Bedingungen; daraus wird keine allgemeine kostenlose oder dauerhafte Dienstzusage. Für Benutzer nennt der aktuelle [Integrationsartikel](https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute) tägliche Kontingente und optional mehr Zugang über iCloud+. Es werden weder konkrete Tageszahlen noch Preise erfunden. Kein Abo wird vorausgesetzt, empfohlen oder abgeschlossen.

## Nicht gleichsetzen

| Pfad | Ausführung und Datenweg | Stand in HomeView |
| --- | --- | --- |
| `SystemLanguageModel` | Konkretes Apple-On-Device-Modell; bereitstehendes Modell benötigt für Textinferenz keinen Cloud-Endpunkt | Optional nach bewusster Auswahl implementiert; nur gesendeter Text/temporärer Dialog, keine App-Daten oder Tools |
| Eigener/anderer Cloud-LLM | Eigener Anbieter, Vertrag, Authentifizierung, Kosten und Datenschutz; auch HTTPS macht ihn nicht zu PCC | Nicht konfiguriert; kein Server-Fallback, kein Gateway-Schlüssel |
| `PrivateCloudComputeLanguageModel` | Apple-PCC-Server; Netzwerk, Geräte-/Regions-/Systemverfügbarkeit, verwaltete Berechtigung und Tageskontingent | Öffentlicher bedingter API-Pfad belegt; **keine Instanz, Session, Anfrage oder Quota-Abfrage in dieser Recherche ausgeführt** |

Apple dokumentiert PCC als serverbasierten Pfad mit größerem Kontext und zusätzlichen Reasoning-Stufen. Die beschriebenen 4K-/32K-Kontexte und täglichen Dienstgrenzen sind aktuelle Anbieterangaben, keine selbst vermessene Kapazität oder Performancegarantie. Das aktuelle lokale App-Limit von vier Gesprächspaaren/6000 Zeichen ist eine eigene, davon getrennte Grenze.

Der [Apple-Sicherheitsartikel](https://security.apple.com/blog/private-cloud-compute/) beschreibt eine eigene Cloudarchitektur mit gehärteter Plattform und Datenschutzmechanismen. Das ist eine Herstellerbeschreibung, keine hier durchgeführte unabhängige Sicherheitsprüfung. Weder ein externer LLM-Aufruf noch lokale Modellinferenz noch `LocalAuthentication` belegen PCC-Verarbeitung. „Privat“ bedeutet hier insbesondere nicht, dass ein PCC-Prompt das Gerät nie verlässt.

## Bewusste Anbieterwahl bleibt maßgeblich

Die aktuelle App wählt ausschließlich den konkreten On-Device-Typ und registriert keine Tools. Quellen, Generator und Projekt enthalten keinen konfigurierten PCC-Entitlement-Pfad oder Modellkonstruktor. Der sichtbare Hinweis **No cloud fallback** bleibt richtig. Die Informationsansicht, Auswahl oder ein Modellfehler senden keinen Entwurf an einen anderen Anbieter. Es wurden keine Produktquellen, Entitlements, Betriebssystemeinstellungen, Benutzerkonten oder Providerzugänge geändert.

Soll später tatsächlich PCC implementiert werden, müssen berechtigtes Signing/Verteilung, Geräte-/Regionsbereitschaft, Netzwerk-/Dienstfehler und `quotaLimitReached` samt unbekanntem Resetzeitpunkt bewusst behandelt und real geprüft werden. Vor einer Datenübertragung wäre eine ausdrückliche separate Anbieter-/Datenschutzwahl nötig. Kein stilles Hochstufen eines lokal gewählten Prompts, kein automatischer Aboweg und keine pauschal behauptete Fehler-/Kostenfreiheit. Das ist eine künftige Implementierungsgrenze, kein bereits gebauter Adapter.

## Nachweis und verbleibende Grenze

Vier **reine Typprüfungen** bestehen mit den installierten OS-27-SDKs: iOS, macOS, visionOS und watchOS. Eine getrennte tvOS-Negativprüfung wird vom Compiler mit der erwarteten ausdrücklichen Nichtverfügbarkeit abgewiesen. Die Probe nimmt einen bereits gelieferten Modellparameter an, statt selbst ein Modell zu erzeugen; sie hat keinen Einstiegspunkt und wurde weder gelinkt noch ausgeführt. Keine Aktivierung, Inferenz, Quota-Nutzung oder Erhebung realer Accountberechtigung. [Probequelltext](verification/pcc-api-surface.swift) · [Ergebnisse und Quellenbindung](verification/private-cloud-compute-boundary.json).

Alle 168 bisherigen App-/Test-/Ressourcen-/Projekt-Eingaben wurden vor und nach der Recherche bytegleich geprüft. Die Änderung betrifft nur Dokumentation und Metadaten; die erfolgreichen 214 Modelltests und fünf Produkt-Builds aus #33 werden nicht als neue PCC-Tests umetikettiert oder unnötig wiederholt. Der fehlgeschlagene Aufruf der verkürzten Security-URL ohne `/blog/` bleibt als 404 dokumentiert, nicht als Beleg fehlender Technik.

Damit ist #70 als geforderte Bilanz abgeschlossen. **F099 ist nicht implementiert oder live abgenommen.** Nur eine spätere ausdrücklich gewählte, berechtigte und real geprüfte Integration könnte diesen Produktstatus ändern. Apple Home bleibt deaktiviert.
