# Mehrere lokale Timer: gemeinsamer Ablauf und Prozessneustart

20. Oktober 2026 · begrenzte Prüfung zu [#49](https://github.com/Olli0103/homeview/issues/49). **Kein Timer-Produktfix erforderlich; das Issue bleibt offen.**

Der neue reproduzierbare Prüftreiber kompiliert die tatsächlichen App-/Core-Quellen. Am AppModel wird nur ein lesender Zugriff auf die Speicher-URL angehängt; keine Produktionsmethode wird ersetzt. Drei Fälle laufen jeweils als getrennte **Seed-, Reconcile- und Verify-Prozesse** mit demselben neuen UUID-Test-Speicher. Zwischen Seed und Reconcile vergehen real zwei Sekunden bei einer Ein-Sekunden-Testfrist. Das ist eine native Prozess-/Persistenzprüfung ohne UI-Host, keine neue iOS-Hintergrund- oder Hardwareabnahme.

| Fall | Geprüftes Verhalten |
| --- | --- |
| Gleichzeitiger Ablauf | Drei Timer mit derselben Frist werden gemeinsam bestätigt; pausierter 90-Sekunden-Timer und weiterlaufender Kontrolltimer bleiben unverändert |
| Gestaffelte Gruppe | Nur der neu fällige Timer wird bestätigt; zukünftiger und zuvor bestätigter Gruppeneintrag bleiben unverändert |
| Fehlgeschlagener Batch-Save | Zwei Ticks bei absichtlich blockierter eigener Speicherdatei erzeugen keine Quittierung, keinen Banner, Auswahlwechsel oder Chime-Aufruf; Originalbytes und Dateicanary bleiben erhalten. Nach Wiederherstellung werden alle drei bestätigt; ein weiterer Prozessstart meldet keinen erneut |

Zusätzlich: Timerreihenfolge und IDs unverändert, nur fällige `didAlert`-Felder geändert, gespeicherter Zustand entspricht dem Modell, Auswahl entspricht dem letzten neuen Ablauf. Weitere Ticks schreiben nicht erneut und ändern weder Banner noch Auswahl oder Aufrufzähler. Der letzte Banner entspricht der letzten neuen Meldung; eine gleichzeitige Darstellung aller Banner wird nicht behauptet.

**Neun tatsächliche Prozessläufe, 118 Assertions bestanden** bei Testcommit `dc6c7f1`. Der erste Vorbereitungsbuild scheiterte ausschließlich an fehlendem Leerraum zwischen `=` und `!` im neuen Prüftreiber: null App-Prozesse, null Assertions; separat aufbewahrt, kein Produktfehler und kein nachträglicher PASS. Zwei Archive vollständig zurückgelesen, inklusive Quellen, kompilierten Eingaben, ausgeführtem Bundle und Ergebnissen. Zwei alte Testdatei-/Runnerstände wurden aus der konkreten Änderung rekonstruiert und gegen ihre zuvor erfassten SHA-256 geprüft; dies steht ausdrücklich im Vorbereitungsinventar.

160 Produkt-/Ressourcen-/Projekt-/Paketdateien bytegleich zum veröffentlichten Rezeptstand und dessen fünf SDK-Builds bei `4c932da`. Keine neuen SDK-Builds, UI-Ausführungen oder Bilder erforderlich/behauptet. Die 297 früheren Coretests bei `6c69a68` bleiben historisch; kein neuer Core-Lauf. [Messbericht und vollständige Einzelprüfungen](verification/simultaneous-timer-expiry.json).

## Wiederholen

Auf einem Mac mit Xcode und bereits gebauten FeedKit-/XMLKit-Debug-Produkten:

```sh
python3 Scripts/check_simultaneous_timer_expiry.py \
  --products /absolute/path/to/Debug \
  --output /absolute/external/path/to/new-output
```

Der Ausgabepfad muss neu sein und außerhalb des Repositorys liegen. Synthetische UUID-Speicher werden als Beleg behalten; keine bestehenden Speicher zurückgesetzt. Der Treiber verwendet keine Audioressource, setzt Lautstärke null und lässt Systemalarme sowie Live-Activities ausgeschaltet. Der Chime-Zähler belegt ausschließlich Anforderungen, **keine akustische Wiedergabe oder Anzahl hörbarer Töne**.

## Weiter offen

Tatsächlicher Geräte-/OS-Neustart, Systemzeitänderung, AlarmKit-Abgleich, akustisches Verhalten, Originalmaximum/-sortierung/-layout und physische Geräte. Keine echte Alarmfreigabe oder Systemaktivität. Keine realen persönlichen Daten und **keine Home-Anbindung**. F063/F064 und die ursprünglichen Abnahmekriterien bleiben unverändert.
