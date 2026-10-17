# Gespeicherte Zustände: begrenzte Migration statt Komplettreset

17. Oktober 2026 · [QA-05, #80](https://github.com/Olli0103/homeview/issues/80).

`Snapshot.decodeMigrating` behandelt Felder und Sammlungseinträge getrennt. Ein beschädigtes Rezept, Widgetfeld oder einzelner Timer verwirft nicht den gesunden Haus-/App-Zustand. Sammlungen, Achsen-/Lautstärkewerte und ausführbare Timer-/Alarmparameter werden begrenzt; doppelte Objekt-IDs werden nicht als doppelte UI-Einträge geladen. Fehlende alte Felder erhalten explizite Defaults. Nicht lesbare Einträge werden nicht als erfolgreich rekonstruierter Originalinhalt ausgegeben.

## Original erhalten

Vor einer normalisierten Speicherung sichert die App die Originaldatei atomar in ihrem eigenen `State Recovery`-Ordner. Dateiname ist der vollständige SHA-256-Digest; die gespeicherten Bytes werden zurückgelesen und exakt verglichen. Derselbe Originalstand erhält kein zweites Backup. Höchstens acht verschiedene Originale werden automatisch behalten; es gibt kein automatisches Löschen alter Sicherungen.

Eine unbekannte Dateiversion, unlesbarer Gesamtzustand oder fehlgeschlagene Originalerhaltung führt zum **schreibgeschützten Modus** mit sichtbarem Hinweis. Die Originaldatei bleibt unverändert. Speicherversuche melden den Fehler. In diesem Modus werden keine neuen eigenen Systemtimer/-wecker angelegt, geändert oder automatisch abgeglichen. Das ist kein erfolgreicher Restore eines unbekannten Formats; angezeigte Ersatzwerte sind nur temporärer App-Zustand.

Neue Timer/Wecker werden auch bei einem gewöhnlichen fehlgeschlagenen ersten lokalen Save nicht als erfolgreich gespeichert und anschließend im System angelegt. Das ist keine allgemeine Rückabwicklung bereits erfolgter externer Aktionen.

## Prüfung

86 Modelltests, drei gezielte UI-Fälle je iPad/iPhone und fünf SDK-Builds bestanden. Die neue Prüfung verwendet ausschließlich UUID-begrenzte eigene Testordner. Danach erfolgte ein **unabhängiger Host-Datei-Read-back**:

- Die unbekannte Version `99` ist nach Speicherversuch und Neustart auf beiden Geräten bytegleich.
- Der beschädigte Originalstand mit synthetischem Thermostat `69` und defektem Rezept ist als digestgebundene Sicherung vorhanden.
- Der normalisierte Hauptstand enthält das erhaltene Haus, das gültige Ersatzrezept und den anschließend bewusst gespeicherten synthetischen Wert `70`.

[Quellenbindung und Tests](verification/migration-final.json) · [separater Datei-Nachweis](verification/migration-file-readback.json).

Die regulären Benutzerdateien wurden nicht geöffnet, beschädigt oder zurückgesetzt. Reale Accounts, Hausgeräte und bestehende physische Systemalarme waren keine Testobjekte. Die bereits separat geprüften Requestgenerationen/Offlinepfade bleiben eigene Testgebiete; dieser Stand behauptet keine umfassende Hardware-/Accountmigration.
