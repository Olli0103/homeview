# Eigenständige Wetter-App nach UI20

Späterer, separat geprüfter [Wolken-Korrekturschritt](weather-clouds.md). Die folgenden Nachweise bleiben ihrem historischen Quellstand zugeordnet.

17. Oktober 2026 · [#21](https://github.com/Olli0103/homeview/issues/21).

Die Originalreferenz UI20 zeigt eine andere Ansicht als das Wetter-Zifferblatt UI05.
Die bisherige Wiederverwendung des Zifferblatts unter einem zweiten Header war
sichtbar falsch. Dieser Schritt rekonstruiert die beobachtete Aufteilung:

- Städteknopf und Uhrzeit oben; zentrierter Ortsname, dünne Temperatur, Zustand und
  Höchst-/Tiefstwerte darunter.
- Dunkelblaue „Conditions“-Karte mit hellblauer Legende, drei Vorhersagemodi und
  horizontaler Stundenfolge. Schriftgrößen, Abstände und Schalterbreite wurden
  am ungefähren Displayausschnitt der Original-Produktaufnahme verglichen.
- Wetter-Zifferblatt und Wetter-App sind getrennte Ansichten. Der vorhandene eigene
  Wolkenhintergrund wird gemeinsam genutzt, nicht als Originalrenderer ausgegeben.

## Daten und Bedienung

Der bestehende öffentliche Open-Meteo-Adapter liefert zusätzlich Stundenwerte für
Temperatur, Niederschlagswahrscheinlichkeit, Wind, Zustand und Tag/Nacht. Es wird
kein zusätzlicher Anbieter, Account oder GPS benötigt. Die vollständige nächste
24-Stunden-Folge bleibt horizontal erreichbar; fehlende Messwerte bleiben „—“.
Beschädigte/ungeordnete Stundenzeitachsen werden verworfen, ohne die brauchbaren
aktuellen Werte zu verlieren. IANA-Zeitzonen erhalten die beiden unterschiedlichen
2-Uhr-Zeitpunkte bei der Herbstzeitumstellung.

Die Städteauswahl übernimmt einen Ort nur nach „Update weather“; „Done“ schließt
sie ohne Ortsänderung. Eine Antwort aus einer inzwischen geschlossenen Auswahl
darf eine neu geöffnete Auswahl nicht schließen. Demo, Quelle, Alter und Einheiten
bleiben als kleine zusätzliche Statuszeile sichtbar; AQI wird nicht erfunden.
Die Demo enthält beobachtete Beispielwerte, keine behaupteten aktuellen Daten.
Unbekannte zukünftige Demo-Temperaturen bleiben ebenfalls leer.

## Prüfung

Nach dem ersten grünen UI-Lauf fand der TV-Build einen dort nicht verfügbaren
Textfeldstil. Er ist jetzt auf unterstützte Plattformen begrenzt. Der endgültige
Quellstand erhält einen eigenen Prüflauf; der Vorlauf ist keine Endabnahme.

**99 Modelltests, acht gezielte UI-Fälle je iPad/iPhone (16 Ausführungen) und fünf
SDK-Builds bestanden auf identischen eingefrorenen Quellbytes.** Null Fehler, Skips
oder von XCTest gemeldete Runtime-Warnungen. Kein neuer vollständiger UI-Suite-PASS.

Die finale Quellenbindung und die tatsächlichen Resultate stehen im
[Prüfnachweis](verification/weather-app.json), die eigenen Simulatorbilder mit
Digests im [Bildmanifest](screenshots/iteration-20261017-block2/weather-app-manifest.json).
Gezielte Tests prüfen zentrierte Geometrie und tatsächliche Bildschirm-Touches,
Vorhersagemodi, Ort/Einheiten, eine verspätete Antwort nach Schließen/Neuöffnen,
fehlende Werte, Fehler, veraltete/offline Daten, Tag/Nacht/Regen/Schnee und die
Navigation aus der verbundenen Musikansicht. Reale persönliche Accounts und
Smart-Home-Geräte werden dabei nicht benutzt.

[Öffentlicher Stundenabruf](verification/weather-hourly-live.json): derselbe
kompilierte Adapter/Decoder, explizit Berlin, 48 gelieferte Stunden und 24 Stunden
im nächsten Tagesfenster. Der datierte Abruf ist an die beiden Quelldateien gebunden,
nicht als spätere komplette UI-Abnahme ausgegeben.

[Eigener Vorher-/Nachher-Vergleich](screenshots/iteration-20261017-block2/weather-app-own-before-after.png) · [Bildherkunft und Ausschnitt](verification/weather-app-comparison.json).

## Sichtbare Lücken

**#21 bleibt offen.** Die weichen Canvas-Wolken treffen die realistisch strukturierten
Originalwolken noch nicht. Licht, Wolkenbewegung, Wetterübergänge, Regen-/Frostdetails
und die Glasziffern des separaten Wetter-Zifferblatts sind nicht originalgetreu
abgenommen. Auch die Städteauswahl ist mangels vollständiger Originalzustände nur
funktional geprüft. Zusätzliche Quell-/Demohinweise sind bewusste Abweichungen.
Die Originalaufnahme enthält das Gerätegehäuse; der ungefähre private Ausschnitt
ist kein nativer Pixel-Benchmark. Originalgrafiken werden nicht veröffentlicht.

Dieser Schritt erweitert nicht beliebig den Funktionsumfang: Er korrigiert die
sichtbare HomeView-Kopie. Ein neuer Werbe-/X-Clip wird daraus nicht automatisch.
