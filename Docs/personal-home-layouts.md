# Persönliche Home-Screens und Medienwidgets

17. Oktober 2026 · [#9](https://github.com/Olli0103/homeview/issues/9), weiterhin offen.

Der persönliche Screen ist nicht mehr für jedes Profil dieselbe feste Anordnung.
`0b3d51e` ergänzt profilgetrennte Layouts und vier bearbeitbare Favoriten. Die
Standardansicht folgt weiterhin UI16; die zweite Variante folgt der sichtbaren
Aufteilung aus UI42: vier Apps links, Podcastkarte rechts, darunter Musik und
weitere App-Icons. Datum/Uhrzeit, Hintergrundface und verfügbare Inhalte bleiben
dynamisch. Die Demo wird nicht zur erfundenen persönlichen Mediathek erklärt.

Normaler Profil-Tap öffnet die Demo-Profilauswahl. Langdruck öffnet ein öffentliches
Menü mit „Edit Home Screen“. Dieser Bearbeitungseinstieg ist unsere öffentliche
Anpassung, keine belegte originale Apple-Editorregel. Es gibt keinen zusätzlichen
dauerhaft sichtbaren Editierknopf. Der All-Apps-Zugang liegt im Medienlayout unter
dem scrollbaren Inhalt, statt die untere Widgetzeile zu verdecken.

## Zustand und Daten

Layout und Favoriten werden nur für bekannte Demo-Profile gespeichert. Ein zweites
Profil oder Gast übernimmt diese Einstellungen nicht. Doppelte Appwahl tauscht
die Positionen; unbekannte/ungültige Favoriten werden begrenzt normalisiert.
Alte Snapshots funktionieren ohne das neue Feld, beschädigte Einträge setzen
nicht den übrigen Zustand zurück. Der Editor bleibt an sein Ursprungsprofil
gebunden und wird bei Profilwechsel geschlossen.

Die Podcastkarte spielt nur die vorhandene eigene Demoaufnahme nach explizitem
Antippen. Musik verwendet Demo-Inhalte oder einen neutralen Zugang zum bereits
bewusst verbundenen Musikdienst. Die Widgetansicht übernimmt dabei keine privaten
Trackmetadaten eines anderen Demo-Profils. Die echte Systemidentitätsbindung und
eine vollständige Mehrbenutzer-Medienpolicy bleiben getrennt offen; Demo-Profilwahl
ist weiterhin keine Geräteauthentifizierung. Keine neue Konto-/Home-Freigabe.

## Zusammengeführter Prüfstand

Merge `5f00961` verbindet Layouts und den gesondert geprüften Prismenrenderer.
103 Modelltests, acht gezielte UI-Fälle je iPad/iPhone (16 Ausführungen) und fünf
SDK-Builds bestanden auf denselben 116 erfassten Quellen; Prüfung nach dem
Mergecommit. Die vier neuen Modellfälle prüfen Profiltrennung/Read-back,
Auswahlnormalisierung und alte/teilweise beschädigte Einstellungen. UI-Fälle
prüfen Neustart, zweites Profil/Gast, Menü, explizite Demo-Wiedergabe und
Navigation sowie die Home-Material-/Editorregression. Null Fehler/Skips oder von
XCTest gemeldete Runtime-Warnungen. Keine neue vollständige UI-Suite.

Ein früherer SwiftUI-ContextMenu-Versuch hatte trotz funktionaler Tests zwei
UIKit-Viewhierarchie-Warnungen pro Gerät. Er ist nicht der akzeptierte Stand;
die getrennte Menu-/primaryAction-Variante und die Integration wurden erneut
geprüft und melden diese Warnungen nicht.

[Quellen und Ergebnisse](verification/home-integrated.json) ·
[eigene Bilder und Digests](screenshots/goal-20261017/personal-home-manifest.json).

## Weiter offen

Originale Foto-/Albuminhalte, sämtliche Layoutvarianten und genauen Licht-/Raster-
details, reale Identität/Accounts und physische Bedienung sind nicht abgenommen.
Die weitere Apps-/Wettervariante aus der Originalsequenz wird getrennt bearbeitet.
Das ist kein Abschluss von #9 und kein Wartepunkt für das Gesamtgoal.
