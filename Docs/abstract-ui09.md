# UI09: abstrakte Digitaluhr

30. Oktober 2026 · [#19](https://github.com/Olli0103/homeview/issues/19)

Die bislang fehlende UI09-Ansicht ist als **Abstract** auswählbar. Das ist unsere Arbeitsbezeichnung, kein bestätigter Apple-Name und keine behauptete Identität mit Flow. Der Katalog enthält weiterhin dieselben24Quellen,51Referenzzustände und13visuellen Originalgruppen.15Replik-Identitäten sind keine15bestätigten Original-Faces.

## Referenzgebundene Konstruktion

UI09 ist der archivierte544×544-Ausschnitt der P01-Montage (SHA-256 `5dc101060d5dd1d136ecf77bb953d8d6d172f24fc95b3bb2c5d374f5ef4c7a56`). Er zeigt10:09: rechts oben und links unten gefüllte ovale Nullen; links oben Punkt und senkrechte Kapsel; rechts unten halbe Schale, Punkt und Kapsel. Eigene geometrische SwiftUI-Pfade bilden diese beobachteten0/1/9-Komponenten nach. Keine Bildtextur, Fontdatei oder aus Apple-Binärdaten extrahierte Kontur wird geladen.

Die Zellen im eigenen600-Punkte-Vertrag liegen bei `(122,58,168,226)`, `(308,60,210,226)`, `(95,308,214,234)` und `(309,310,185,230)`. Das sind nachvollziehbare eigene Näherungen an die sichtbare Komposition, keine native Originalmessung. UI09 enthält weder eine vollständige0–9-Familie noch einen Editor oder eine bekannte Animationsphase. Die anderen Ziffern verwenden vorhandene eigene Konturen; sie werden nicht als belegte Apple-Glyphen ausgegeben.

Öffentliches `glassEffect` auf unterstützten Zielen, ein Materialfallback und ein eigener analytischer Rosa-/Blau-/Cyan-Farbgrund liefern die Darstellung. Glasbrechung, Flüssigkeitsphase, fotometrische Farben und genauer Originalalgorithmus bleiben abweichend/unbewiesen. Diese Lieferung beansprucht keine vollständige Material- oder Pixelparität. Der bestehende Flow-Renderer bleibt unverändert.

## Verhalten

Die Uhr liest denselben Zeit-/Zeitzonenwert wie die anderen Faces. Normalbetrieb folgt dem lokalen12-/24-Stundenformat; der kontrollierte Referenzmodus bleibt24-stündig. Auswahl wird im vorhandenen Face-Speicher gehalten. Die abstrakte Uhr bildet genau ein lesbares Accessibility-Element mit tatsächlichem Zeitwert. Der vorhandene Nachtpfad, Reduce Motion und inaktive ScenePhase bleiben wirksam; kein eigener Hintergrundtimer.

## Gemeinsame Prüfung

469Coretests bestanden nach Aufnahme der neuen Face-Identität. Vier erste Simulator-Flows bestanden funktional auf iPhone/iPad (Auswahl, Neustart, Nacht-Rückkehr, Zeitzone und Zeitwechsel). Ihre Bilder zeigten dennoch innere Überlappungskanten bei den eigenen Ersatzziffern. Dieser visuelle Fehler bleibt im Kandidaten dokumentiert; er ist kein visueller PASS. Nur die Fallbackpfade wurden mit öffentlichem `Path.normalized` vereinigt. Die anschließende Sichtung erkannte außerdem zu ähnliche2/5/8 bei maximaler eigener Strichstärke. Eine native Host-Zeichnung der tatsächlichen Pfade verglich die vorhandenen Achsen; nur dieser Fallback nutzt nun die vorhandene minimale Stärke. Beide visuellen Zwischenstände bleiben getrennt erhalten. Die beobachteten0/1/9-Pfade und bestehenden anderen Faces sind davon unberührt. Ein separater nativer Host-Geometriecheck prüft40Pfad-/Zellenkombinationen und die1/2/3-Komponenten von0/1/9; das ist kein Simulator- oder Originalvergleich.

Der erste abschließende Buildaufruf verlangte unbeabsichtigt x86_64 neben den vorhandenen arm64-Paketmodulen und scheiterte vor jeder UI-Ausführung an FeedKit. Der korrigierte arm64-Aufruf ändert keine Produktquelle. Abschließende native und SDK-Ergebnisse stehen im [Prüfbericht](verification/abstract-ui09-20261030.json).

## Ursprünglicher #19-Vertrag

Der analoge Block ist in [Numerals: beobachtete Varianten](numerals-observed-variants.md) und den dort verknüpften UI10/S07-/UI13-/UI45-Vergleichen dokumentiert. UI09 ergänzt die fehlenden abstrakten Formen und10:09-Komposition. Unbelegte Ziffernfamilien, unbekannte Originalsekunden, private Fontidentität und physische Farbmessung werden nicht erfunden. Vollständige Original-/Animationsparität bleibt ein eigener offener Vertrag; Home-, Geräte- und Signingpausen bleiben unverändert.

## Abschließender Paketstand

Alle fünf SDK-Builds bestanden; iOS benötigte die bereits dokumentierte einmalige reguläre AppIntents-Metadaten-Recovery. Zehn native Ausführungen insgesamt funktional grün, aber zwei visuell verworfene Zwischenstände ausdrücklich erhalten. Abschließend wurden die zwei betroffenen Zeit-/Zeitzonenmethoden auf iPhone/iPad nach der Fallbackkorrektur bestanden; unveränderte andere Suites nicht erneut gestartet. Beide installierten Apps mit je20Dateien exakt zum Testarchiv. Aktueller nativer Host-Geometriecheck40Pfadfälle bestanden.

Acht aktuelle eigene Zeitansichten, sechs vorherige unveränderte Referenz-/Neustart-/Tagesrückkehransichten und beide Nachtbilder tatsächlich gesichtet, ebenso der12er-Kontakt der ersten Korrektur einschließlich Numerals/Fade. Vier eigene finale Ansichten veröffentlicht. 77SDK-Dateien und alle sieben Quellen-/Binärarchive vollständig zurückgelesen. Bestehende Flow-/Numerals-/Ressourcenbäume unverändert; nur neue Face-Routingzeile ergänzt.
