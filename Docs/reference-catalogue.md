# Referenz- und Face-Katalog: abgeschlossene Inventur

22. Oktober 2026 · [BASE-02 / #2](https://github.com/Olli0103/homeview/issues/2), [FACE-01 / #5](https://github.com/Olli0103/homeview/issues/5).

Diese beiden Pakete verlangen einen verknüpften Zustandskatalog und einen geprüften Zustand **oder eine benannte Lücke** je Referenz-Face. Sie verlangen keine erfundene Kenntnis unveröffentlichter Screens. Die Inventur ist abgeschlossen; die offenen Renderer-, Gesten-, Editor-, Rechte- und Geräte-Issues werden dadurch nicht geschlossen. F001 und sämtliche Original-Paritywerte bleiben `false`.

## Ein gemeinsamer, nachprüfbarer Bestand

[Maschinenlesbarer Zustandskatalog](reference-states.json) · [öffentlicher Strukturcheck](verification/check-reference-states.py) · [Prüfbericht](verification/reference-catalogue.json).

| Einheit | Geprüfter Bestand |
| --- | --- |
| Quellen | 24 archivierte Quellen mit datierter Herkunft, URL und aktuellem Datei-Digest |
| Bildreferenzen | 51 IDs, keine doppelten Zielpfade; 12 Montageausschnitte, 11 Geräte-Renderings, neun perspektivische Eventfotos, 15 Filmstichproben und vier GIF-Stichproben |
| Native Original-Pixelscreens | **Null.** Die 600×600-Punkte-Geometrie ist unser Replikvertrag, nicht das Dateiformat jedes Originals |
| Funktionskatalog | 105 Funktionen mit konkreten Quellen, Datums-/Geometriebasis und Unsicherheit; 47 mit direktem UI-Locator, 58 ohne eigenen vollständigen UI-Locator |
| Bewegung | Vier Original-GIFs mit 101 tatsächlich dekodierten und zeitlich geprüften Stichproben; Zeitstempel aus den GIF-Frame-Dauern |
| Private Dateien | 216 Dateien vollständig gelesen und gegen das vorhandene datierte SHA-/Byte-Manifest geprüft; 51 Ausschnitt-/Formattransformationen pixelgenau nachgerechnet |
| Sichtprüfung | Fünf Referenztafeln mit allen 51 Bildern und vier Original-GIF-Kontaktbögen erneut gesichtet |

Ein späterer [gezielter Quellen-Delta vom 22. Oktober](reference-delta-20261022.md) bleibt separat; er ersetzt keine Vollinventur und ändert die folgenden eingefrorenen Zähler nicht.

**Nachprüfung und Begriffskorrektur, 29. Oktober:** Erst [158 Frames zweier vorhandener GIFs](transition-reference-review-20261029.md), anschließend [alle vier Folgen mit299 vollständig dekodierten Frames](remaining-original-gifs-20261029.md) gesichtet. Die historische S07-Quellenbeschreibung „vier Gesten-GIFs“ ist zu weit: `SLGADnGeMyNj6CZ6geg9VP` zeigt eine Snoopy-Animation, keine Navigation; eine weitere Folge zeigt eine Assistentenantwort ohne sichtbaren Auslöser. Vier animierte GIFs sind nicht vier Gestentraces. Der eingefrorene Rohkatalog/Prüfstand bleibt erhalten; seine Bewegungs-/Reihenfolgeaussagen sind mit dieser Korrektur zu lesen. Keine neuen Quellen-/Referenzzahlen oder vollständige Gestenabnahme daraus.

Der Recherche-Cutoff ist **16. Oktober 2026**, der erneute Byte-/Katalogcheck **22. Oktober 2026**. Das ist keine neue Web-Vollsuche, kein laufender Originalgerätezugriff und keine Behauptung unveränderter aktueller Produktverfügbarkeit. Der bereits archivierte Hauptfilm hat 187,52 Sekunden und 188 Ein-Sekunden-Stichproben; Kurzfilm/Browseraufnahme und der gesampelte 833,401-Sekunden-Hands-on-Film sind im Quellenbestand getrennt dokumentiert. Narration ist kein Button-/Bewegungsnachweis.

Originalmedien bleiben ausschließlich in der privaten Projektakte. Hier werden **keine** Originalfotos, Referenz-Crops, GIFs, Fonts oder extrahierten Konturen als App-Assets veröffentlicht. Öffentliche Quellenlinks und Hash-/Geometriemetadaten sind davon getrennt.

## Sichtbare Face-Gruppen und aktueller Stand

Varianten sind keine zusätzlichen eindeutig benannten Faces. Der Katalog lässt deshalb die Gesamtzahl eindeutiger Original-Face-Identitäten ausdrücklich offen.

| Sichtbare Gruppe | Referenz | Aktuelle Replik / konkrete Lücke |
| --- | --- | --- |
| Modular | UI01, UI39 | Modular vorhanden; exakte Typografie, Material und weitere Widgetkombinationen unter #78/#7 offen |
| Albumvariante | UI02 | Photos vorhanden; vollständiger Original-Auswahldialog und Wechselalgorithmus unter #11 offen |
| Snoopy Tag/dunkel | UI03, UI06 und eigener S07-Animationsclip | Nicht implementiert; am 29. Oktober vom Eigentümer wegen der Rechte ausgeschlossen, #14 `not_planned`. Kein Parity-PASS; [Scope](scope-exclusions.md) |
| Foto-Tiefenuhr | UI04, UI11, UI36 | Photos vorhanden; Originalformen, Algorithmus und native iPad-Segmentierung bleiben unter #11/#78 offen |
| Wetter | UI05, UI19, UI20 | Weather vorhanden; Nah/Fern unterschieden, komplette Effekte/Licht unter #21 offen |
| Home Modular | UI07, UI21 | Home Modular vorhanden; Prismendetail unter #20, echte Home-Quelle ausdrücklich gesperrt |
| Monatskalender | UI08 | Calendar vorhanden; restliche Locale-/Monats-/Stildetails unter #22 offen |
| Unbenannte Digitalvariante | UI09 | Name/Identität ungeklärt; nicht stillschweigend zu einem weiteren bekannten Face oder zu Flow erklärt |
| Große analoge Ziffern | UI10 | Arbeitsname Numerals; vollständige Formen-/Zeit-/Stilabnahme unter #19 offen |
| Verblassende analoge Ziffern | UI12 | Arbeitsname Fade; vollständige Original-Zeitkurve unter #18 offen |
| Große Home-Analoguhr | UI45 | Home Modular Clock vorhanden; Perspektive, exakter Name/Licht weiterhin begrenzt belegt |
| Reaktive Digitaluhr | UI47 | Pressebeschriftung nennt Flow; Formen/Fluid unter #15/#16 offen, Foto ist kein nativer Pixelscreen |
| Kameraface | UI40 | Home Camera mit gekennzeichneten synthetischen Standbildern; keine echten Streams, #27 bleibt gesperrt |

**Watch Modular, Infograph Modular, Modular Duo und Modular Compact sind vier optionale Watch-inspirierte Zusatzlayouts.** Sie zählen weder als vier fehlende HomeView-Originale noch als Ersatz für Snoopy oder UI09.

## Reihenfolge und Styles: belegt versus unbekannt

Die Lesereihenfolge UI01–UI12 einer Marketingmontage ist **keine** bestätigte Carousel-Reihenfolge. Ein gesampelter Event-GIF zeigt nacheinander reaktive Ziffern, verblassende Analoguhr, Modular mit Agenda, Foto-Tiefenuhr und große Home-Analoguhr. Die Endpunkte bei 0/630/2310/3780/5250 ms und die überlappenden Zwischenbilder sind dokumentiert. Das ist eine beobachtete Teilfolge, keine komplette Originalreihenfolge oder gemessene Wischgeschwindigkeit.

Der aktuelle Replik-Carousel besitzt 14 stabile Identitäten in der deklarierten Enum-Reihenfolge. Sieben Layouts bieten die vorhandenen zwei Farboptionen, Flow bietet Solid/Stencil und Hintergrund an/aus. Sechs andere Faces haben keine solche Editoroption. Die vollständige Originalpalette ist aus dem einzelnen Farbeditor-Foto UI37 nicht rekonstruierbar; diese Lücke bleibt #7 zugeordnet. Der aktuelle Default jedes Faces ist aufgenommen, nicht jede denkbare Stylekombination als Original akzeptiert.

## Fehlende und widersprüchliche Zustände

Der JSON-Katalog enthält 18 konkrete Lückengruppen für Einrichtung, Face-Editor, Gesten, Nacht/Nah-Fern, Fotoauswahl, Timer, Weltuhr/Wecker/Reminder, Kalender, Browser/Rezept, Kamera, Spiegel, Identität/Privatsphäre, Assistent, Musik, Systemdienste, Fehler/Leerzustände, Hilfsmittel und Geräteperformance. Jede Gruppe verlinkt ihre Folge-Issues und tatsächlich vorhandenen Teilbelege. Perspektive, Gerätegehäuse und Marketingkamera-Zoom werden nicht in Pixelgeometrie oder gemessene UI-Latenz umgedeutet.

Der obere Siri-/Control-Center-Gestenbereich bleibt aus widersprüchlichen Quellen räumlich ungeklärt. Alle ursprünglichen Zustände von Accounts, Offlinefehlern, leeren Varianten und Geräte-Unterbrechungen sind weiterhin nicht vollständig öffentlich dokumentiert. Diese Abweichungen sind keine Erlaubnis, das Kopierziel durch einen eigenen Stil zu ersetzen.

## Reproduzierbarkeit leerer/entfernter/neuer Varianten

Vier neue Coremethoden prüfen am vorhandenen Decoder: unbekanntes/entferntes ausgewähltes Face fällt auf den bestehenden Home-Default zurück, ohne dessen Stil zu übernehmen; leere/falsch typisierte Auswahl erhält Nachbar- und Profildaten; ein neu gewähltes Face erbt keine fremde Konfiguration; bekannte und unbekannte inerte Konfigurationsdatensätze bleiben über kanonisches Speichern getrennt. Dabei werden alle 14 aktuellen Identitäten berücksichtigt. Kein künstliches unbekanntes Face wird als öffentliche Produktvariante angezeigt.

Der gemeinsame vollständige Corelauf besteht **356 Tests**. Der neue UI-Inventurfall läuft einmal je iPad/iPhone: **zwei erfolgreiche Ausführungen mit je 14 tatsächlich gestarteten Face-Zuständen**, keine 28 unabhängigen Tests. Keine Fehler, Skips oder strukturierten Runtimewarnungen. 56 eigene PNGs dekodiert, zwei aktuelle Tafeln gesichtet, 28 eigene Face-Viewports publiziert. Photos verwendet ausdrücklich eine geometrische Testfixture, nicht ein Originalfoto oder eine echte Bibliothek. Andere Quellen bleiben MockHome/Fixture; keine Kamera, Accounts, Systemalarme, Musikstarts, Anrufe oder Nachrichten.

Produktquellen und Ressourcen bleiben bytegleich zu `505f003`; nur Tests und diese Inventur wurden ergänzt. Der iOS-Testbuild ist neu, die früheren fünf SDK-Builds werden nicht als neue Läufe ausgegeben. Quellen, App-/Test-/Launch-Eingaben und installierte Appbytes sind vor/nach gebunden. Katalogabschluss ist **kein** neuer vollständiger visueller, Service-, Hardware- oder Gesamt-Parity-PASS.
