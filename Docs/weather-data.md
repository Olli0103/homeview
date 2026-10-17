# Wetterdaten ohne erfundene Live-Werte

Spaeterer, separat gepruefter [Wolken-Korrekturschritt](weather-clouds.md). Die folgenden Nachweise bleiben ihrem historischen Quellstand zugeordnet.

Historischer Datenschritt `b08c6f8`. Die spätere eigenständige UI20-Ansicht ist
[separat dokumentiert](weather-app.md); die folgenden Tests gehören zu diesem älteren Stand.

17. Oktober 2026 · [#21](https://github.com/Olli0103/homeview/issues/21).

Der vorhandene öffentliche Open-Meteo-Adapter bleibt die Quelle; kein neuer Dienst,
Account, Schlüssel, GPS oder HomeKit-Zugriff. Wetter wird nur nach bewusster Verbindung
für einen eingegebenen Ort abgefragt. Der Abruf verwendet Fahrenheit/mph als feste
Transportbasis, die Anzeige wahlweise °F/mph oder °C/km/h.

## Daten- und Lebenszyklusgrenzen

- Fehlende/null oder unplausible Messwerte bleiben unbekannt (—), einschließlich
  Temperatur, Tagesgrenzen, Wind, Feuchte und Sonnenzeiten. Kein ausgedachter AQI:
  dieser Forecast-Endpunkt liefert keinen, die Ansicht sagt das ausdrücklich.
- Ein fehlender/ungültiger Beobachtungszeitpunkt oder ungültiger UTC-Offset verwirft
  die Antwort. Datum und Uhrzeit der Beobachtung sowie Quelle und Einheiten sind sichtbar.
- Nach mehr als einer Stunde oder bei einer mehr als fünf Minuten zukünftigen
  Beobachtung steht „Stale reading“. Ein fehlgeschlagenes Update derselben Stadt
  behält den letzten Wert mit „Offline · last reading“, nicht als frischen Messwert.
- Ein Ortswechsel entfernt die alten Werte sofort und invalidiert laufende Antworten.
  Eine explizite Aktualisierung verbindet den neuen Ort. Trennen invalidiert ebenfalls.
- Nach einem fehlgeschlagenen Verbindungsversuch gibt es keine heimliche Rückkehr zu
  Demo-Temperaturen. Ohne Verbindungsversuch ist das synthetische Wetter deutlich
  in Vollansicht und modularem Panel als Demo gekennzeichnet. Die Komplikation
  teilt dieselben Messwert-/Fehlergrenzen.
- Öffentliche WMO-Codes bestimmen Zustand und Tag-/Nachtsymbol. Wolkenbedeckung,
  Regen und Schnee nutzen eigene dekorative Canvas-Zeichnungen. Ein Rand bei ≤32°F
  illustriert Kälte, behauptet keine gemessene Eisbildung. Reduce Motion und inaktive
  Szenen verwenden den gemeinsamen pausierenden MotionTimeline-Pfad.

## Prüfung und verbleibende Arbeit

95 Modelltests prüfen unter anderem echte JSON-Nullwerte/fehlende Felder, extreme
Zahlen einschließlich Int.min-Offset, sichere Formatierung, Einheiten, Sonnenzeit
bei UTC+05:45, Zustandszuordnung, veraltete/future Beobachtungen, Offline-Caches
sowie verzögerte Antworten nach Ortswechsel/Trennen. Drei gezielte UI-Fälle je iPad/iPhone (sechs Ausführungen) sowie fünf SDK-Builds
bestehen auf dem finalen Quellenstand. [Quellenbindung und Resultate](verification/weather-accepted.json)
· [Simulatorbilder und Digests](screenshots/iteration-20261017-block2/weather-accepted-manifest.json).
Die frühere vollständige 216-Ausführungen-Suite ist ein anderer Quellstand und
wird hier nicht als neue Vollsuite ausgegeben.

Die manuelle Sichtprüfung verwarf zwei vorläufige Layoutstände wegen abgeschnittener
Quellen-/Sonnenaufgangszeilen trotz technisch vorhandener Accessibility-Texte.
Die finale Prüfung fordert ihre Lage innerhalb des Displays einschließlich des
unteren Rands. Der Celsius-Test scrollt den tatsächlichen Segmentknopf in den
sichtbaren Bereich und bestätigt seine Auswahl, statt nur die teilweise sichtbare
Picker-Gruppe anzutippen. Die fehlgeschlagenen Vorläufe bleiben private Arbeitsbelege.

Ein separater öffentlicher Abruf von „Berlin“ erfolgte durch den tatsächlich
kompilierten WeatherService und denselben Decoder, nicht durch einen Ersatzparser.
Der Nachweis nennt Quelle und Abruf-/Beobachtungszeit; es wurde keine private
Standortquelle benutzt. Er ist eine Momentaufnahme, keine Dauerverfügbarkeitszusage.

#21 bleibt für vollständige Originaleffekte, zusätzliche Wetter-/Polartag-/
Ortsauswahlfälle und Geräte-/Performanceabnahme offen. Diese Änderungen behaupten
weder Originalparität noch eine Luftqualitätsintegration.

[Öffentlicher Live-Abruf](verification/weather-live.json). Die originale Wetter-App
(UI20) ist eine eigene Ansicht; der spätere Layoutschritt ist im verlinkten Folgebericht dokumentiert. Diese
Datenkorrektur schließt #21 nicht und rechtfertigt keine abweichende Neugestaltung.
Nach Eigentümerreview haben die sichtbaren Originalvergleiche Vorrang.
