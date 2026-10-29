# Sichtbare Antwortkarten beim bewussten Vorlesen berücksichtigen

29. Oktober 2026 · begrenzte Ergänzung zu [#36](https://github.com/Olli0103/homeview/issues/36). Keine VoiceOver-, Siri-, Live-Karten- oder Original-Parity-Abnahme.

## Reproduzierte Auslassung

`answerReadoutText` lieferte bei lokalen Antwortkarten nur den Antwortsatz. Dadurch fehlten unter anderem Absender/Zeit/vollständiger Nachrichtenauszug, die drei Agenda-Einträge und die sichtbaren Rezeptangaben. Auch die sichtbare Beispielkennzeichnung und Quellennamen fehlten. Der bestehende tatsächliche AppModel-Prüftreiber wurde vor jeder Produktänderung um diese Erwartungen erweitert; alle 165 Produkt-/Ressourceneingaben entsprachen dabei exakt `1740308`.

In der unveränderten 76-Assertion-Matrix scheitern vorher **18 Assertions**: sieben Karteninhalte, sieben Beispielkennzeichnungen und vier vorhandene Quellennamen. Antwortsatz, ungesendeter Entwurf, Zustands-/Aktionsgrenzen und andere Kontrollen bleiben grün. Native Ausführung verwendet einen eigenen UUID-Speicher und keine gebündelte Audiodatei. Keine Produktionsmethode ersetzt; Quellen, verlinkte Paketobjekte und ausgeführte Binärdateien archiviert. Importierte Modulinterfaces und Apple-SDK-/Compilerinternas sind nicht separat manifestiert, keine allgemeine Toolchain-/Hardwaregarantie.

## Nur vorbereiteten Text ergänzt

Zwei Produktdateien: `AssistantResponseDocument` stellt einen deterministischen Vorlesetext aus der geschlossenen Beispielart bereit; `AnswerSpeechActions` verwendet ihn, wenn eine solche Karte ausgewählt ist. Der normale AI-/Plaintext-Pfad bleibt unverändert. Layout, Bilder, Provider, Textdarstellung und Actions werden nicht geändert. Keine weitere Abhängigkeit; `RecipeDocument` war bereits in der reduzierten Watch-Quellenliste enthalten.

| Karte | Zusätzlich berücksichtigter sichtbarer Inhalt |
| --- | --- |
| Wissen/Bild | Bildbeschreibung und Hinweis auf eigene, nicht historische Illustration |
| Agenda | Tag, Titel und Detail aller drei Einträge in sichtbarer Reihenfolge |
| Fiktive Nachricht | Absender, Zeit, vollständiger wörtlicher Auszug und Read-only-Hinweis |
| Rezept | Eigenes Suppenbild beschrieben, Titel, gebündelte Quelle, Dauer und Portionen |
| Lade-/Leer-/Fehlerbeispiel | Sichtbare Erklärung, dass kein Live-Abruf, Ergebnis oder automatischer Retry vorliegt |

Beispielkennzeichnung und sichtbare Quellennamen werden mitgelesen. Versteckte Quellenblatt-Texte/URLs, Zutaten/Schritte der noch nicht geöffneten Rezeptansicht und Folge-/Aktionsbuttons nicht. Die Rezeptangaben stammen vom gebündelten Suppenrezept, nicht einem anderen ausgewählten Nutzerrezept. Nachrichten-/Providertext wird dadurch nicht zum Kartenformat, Befehl, Link oder SSML umgedeutet. Alle sieben festen Beispiele bleiben innerhalb der vorhandenen 4000-Zeichen-Grenze; kein stilles Abschneiden eingeführt.

Geräteentsperrung startet weiterhin keine Sprache: Ein weiterer bewusster Read-Tap ist erforderlich. Kartenwechsel stoppt den bisherigen Vorlesevorgang, ebenso die bestehenden Hintergrund-/Mikrofon-/Navigations-/Sperrpfade. Kein automatisches Wiederaufnehmen, Senden oder Quellenöffnen; keine neue Persistenz des Vorlesetexts.

## Geprüfter Umfang

- **405 Coretests** bestanden, einschließlich sieben neuer Fälle für Umfang/Reihenfolge, wörtlichen Nachrichtentext, Ausschluss versteckter Inhalte, Beispielgrenzen und vollständige Übergabe an einen synthetischen Speech-Backend-Recorder. Die zwei bestehenden ungenutzten Bool-Ergebnisse in anderen Tests bleiben Compilerwarnungen.
- **76/76 Assertions gegen das tatsächliche AppModel** mit identischem erweitertem Testtreiber bestanden. Die 18 Vorherfehler bleiben erhalten, nicht nachträglich umetikettiert.
- **14 aktuelle native UI-Ausführungen**, sieben Methoden auf je iPhone/iPad: neuer Kartenwechsel-/Read-/Stop-/Entwurffall; vorhandene Stimmenwahl/Tempo/bewusstes Entsperren/Stop, unavailable/denied/muted, echter Hintergrund ohne Wiederaufnahme, synthetische Mikrofonvorschau sowie Nachrichten-/Rezeptkartenregressionen. Fixture-Speech ohne Lautsprecherausgabe; kein tatsächlicher VoiceOver-Test.
- **Fünf frische SDK-Builds** über den abgesicherten Buildweg und sechs unveränderte Tooling-Tests bestanden. 73 SDK-Produktdateien einschließlich vollständiger iOS-Metadaten archiviert/zurückgelesen.233 finale Quellen unverändert, aktuelle UI-Eingabearchive und installierte Appbytes geprüft.163 von165 Produkt-/Ressourceneingaben bytegleich.

Ein erster UI-Vorbereitungsbuild forderte auch x86_64 an, fand aber nur das arm64-FeedKit-Modul: null UI-Ausführungen aus diesem Build. Explizite arm64-/Device-Family-Vorgaben korrigieren ausschließlich den Buildaufruf; derselbe Produktstand besteht anschließend. Fehlerlog separat erhalten. Frühere UI-/Core-/OS-Shortcut-Ergebnisse werden nicht zu einer größeren heutigen Suite addiert.

[Quellen, native Vorher-/Nachherchecks, Archive, genaue UI-/SDK-Ergebnisse und Bildsichtung](verification/card-readout.json) · [eigene synthetische Appbilder](screenshots/card-readout).76PNG dekodiert, acht Übersichten und vier volle Einzelbilder tatsächlich gesichtet, sechs eigene Bildkopien bytegeprüft. Die Read-Zustandsbilder zeigen Header/Antwort und den synthetischen Sprachzustand; auf dem schmalen iPhone liegt die eigentliche Karte dabei unterhalb des aktuellen Scrollausschnitts. Separate Nachrichten-Belegbilder zeigen die vollständige Karte. Die vorbereiteten Texte und die synthetische Übergabe sind geprüft, nicht akustische Aussprache, tatsächliche Hilfsmittelansagen oder persönliche Live-Karten.

**#36 bleibt OPEN, F046 partial/parity=false.** Vollständige Originalgeometrie/-bewegung, dynamische persönliche Karten und tatsächliche VoiceOver-/Switch-Control-/Dynamic-Type-/Kontrast-/Geräteabnahme bleiben separat offen. Geräte-/Signing-Hold und Home-Sperre unverändert; keine realen Konten, Nachrichten/Anrufe oder Aufnahme. Der gesamte Backlogauftrag läuft weiter.
