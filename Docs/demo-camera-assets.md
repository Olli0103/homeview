# Eigene synthetische Kamera-Standbilder

Vier eigenständig erzeugte, fiktive Szenen ersetzen die bisherigen Vektor-
Platzhalter: Front Door, Back Yard, Living Room und Driveway. Die PNGs stammen
aus dem eingebauten image_gen-Werkzeug, ohne Bildreferenzen und ohne CLI/API-Key.
Keine Apple-Originalbilder oder Aufnahmen echter privater Räume wurden benutzt.

Alle vier ausgewählten Dateien wurden dekodiert und als 1254×1254 RGB geprüft.
Der Promptwunsch 1024×1024 war keine zugesicherte Tool-Ausgabegröße; die tatsächliche
Ausgabe bleibt unverändert erhalten. Die Bilder werden mit dem Projekt unter MIT
bereitgestellt, mit dokumentierter KI-Provenienz statt behaupteter Fotoaufnahme.

[Assetnamen, relative Speicherpfade und SHA-256](demo-camera-assets.json) ·
[vollständige finale Prompts und Toolmodus](demo-camera-prompts.json).

Raster und Home-Thumbnail tragen eine Demo-Kennzeichnung, die Detailansicht
„Demo still“ beziehungsweise „Offline · Demo still“. Es wird kein Live-Stream
behauptet oder erzeugt. Talkback bleibt der vorhandene lokale Mock ohne Mikrofon.
Die Neuneransicht wiederholt die vier Demoquellen; sie ist kein Nachweis für neun
echte Streams. Apple Home bleibt konstruktionsseitig gesperrt.

Die tatsächliche Raster-/Detail-/Nacht-/Offline-Darstellung wird vor Veröffentlichung
getrennt geprüft. Original-Kamera-, Hardware-, Stream- und Leistungsabnahme bleiben
offen. Dieser Assettausch schließt das blockierte Kamera-Issue nicht.

Die Home-Raster-Kachel zeigt die fiktive Living-Room-Szene mit Treppe und öffnet
das zugehörige Living-Room-Detail, statt Vorschau und Raumziel zu vermischen.
Die Kamera-Uhr verwendet dieselbe Display-Zeitzone wie das übrige Dashboard.

Die frühe Bildprüfung hatte einen orangen Offlinebanner trotz Nachtmodus gezeigt:
der frühere Nachtfilter umfasste nur die Hauptansicht, nicht Root-Banner/Toasts.
Der Kandidat färbt den gesamten geclippten Viewport. Der Kamera-Nachttest prüft
dekodierte RGBA-Pixel der vollen Fläche einschließlich Offlinebanner; keine
Beschränkung auf die inneren 80 Prozent, die diesen Fehler zuvor übersahen.
