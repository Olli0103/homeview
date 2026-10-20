# Reale Trefferflächen für Assistenten-Controls

20. Oktober 2026 · Teilfix von [#73](https://github.com/Olli0103/homeview/issues/73), Produkt-/Testcommit `4137efd`. Das umfassende Accessibility-Issue bleibt offen.

## Tatsächliche Vorherfehler

Vier Ansichten werden mit dem öffentlichen XCTest-Audit `.hitRegion` geprüft: Ausgangsansicht, sichtbare Kartenaktionen nach Scrollen, Quellenblatt und Fähigkeitenblatt. Alle Befunde werden ungefiltert gesammelt; anschließend muss die komplette Liste leer sein.

Auf dem iPad meldeten Ausgangs- und Kartenansicht drei kleine Kopf-Controls: **Capabilities and limits** (149,5 × 18 Punkte), **Unlock readout** (105 × 18) und **Answer voice settings** (20,5 × 16). Auf dem iPhone meldete die Ausgangsansicht Readout (104,67 × 18) und Einstellungen (21,33 × 16). Beim gescrollten Telefon-Kartenbild lagen die Kopf-Controls außerhalb des sichtbaren Bereichs; der leere Audit ist keine Abnahme verborgener Controls.

Der öffentliche Audit ist nicht identisch mit einer strikten 44-Punkte-Mindestgröße. Zusätzliche Größenassertionen stoppten den Rezept-Randtest bei nur **20,5 / 20,33 Punkten Höhe**. Der Quellenchip ließ sich bereits am oberen Rand öffnen; anschließend stoppte der Done-Test bei nur **40,5 / 40,67 Punkten Breite**. In diesen vier Fehlfällen wurde der jeweilige Rezept-/Done-Rand-Tap wegen der Größenassertion **noch nicht geliefert**. Ein fehlgeschlagener Tap wird nicht behauptet. Quellen- und Fähigkeitenblatt bestanden den öffentlichen Audit bereits vorher.

## Korrektur

Nur zwei Produktdateien geändert. Die drei Kopf-Controls erhalten mindestens 44 × 44 native Punkte große Labels mit rechteckiger Trefferfläche. Beim Rezeptknopf wird die bislang äußere Mindesthöhe in das tatsächliche Button-Label verlegt; die Folgebeispiele mit demselben Labelmuster erhalten dieselbe Behandlung. Done bekommt sein eigenes 44 × 44-Punkte-Label. Schrift- und Symbolgrößen bleiben erhalten; die Kopfzeile wird höher. Keine Pixelgleichheit behauptet.

Keine globale Button-Änderung. Der bereits funktionierende Quellenchip, Museumslink, Speak, Fähigkeitenblatt, Spracheinstellungsinhalt und AppModel bleiben unverändert. Es werden keine Audit-Ausnahmen eingeführt.

## Abschlussprüfung

| Prüfung | Ergebnis |
| --- | --- |
| Vier komplette Auditlisten je Gerät | alle acht leer |
| Drei Kopf-Controls | mindestens 44 × 44 Punkte, paarweise ohne Überschneidung |
| Tatsächliche obere/untere Kopf-Rand-Taps | Fähigkeiten und Einstellungen öffnen sich; Readout erreicht ausschließlich die verweigerte Mock-Freigabe, ohne reale Authentifizierung oder Sprache |
| Oberer Rezept-Rand | öffnet die Rezeptansicht; der ungesendete Timerentwurf erzeugt keinen Timer |
| Quellenchip / Done / Folgebeispiel | oberer Quellenrand öffnet das Blatt, unterer Done-Rand schließt es, oberer Folgenrand wählt die Beispielagenda |
| Regression | fertiger synthetischer Sprachentwurf bleibt ungesendet, Tastaturrotation erhält Entwurf und Eingabegeometrie |
| SDKs | iOS, macOS, tvOS, visionOS und watchOS gebaut |

**18 finale UI-Ausführungen bestanden**, neun Methoden auf beiden Simulatoren. Gesamte Historie: 30 Ausführungen, 23 erfolgreich, sieben frühere Fehler. Keine Skips oder Runtime-Warnungen in den Ergebniszusammenfassungen. Die numerische Frame-Toleranz bleibt ein millionstel Punkt; tatsächliche Rand-Taps liegen zwei Punkte innerhalb des jeweiligen Randes. Kein gelockerter Audit und kein center-tap-Fallback für diese Randaktionen.

206 Quellen, je 28 kompilierte Eingaben und installierte Appbytes gebunden. Beide Archive mit je 234 Einträgen vollständig zurückgelesen. 110 PNGs dekodiert, vier Übersichten und zwei zusätzliche eigene Bilder in voller Auflösung gesichtet; 18 ausgewählte Bilder im [Messbericht](verification/assistant-hit-regions.json). Die Bildprüfung bestätigt erreichbare Kopfzeile und getrennte Eingabe, nicht Originalgleichheit.

AppModel und 72 Core-/Coretest-Dateien bleiben bytegleich. Die früheren 301 Modelltests bei `add551c` sind historisch; für diese Label-/Hitflächenänderung wurde kein neuer Core- oder nativer AppModel-Lauf behauptet.

## Grenzen

Die Audits gelten nur für die vier aufgenommenen sichtbaren Zustände, nicht alle verborgenen Beispiele, Provider oder Hilfsmittel. Tatsächliche VoiceOver-/Switch-Control-, Fokus-/Ansagen-/Dynamic-Type-/volle Kontrast-, Hardware- und Originalabnahme bleiben offen. Der Museumslink wurde nicht aktiviert. Authentifizierung und Sprache sind ausschließlich explizite Testfixtures; keine reale Mikrofonaufnahme, Systemalarmfreigabe oder neue Live-Activity.

Das Quellenblatt wird in den vollständigen Screens gezeigt. Sein zusätzliches „Viewport“-Bild ist nur der Ausschnitt der dahinterliegenden Referenzfläche und keine Behauptung, das gesamte native Blatt liege darin. Ursprüngliche Kriterien und F103 ohne Parity bleiben unverändert. **Keine Home-Anbindung.**
