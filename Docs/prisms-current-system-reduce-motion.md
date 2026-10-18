# Aktueller App-Stand: echter Systemschalter für Reduce Motion

18. Oktober 2026 · Zusatznachweis auf Basis `8bc262ab` nach der
[blauen Prismenpalette](prism-blue-balance.md). App-Code und Standard-Testtarget unverändert.

**Zwei native Ausführungen bestanden**, null Fehler, Skips oder XCTest-Runtime-Warnungen.
Auf verwalteten iPhone-/iPad-Simulatoren wurde der tatsächliche Schalter unter
Einstellungen → Bedienungshilfen → Bewegung → Bewegung reduzieren zweimal ein- und
ausgeschaltet. Beide Phasen verwenden identische App-Argumente einschließlich
`--animation-test`, ausdrücklich ohne `--reduce-motion`-Override.

Je Gerät sind alle **16 Standbilder** über zwei Kaltzyklen als ganze RGBA-Viewports
und PNG-Dateien exakt gleich. Die vier bewegten Kontrollbilder je Gerät zeigen
positive Unterschiede. Keine RGB-Toleranz. Alle 40 eigenen PNGs wurden dekodiert
und auf vier Kontaktbögen tatsächlich gesichtet. 16 zeitgestempelte Schalter-Rücklesungen
bestätigen die Übergänge und den wiederhergestellten Ausgangswert **aus** auf beiden Geräten.

## Bindung an die veröffentlichte App

Die ausgeführte App stammt unverändert aus dem bestandenen Palette-Prüflauf:
alle zehn App-Dateien SHA-256-exakt. Auch die tatsächlich installierten Pakete
wurden auf beiden Simulatoren vollständig gegen diese zehn Dateien rückgelesen.
App, privater Runner und Prüfeingaben bleiben zwischen beiden Geräten identisch;
alle 20 Eingabedateien vor/nach dem Lauf unverändert und privat SHA-verifiziert archiviert.

App-/Standardquellen: 142 Dateien, Digest
`6750246c7ddb1bb6bf13ab32797f291aaa2c49b5d95bebfabc5cf557f701c44d`.
Der private Prüfharness ergänzt ausschließlich den bereits veröffentlichten
[optionalen Test](verification/prisms-system-reduce-motion-fixture.swift.txt).
Basis-Testfile, Einfügefragment einschließlich zusätzlichem LF und vollständiger
Prüfquellenstand sind im [Nachweis](verification/prisms-current-system-reduce-motion.json)
bytegenau gebunden. Er wird nicht in das Standard-Testtarget übernommen.

Keine neue App-Implementierung und kein erneuter SDK-Durchlauf: Die vorhandenen
166 Modelltests, 14 regulären UI-Ausführungen und fünf SDK-Builds gehören zum
unveränderten Palette-Stand. Diese zwei Systemschalter-Läufe sind ein eigener Zähler.
Der [ältere Systemnachweis](prisms-system-reduce-motion.md) bleibt historisch erhalten.

[Eigene Bilder und Hashes](screenshots/goal-20261018/prism-current-system-motion-manifest.json).
Keine privaten Originalbilder, echten Bibliotheken, Geräte, Konten, Systemalarme
oder Durchsagen. Keine Host-Einstellung verändert.

## Grenze

Belegt ist dieser Home-Modular-Zustand auf den beiden iOS-27-Simulatoren.
Vollständige Accessibility, physische Hardware/Energie, Originallicht/-brechung
und Originalbewegung bleiben offen. Kein aktueller Gesamtsuiten- oder interner
UIKit-Ursachennachweis. [Issue 20](https://github.com/Olli0103/homeview/issues/20) bleibt offen.
