# App-Icons und persönlicher Home Screen

17. Oktober 2026 · [#9](https://github.com/Olli0103/homeview/issues/9) und
[#3](https://github.com/Olli0103/homeview/issues/3), beide weiter offen.

Die sichtbaren Plus-Kreis-Platzhalter werden nicht mehr als App-Icons verwendet.
Runtime-Vektorformen, System-Symbole und die in UI16/UI41/UI42 sichtbaren Farbgruppen
ersetzen sie. Kalender zeigt Datum/Wochentag der Anzeige, Musik zwei Notenköpfe,
Reminders die farbigen Ringe und Safari die Kompassdarstellung. Keine extrahierten
Original-App-Icons werden in die App oder den öffentlichen Verlauf kopiert.

Der persönliche Standard-Screen folgt nun UI16: FaceTime/Home über Music/Messages,
kleinere zweizeilige Versal-Begrüßung, verkleinerter Profilkreis und quadratisches
Foto-Widget mit Beschriftung. Das ist kein eigener neuer Home-Screen-Stil.

## Geprüfter Umfang

95 Modelltests, ein gezielter Anordnungs-/Renderfall je iPad/iPhone und fünf SDK-
Builds bestanden. Die Spaltenprüfung vergleicht die Mittelpunkte, nicht die linken
Accessibility-Inkgrenzen verschieden breiter Symbole. Die tatsächlichen Bilder
wurden gesichtet; ein zunächst ausgesparter grüner Bereich in der Messages-Sprech-
blase wurde durch die Vereinigung beider Teilflächen korrigiert und neu geprüft.

[Quellenbindung und Resultate](verification/icons-final.json) ·
[Eigene Simulatorbilder](screenshots/iteration-20261017-block2/icons-final-manifest.json).

## Sichtbare Restabweichungen

Die Icons sind Annäherungen, keine behaupteten identischen Apple-Assets. Exakte
Glas-/Lichtdetails, profilabhängige Anordnung und Einstellungen, Widgets aus UI42,
das gesamte Apps-Raster und Zustandswechsel sind nicht abgenommen. Der Foto-
Platzhalter ist weiterhin eine Illustration, kein zum Original passendes Familien-
foto. Diese Lücke wird nicht als erledigte Foto- oder Home-Screen-Parität ausgegeben.

Die alten selbst erzeugten Bitmap-Fixtures bleiben als unbenutzte Projektressourcen
und historische Veröffentlichung erhalten. Aktuelle Vektorquellen unterliegen MIT;
System-Symbole werden vom OS bereitgestellt und nicht durch dieses Repo umgelizenziert.
