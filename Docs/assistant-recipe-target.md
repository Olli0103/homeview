# Rezeptkarte öffnet ihr eigenes Beispiel

20. Oktober 2026 · Teilfix von [#36](https://github.com/Olli0103/homeview/issues/36). Produktstand `2b223b7`; vollständige Nachweise im [Prüfbericht](verification/assistant-recipe-target.json). Das übergreifende Karten-/Accessibility-/Original-Issue bleibt offen.

## Vorherfehler

Die gebündelte Assistentenkarte bezeichnet „Butternut Squash Soup“. Ihre Aktion navigierte jedoch zur allgemeinen Rezeptansicht, die das aktuell ausgewählte Rezept liest. Mit dem ausschließlich lokalen Browserfixture wurde „Second local recipe“ ausgewählt und dessen Kochmodus geöffnet. Der anschließende bewusste Karten-Tap zeigte auf beiden Simulatoren dieses andere Rezept. Beide fehlgeschlagenen UI-Ausführungen und die tatsächlichen Zielbilder sind erhalten.

Eine zusätzliche tatsächliche AppModel-Probe setzt `OTHER_RECIPE_CANARY`, beginnt dessen Kochmodus und wechselt zu Schritt 2. Vor der Änderung bestehen 48 von 50 Assertions: Die Zielroute ist falsch; außerdem fehlt die gewünschte unabhängige Leseansicht. Dies sind ein reproduzierter Auswahlfehler und ein zusätzlicher Zielvertrag, nicht zwei unabhängige Produktfehler. Die vollständige Snapshot-Erhaltung bestand bereits vorher.

## Korrektur

Die Karte sagt jetzt **Read bundled recipe** und öffnet eine eigene vorübergehende Route. Die Leseansicht verwendet ausschließlich `RecipeDocument.soup`, nicht `model.recipe`: eigene vorhandene Suppenillustration, Zutaten und Schritte. Der sichtbare Hinweis erklärt den schreibgeschützten Charakter. Es gibt dort keine Kochstart-, Timer-, Pin- oder Handoff-Aktionen.

Die Aktion ruft ausdrücklich nicht `setRecipe(.soup)` auf. Dadurch ersetzt sie kein ausgewähltes Importrezept und setzt weder Kochfortschritt noch Handoff zurück. Sie schreibt keine Snapshot-Felder; die zusätzliche Route ist nicht Teil des gespeicherten Schemas. Der mindestens 44 × 44 native Punkte große Back-Button kehrt mit ungesendetem Entwurf zum Assistenten zurück. Wie bei sonstiger Navigation wird die frühere Karte verworfen.

## Nachweise

- **301 aktuelle Modelltests**, **50 tatsächliche AppModel-Assertions** und **fünf SDK-Builds** bestanden. Die native Probe erhält den vollständigen Snapshot, das ausgewählte Canary-Rezept, den aktiven zweiten Kochschritt und den ungesendeten Aktionsentwurf. Keine Produktionsmethode ersetzt; nur ein lesender Store-URL-Zugang an die externe Probe angehängt.
- Acht abschließende UI-Ausführungen: korrekte Suppe bei anderer Auswahl, Back-Rand und Entwurf, bisherige Auswahl vor/nach eigenem App-Prozessneustart, Zutat im sichtbaren Scrollbereich bei Hoch-/Querformat sowie bestehende explizite Karten-/Randaktion ohne Ausführung des ungesendeten Timerbefehls.
- Die erste korrigierte Produktrunde scheiterte in zwei neuen Tests an einer falschen Annahme des Testautors: Der App-Drawer öffnet das aktuelle Rezeptcover, nicht die Bibliotheksliste. Richtige Suppenansicht und Back wurden zuvor erreicht. Die Folgerunde verlangt deshalb den tatsächlichen Cover-Titel und Startknopf vor/nach Neustart, nicht einen dort nie vorgesehenen Bibliotheksknopf. Der Fehlstand bleibt archiviert; die Produktdateien wurden dafür nicht geändert.

Die Neustartprüfung belegt die gespeicherte Rezeptauswahl, **nicht** persistierten Kochfortschritt. Aktiver Kochfortschritt ist separat in derselben nativen Prozessinstanz belegt. Kein Systemneustart, keine Hintergrund-Ausführung und keine Prozesswiederherstellung behauptet.

## Eingaben und Bilder

206 Quellen und je 28 kompilierte UI-Eingaben einschließlich installierter Appbytes gebunden. Sechs Archive vollständig zurückgelesen; 82 PNGs dekodiert, sechs Übersichten und neun zusätzliche Vollbilder gesichtet. 16 ausgewählte Bilder im Prüfbericht. Historie: 18 UI-Ausführungen, 14 erfolgreich, vier frühere Fehler; final acht PASS, keine Skips oder Runtime-Warnungen. Die ersten App-Fensterbilder im Querformat hatten falsche Crop-Koordinaten des Simulator-Runtimes. Sie bleiben erhalten; die Abschlussbilder verwenden den ganzen Bildschirm und prüfen dessen orientierte Punktmaße gegen das App-Fenster.

## Grenzen

Eigene begrenzte Korrektur, keine Original-Siri- oder Pixelgleichheit. Keine tatsächliche VoiceOver-/Switch-Control-/Dynamic-Type-/Hardware-Abnahme, keine dynamischen API-Karten oder persönlichen Rezeptdaten. Bild und Inhalte sind gebündelte eigene Beispiele; keine externen Bilder oder Links geöffnet. Keine reale Authentifizierung, Aufnahme, Systemalarmfreigabe oder Live-Activity. F046 bleibt partial, parity=false. **Keine Home-Anbindung.**
