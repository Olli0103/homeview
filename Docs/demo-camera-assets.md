# Eigene synthetische Kamera-Standbilder

Vier eigenständig erzeugte, fiktive Szenen ersetzen die bisherigen Vektor-
Platzhalter: Front Door, Back Yard, Living Room und Driveway. Die PNGs stammen
aus dem eingebauten image_gen-Werkzeug, ohne Bildreferenzen und ohne separat konfigurierten CLI/API-Key.
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

Die tatsächliche Raster-/Detail-/Nacht-/Offline-Darstellung wurde auf beiden
Simulatorgrößen getrennt geprüft und gesichtet. Original-Kamera-, Hardware-, Stream- und Leistungsabnahme bleiben
offen. Dieser Assettausch schließt das blockierte Kamera-Issue nicht.

Die Home-Raster-Kachel zeigt die fiktive Living-Room-Szene mit Treppe und öffnet
das zugehörige Living-Room-Detail, statt Vorschau und Raumziel zu vermischen.
Die Kamera-Uhr verwendet dieselbe Display-Zeitzone wie das übrige Dashboard.

Die frühe Bildprüfung hatte einen orangen Offlinebanner trotz Nachtmodus gezeigt:
der frühere Nachtfilter umfasste nur die Hauptansicht, nicht Root-Banner/Toasts.
Der integrierte Stand färbt den gesamten geclippten Viewport. Der Kamera-Nachttest prüft
dekodierte RGBA-Pixel der vollen Fläche einschließlich Offlinebanner; keine
Beschränkung auf die inneren 80 Prozent, die diesen Fehler zuvor übersahen.

## Integrierter Nachweis

`2776f7c`, integriert in `facfa9a`: 104 Modelltests, sechs gezielte UI-Fälle je
iPad/iPhone (zwölf Ausführungen) und fünf SDK-Builds bestanden. 124 Quellen vor/nach
Prüfung und gegen den Mergecommit identisch; nach Featurecommit erneut 104 Core.
Null UI-Fehler/Skips oder von XCTest gemeldete Runtime-Warnungen. Keine Vollsuite.

Enthalten sind Vierer-/Neunerraster und Details, lokaler Mock-Talkback, vollständige
Nacht-/Offline-Fläche, Referenzuhrzeit, native Glas-Nachtregression, echte Randgesten,
Wetter-Nacht-/Offline-Zustand, fünf Face-Sichten und Home-Raster inklusive
Thermostat 68°→69° und passendem Living-Room-Kameraziel.

Die neuen acht PNG-/Assetkonfigurationsdateien und sämtliche 22 aktuellen PNGs des
Assetindex wurden bytegeprüft. Der allgemeine Index hält historische
Erstveröffentlichungsdigests auch für Konfigurationen fest; aktuelle
Konfigurationsbytes sind separat durch den vollständigen Quellmanifest gebunden.

[Quellen und Ergebnisse](verification/camera-stills-integrated.json) ·
[eigene Bilder und Digests](screenshots/goal-20261017/camera-stills-manifest.json).
Das Kontaktblatt enthält acht verkleinerte eigene Viewports beider Größen; die
Pixelprüfungen liefen auf den nativen Exporten, nicht auf dem Kontaktblatt.
Original-/Stream-/Hardwareabnahmen bleiben offen, ebenso weitere Foto-Demoassets.
