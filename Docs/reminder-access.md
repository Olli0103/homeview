# Erinnerungen: Listenrechte und bestätigte Änderungen

17. Oktober 2026 · [DAY-02, #48](https://github.com/Olli0103/homeview/issues/48).

Die opt-in EventKit-Verbindung zeigt Listennamen und Schreibrechte. Read-only-Einträge haben gesperrte Erledigen-/Löschen-Aktionen. Auch das Modell lehnt beide Schreibpfade ab; der native Adapter prüft unmittelbar vor jedem Write erneut OS-Freigabe und aktuelle Kalenderrechte.

Neue Erinnerungen entstehen ausschließlich in einer durch diese App angelegten Liste. Deren EventKit-Kennung wird lokal gespeichert. Eine existierende gleichnamige persönliche oder geteilte „HomeView“-Liste wird **nicht** als app-eigen angenommen. Eine verschwundene oder schreibgeschützte eigene Liste führt zu einem Fehler, nicht zur Wahl einer beliebigen anderen Liste.

## Verifikation und Nebenläufigkeit

- Der Adapter liefert bei einem neuen Eintrag dessen Provider-ID zurück. Erstellen prüft diese exakte ID, den Titel und den offenen Zustand im folgenden Read-back; Erledigen prüft ID/Zielzustand, Löschen die Abwesenheit der ID.
- Ein Write-Acknowledgement ohne passenden Read-back zeigt einen unbestätigten Zustand und den tatsächlich gelesenen Listenstand. Kein automatischer Wiederholungs-Write.
- Eingabeentwürfe bleiben bei fehlgeschlagenem Erstellen erhalten. Sperren löscht den persönlichen Entwurf. Bereits laufende Writes können nicht als rückgängig gemacht gelten; nach Sperre beginnt aber kein privater Read-back.
- Bei mehr als 500 Erinnerungen oder fehlgeschlagenem Fetch wird keine unbemerkt gekürzte beziehungsweise vermeintlich leere Liste angezeigt.
- Freigabewiderruf leert den Cache. Die gewählte Quelle bleibt bis zum expliziten Trennen erkennbar; kein Ersatz durch Demo-Erinnerungen.

69 Modelltests, drei UI-Fälle je iPad/iPhone und fünf SDK-Builds bestanden. Enthalten sind Read-only-Bedienung, synthetisches CRUD mit Quellen-Read-back sowie die Hintergrund-/Entsperrregression. [Quellenbindung und Ergebnis](verification/reminders.json).

Automatische Tests verwenden nur synthetische Provider. Keine persönliche Liste, geteilte echte Liste oder EventKit-Kalendererstellung wurde ausgeführt. Physische Freigaben, Accountwechsel, tatsächliche geteilte Listen und deren Read-back bleiben als Hardware-Gate in #48 offen. Ein dauerhaft verschwundener app-eigener Zielkalender wird derzeit als Fehler gemeldet; ein Wiederherstellungsassistent ist nicht behauptet.
