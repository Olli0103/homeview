# Persönliche Sitzung gegen verspätete Antworten sichern

17. Oktober 2026, Teilumsetzung von [SYS-04, #67](https://github.com/Olli0103/homeview/issues/67).

Der bisherige Entsperrpfad übernahm den asynchronen Rückgabewert ohne Sitzungsgeneration. Eine alte erfolgreiche Authentifizierung konnte dadurch eine inzwischen gesperrte Sitzung wieder entsperren. Sperren ließ außerdem Kalender- und Erinnerungsdatensätze im Arbeitsspeicher der Verbindung liegen.

Die Verbindung besitzt jetzt getrennte Generationen für Authentifizierung und Datenanfragen. Sperren, Abmelden, Profilwechsel und Hintergrund entwerten alte Entsperrungen sowie persönliche Requests und leeren die persönlichen Caches. Eine abgebrochene oder verweigerte Authentifizierung erteilt keine Freigabe. Eine neue Sitzung wird nicht durch den Abschluss einer alten Anfrage verändert, auch nicht durch deren Fehler- oder Busy-Cleanup.

Erinnerungsänderungen können bereits vor einer Sperre an den Provider übergeben worden sein. Die App behauptet nicht, solche bestätigten externen Schreibvorgänge rückgängig machen zu können. Nach dem Sperren startet sie daraus keinen weiteren privaten Read-back und zeigt keine verspäteten Inhalte an. Die nächste bewusst entsperrte Sitzung muss den Zustand neu lesen.

Assistenten-/Nachrichtenentwürfe und Toasts werden beim Beenden der persönlichen Sitzung verworfen. Eine deckende Schutzansicht verbirgt den Inhalt, sobald die Scene nicht aktiv ist. Erst tatsächlicher Hintergrund beendet die Freigabe. So bricht eine vorübergehend inaktive Scene während des System-Authentifizierungsdialogs nicht ihre eigene Entsperrung ab. Ein später Authentifizierungsabschluss darf die Navigation nicht mehr übernehmen.

## Prüfung dieses Commits

- 39 Modelltests bestanden, darunter sieben gezielt gesteuerte Authentifizierungs-/Providerfälle.
- Je drei gezielte UI-Tests auf iPad und iPhone bestanden. Kalender und Reminder-CRUD funktionieren weiter; nach Home-Taste und Rückkehr ist eine neue Geräteentsperrung erforderlich.
- Keine Fehler, übersprungenen Fälle oder Runtime-Warnungen in den beiden finalen UI-Berichten.
- Der erste App-Build meldete zwei Quelldateien mit identischem Basisnamen. Die Core-Datei wurde umbenannt; der danach gebaute und getestete Stand enthält keinen solchen Konflikt.

Alle Provider und persönlichen Inhalte dieser Tests sind synthetisch. Kein echtes Konto, Mikrofon oder Heim wurde verwendet. Keine physische LocalAuthentication- oder App-Switcher-Snapshot-Abnahme behauptet. Erkennung tatsächlichen Weggehens, geschützte Medienfreigaben und die übrige Identitäts-/Gastpolicy bleiben eigene offene Arbeit. Deshalb bleibt #67 offen.

## Folgekorrektur: Freigabe ist noch kein Datenzugriff

Beim Verbinden werden OS-Berechtigungen jetzt gesondert angefragt. Solange die Geräteentsperrung fehlt, startet kein Kalender-/Reminder-Lesezugriff und es entsteht kein persönlicher Datencache. Nach dem Freigabedialog wird die Sitzungsgeneration erneut geprüft, bevor ein Lesen beginnt. Kalenderabfrage und lokale Reminder-Schreibaktionen starten selbst keinen weiteren Freigabedialog mehr. Damit kann eine während dieses Dialogs abgelaufene Sitzung nicht später doch einen privaten Zugriff beginnen.

Der kontrollierte Provider zählt tatsächliche Leseaufrufe. Verbinden im gesperrten Zustand muss null Aufrufe ergeben. Auch eine erfolgreiche, aber verspätete OS-Freigabe nach dem Sperren darf keinen Read starten. Dieser zusätzliche Modellfall besteht zusammen mit den Foto-Modellfällen im späteren 50er-Core-Lauf. Die abschließende Gesamtprüfung ist gesondert dokumentiert.
