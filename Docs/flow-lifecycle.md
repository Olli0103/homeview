# Flow: Hintergrund, Rückkehr und Face-Wechsel

18. Oktober 2026 · Zusatz zur [Fünf-Minuten-Beobachtung](flow-five-minute.md).
Aktuelle App auf Basis `f3dfbe14`, **App-Code und Standard-Testtarget unverändert**.

Je eine native Ausführung auf iPhone und iPad bestanden: null Fehler, Skips oder
XCTest-Runtime-Warnungen. Derselbe App-/Runner-/Testbundle-Stand ohne Neubau zwischen
den Geräten. Alle zehn tatsächlich installierten App-Dateien wurden je Gerät
gegen das bereits geprüfte Palette-Paket SHA-exakt rückgelesen. Alle 21 gemeinsamen
Eingabedateien vor/nach dem Lauf unverändert und privat bytegeprüft archiviert.

## Tatsächlich geprüfter Wechsel

Die verwalteten Simulator-Einstellungen werden in den Vordergrund gestartet,
**ohne eine Einstellung zu ändern**. HomeView muss den Vordergrund verlassen,
aber weiter laufen. Die drei zeitgestempelten Rücklesungen je Gerät wurden
zusätzlich unabhängig auf explizite Hintergrundzustände 2 oder 3 geprüft;
unbekannt, beendet oder Vordergrund werden nicht als Hintergrund gewertet.
Die Einstellungen werden am Ende beendet.

Nach zwei solchen Rückkehrzyklen bewegt sich das Fluid weiterhin in den eigenen
festen erodierten Glyphenkörpern. Anschließend wechseln echte horizontale Gesten
von Flow nach Fade und zurück; der tatsächliche Fade-Zielzustand ist aufgenommen.
Auch nach dieser Rückkehr unterscheiden sich die zwei Flow-Körperbilder.
Die Maskierung entspricht dem bestehenden festen Glyphenmaterialtest.

Nach getrenntem Start mit CLI-Reduce-Motion bleiben dieselben Körperpixel vor der
Hintergrundphase, nach Rückkehr und 1,2 Sekunden später exakt gleich – keine
RGB-Toleranz. Kein tatsächlicher OS-Reduce-Motion-Schalter-Test für Flow.
Alle 22 eigenen nativen PNGs sind dekodiert und auf zwei Kontaktbögen tatsächlich
gesichtet; keine privaten Originalbilder.

## Vorheriger Fehlbefund bleibt erhalten

Zwei frühere native Versuche mit dem simulierten Home-Tastendruck scheiterten
bereits an der Vordergrundprüfung: Nach Home und zwei Sekunden meldete XCTest
weiter Zustand 4 (Vordergrund). Keine Wiederaufnahme oder Materialprüfung erreicht.
Quellen, Ergebnisse und alle 20 damaligen Eingabedateien bleiben privat exakt
archiviert. Die Ursache ist ungeklärt; der erfolgreiche Settings-Wechsel erklärt
sie nicht und etikettiert diese Versuche nicht in PASS um. Daraus folgt auch
keine nachträgliche Aussage über ältere, getrennte Prüfstände.

[Gebundener Nachweis](verification/flow-lifecycle.json),
[exakter optionaler Simulator-Harness](verification/flow-lifecycle-native-fixture.swift.txt),
[eigene Bilder und Hashes](screenshots/goal-20261018/flow-lifecycle-manifest.json).
Der Harness ergänzt nur das private UITestfile; die Original-Basisdatei und
Einfügung einschließlich eines zusätzlichen LF sind SHA-gebunden. Kein neuer
SDK-Durchlauf und kein Addieren zu den beiden früheren Fünf-Minuten-Läufen.

## Grenze

Belegt sind diese drei kurzen Hintergrund-/Rückkehrphasen und dieser Face-Wechsel
je Simulator. Nicht belegt sind CPU-/GPU-Ruhe oder Energie im Hintergrund,
Framezeiten, beliebige Dauer, Prozess-/Geräteneustart, physische Hardware,
globale Accessibility oder Originallicht/-bewegung. Nur synthetische Daten,
keine Konten, echten Bibliotheken, Homes oder Kommunikation. Issue 16 bleibt offen.
