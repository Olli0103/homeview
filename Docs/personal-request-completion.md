# Persönliche Quellen auch bei Fehler oder Abbruch bereinigen

31. Oktober 2026 · gemeinsames Softwarepaket für [#47](https://github.com/Olli0103/homeview/issues/47), [#48](https://github.com/Olli0103/homeview/issues/48) und die ergänzende Datenschutzgrenze [#67](https://github.com/Olli0103/homeview/issues/67).

## Befund und Korrektur

Die bestehenden Generations- und Rechteprüfungen schützten erfolgreiche Antworten.
Eine abgebrochene Kalender-/Reminder-Abfrage übersprang jedoch die erneute
Rechteprüfung. Ebenso konnte ein fehlgeschlagener Reminder-Write oder dessen
fehlgeschlagener Read-back die zuvor gelesenen Erinnerungen im Modell behalten,
obwohl der synthetische Anbieter inzwischen keine Berechtigung mehr meldete.
Erst der nächste reguläre `tick()` bereinigte diese alten Daten. Das ist ein
reproduzierter Modellbefund, keine beobachtete Offenlegung echter EventKit-Daten.

Die gemeinsame Abschlussbehandlung prüft jetzt auch auf Fehler- und Abbruchwegen
die aktuelle Berechtigung. Widerruf leert den betroffenen Cache, entfernt den
Verbindungserfolg und verlangt erneutes ausdrückliches Verbinden. Quellenwahl,
andere Quelle und Geräteentsperrung bleiben erhalten. Die Generationsprüfung steht
weiterhin davor: Ein überholter Abschluss darf weder die neue Sitzung bereinigen
noch deren Status oder Busy-Zustand überschreiben. Der Abschluss fragt keine
neue Freigabe an und startet weder zusätzliche Reads noch Wiederholungs-Writes.

Bereits abgeschickte Writes können stattgefunden haben, selbst wenn die spätere
Bestätigung fehlschlägt oder abgebrochen wird. Sie werden nicht als zurückgerollt
ausgegeben. Bei unveränderter Berechtigung bleibt die bestehende Abbruchregel
erhalten: keine späten Daten und kein überholter Fehlerstatus.

## Begrenzte Prüfung

- Vier neue Testmethoden: vorher drei fehlgeschlagen, eine bereits bestanden;
  insgesamt 34 verletzte Assertions in zwölf kontrollierten Unterfällen.
- Nach Korrektur **79 relevante Coretests bestanden**: DeviceConnections,
  Kalender-Tagesvertrag und öffentliche Freigabekarten. Enthalten sind Widerruf
  bei erfolgreicher/fehlgeschlagener abgebrochener Abfrage, Fehler während Write
  und Read-back, abgebrochener Write-Erfolg, erneute Verbindung, bestehende
  Abbruch-/Lock-/Quellen- und Musikregressionen.
- Fünf SDK-Builds am eingefrorenen Quellstand; Quellen, tatsächliches Core-Testbundle
  und SDK-Produkte bleiben separat gebunden und zurückgelesen. Der bekannte
  iOS-Metadaten-Recovery bleibt im ursprünglichen Buildlog erhalten.

[Quellenbindung, Ergebnisse und Grenzen](verification/personal-request-completion-20261031.json).
Keine UI-/Ressourcenänderung, keine neue Pixel-/Fokusprobe oder Original-Parity.
Nur synthetische Provider; keine persönlichen Konten, EventKit-Listen oder
Kalender geöffnet oder geändert. Home-/Geräte-/Signing-Holds unverändert.

**#47/#48/#67 bleiben OPEN.** Bewusst eingerichtete physische Testquellen,
tatsächlicher OS-Rechte-/Accountwechsel und die übrigen Originalkriterien sind
weiter erforderlich. Dieses Paket ersetzt diese Abnahmen nicht.
