# Profil-Editor: lesbare Textfarben im dunklen Sheet

29. Oktober 2026 · begrenzte Fortsetzung von [#73](https://github.com/Olli0103/homeview/issues/73), Gesamtissue offen.

## Befund und Korrektur

Der Root-Canvas setzt ein helles `colorScheme`, die äußere Präsentation dagegen ein dunkles bevorzugtes Schema. Im eigenen Profil-Editor blieben schwarze Haupttexte und ein ebenfalls kaum lesbarer sekundärer Hinweis auf dem dunklen Sheet. Die tatsächlichen nativen Vorherbilder zeigen das nach zwei Sekunden Wartezeit und erneutem Öffnen auf beiden Geräten.

Nur `PersonalHomeEditor` erhält eine ausdrückliche semantische Primärfarbe und ein lokales dunkles Farbschema passend zur bestehenden Sheet-Präsentation. Hintergrund, Layout, Schriftgrößen, Aktionen, Profile und der globale Canvas werden nicht umgebaut. Die vorhandene sekundäre Texthierarchie bleibt erhalten. Die zuvor vergrößerte Done-Fläche bleibt 44×44 Punkte.

## Vorab festgelegte Textprüfung

Vier wörtlich identifizierte native Textrollen, jeweils zwei ruhende Öffnungen auf iPhone/iPad: 16 eigene Messungen. Unveränderte Grenze **4,5:1**. Die Ausschnitte stammen aus den nativen AX-Textrechtecken; ein fester Ring von zwei logischen Punkten um jedes Rechteck bestimmt den Hintergrund. Keine aus dem Endbild angepasste Maske.

Vorher war selbst der **größtmögliche** Kontrast innerhalb jeder Textregion kleiner als 1,31:1. Dadurch hängt dieser Fehlbefund nicht von einer günstigen Vordergrundsegmentierung ab. Für einen aktuellen PASS gelten zusätzlich mindestens 99% einheitlicher Ringhintergrund und mindestens 100 Pixel der häufigsten kontrastierenden Glyphenkernfarbe. Die hellen Titel des bestehenden Fähigkeiten-Dialogs müssen als native Messkontrolle nach derselben Auswertung 21:1 erreichen.

| Textrolle | iPhone, Vorher-Obergrenze → aktuell | iPad, Vorher-Obergrenze → aktuell |
|---|---|---|
| Titel | ≤1,23 → 17,01 | ≤1,18 → 17,83 |
| Layout | ≤1,23 → 17,01 | ≤1,18 → 17,83 |
| Favorite apps | ≤1,23 → 17,01 | ≤1,18 → 17,83 |
| Demo-/Privatsphäre-Hinweis | ≤1,28 → 5,94 | ≤1,31 → 6,09 |

Alle 16 aktuellen eigenen Messungen bestehen, ebenso beide hellen Kontrollen. Alle 18 erfassten Texte und nativen Rechtecke sind exakt gleich zum korrigierten Vorherstand. Die Rückkehr zur persönlichen Oberfläche ist in jedem der beiden aktuellen Läufe strikt RGBA-pixelgleich; auch die vorherigen und aktuellen Ausgangs-Viewports stimmen überein. Nur dieser eigene Viewport wird verglichen, nicht OS-Uhr oder kompletter Bildschirm.

Die PNGs tragen eine sRGB-Kennung; die Auswertung dokumentiert Profil-/Konvertierungsregeln und verwendet die übliche sRGB-Luminanzformel. Schwarz/Weiß 21:1, gleiche Farben 1:1 und der knapp unter 4,5 liegende Grauwert 119 dienen als Formelkontrollen. Glyphenkern-/Hintergrundsampling bleibt eine begrenzte Screenshotmessung, keine vollständige WCAG-, Displaykalibrierungs- oder Hardwareabnahme.

## Native Rückkehr, Fehler und Quellenbindung

- Acht **aktuelle** UI-Ausführungen bestehen: zweimal die neue Kontrast-/Konfigurations-/Pixel-Rückkehrmethode, vier tatsächliche Done-Ecken und zwei echte OS-App-Umschalter-/Rückkehrfälle.
- Layout-/Favoritenlabels und -werte bleiben über erneutes Öffnen unverändert; Profil Alex bleibt gewählt. Kein Layout oder Favorit wird betätigt, die Mocktemperatur bleibt 68°.
- Der erste Vorherlauf scheiterte erst nach allen Messungen am abschließenden Thermostat-Aufruf: Der Test hatte ausdrücklich Modular gewählt, versuchte aber einen nur bei Home Modular vorhandenen Button. Beide Fehler bleiben historisch. Nur der finale Weg wurde vor Produktänderungen auf den tatsächlichen eigenen Home-Raster-Button korrigiert; dieselbe 68°-Assertion bleibt verpflichtend. Der korrigierte Vorherlauf besteht auf beiden Geräten und bestätigt dieselben 16 Kontrastfehler.
- Ein früher Zwischenschritt mit nur `Color.primary` hatte einen erfolgreichen UI-Testbuild und fünf SDK-Builds, aber **keinen UI-Lauf**. Nach Quellprüfung des Schema-Konflikts wurde er nicht als Farbkorrektur abgenommen. Die aktuelle lokale Schema-/Primärfarbenkombination besitzt einen eigenen eingefrorenen Buildstand.
- Fünf aktuelle SDK-Builds mit vollständigen iOS-Shortcut-Metadaten und 73 nach Bytes geprüften Produktdateien sowie sechs Tooling-Tests bestehen. Nur eine Produktdatei geändert, 164 unverändert; 89 Core-/Package-Eingaben sind exakt gleich zum früheren 405-Test-Stand, kein neuer Core-Lauf.
- Code, Tests, Ressourcen, kompilierte Apps/Testbundles, installierte Apps und acht UI-Archive sind quellen-/bytegebunden. Historie: 12 Ausführungen, 10 PASS / 2 alte Navigations-FAIL, nicht 12 aktuelle PASS.

[Vollständige Regionen, Geometrien, Formeln, gemessene RGB-/Kontrastwerte, Pixelabgleiche und Archivhashes](verification/personal-editor-contrast.json).

## Eigene Bilder

| Gerät | Vorher | Aktuell |
|---|---|---|
| iPhone | [Dunkler Text](screenshots/personal-editor-contrast/before-phone.png) | [Semantische Textfarben](screenshots/personal-editor-contrast/current-phone.png) |
| iPad | [Dunkler Text](screenshots/personal-editor-contrast/before-ipad.png) | [Semantische Textfarben](screenshots/personal-editor-contrast/current-ipad.png) |

Keine Originalbilder veröffentlicht. Nur eigene UUID-Demostores/MockHome, keine Home-Verbindung, Konten, Aufnahme, Wiedergabe, Nachrichten oder Anrufe. Normale Systemschrift und vier statische Rollen: keine vollständige Zoom-/Dynamic-Type-, Kontrast-, VoiceOver-, Voice-Control-, Switch-Control- oder AssistiveTouch-Abnahme. F103 bleibt partial/parity=false; Geräte-/Signing-Pause unverändert.
