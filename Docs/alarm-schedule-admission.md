# Timer und Wecker: Gültigkeit nach der Systemfreigabe

31. Oktober 2026 · gemeinsames Lifecycle-Paket für [#49](https://github.com/Olli0103/homeview/issues/49) und [#52](https://github.com/Olli0103/homeview/issues/52).

## Grenze

Eine Systemfreigabe ist asynchron. Während sie wartet, kann der Benutzer einen Timer pausieren/löschen oder einen Wecker ausschalten/ersetzen. Auch eine Timerfrist kann bereits vergangen sein. Der vorhandene serialisierte AppModel-Writer erkennt einen veralteten Abschluss und räumt dessen Systemauftrag anschließend auf. Das verhindert jedoch nicht den **vorherigen** veralteten Systemaufruf. Außerdem machte das bisherige `max(1, Restzeit)` aus einer während der Freigabe verstrichenen Frist einen neuen Ein-Sekunden-Auftrag.

## Zusammenhängende Korrektur

- Timer geben ihre ursprüngliche absolute Frist an den Adapter, nicht eine vor der Freigabe berechnete Ersatzdauer.
- Der gemeinsame Admission-Gate prüft Auftragsgeneration, aktuelle lokale Auswahl und Task-Abbruch vor und nach der Freigabe. Verstrichene oder ungültige Timerfristen werden nicht geplant; positive Restzeit wird nach der Freigabe neu berechnet und nicht auf eine neue Sekunde aufgerundet.
- Ein nicht mehr zugelassener Auftrag beendet den Writer ohne Systemeffekt und ohne gespeicherten Systembesitz.
- Ein bereits tatsächlich begonnener asynchroner Systemaufruf bleibt eine andere Grenze: Der bestehende nachträgliche Generationstest, Cleanup und die Serialisierung je UUID bleiben erhalten. Ein Gate kann einen bereits begonnenen OS-Aufruf nicht atomar zurückholen.
- Lokales Save-vor-Effekt und Cleanup bei fehlgeschlagener Besitzspeicherung bleiben bestehen. Keine neue Alarmquelle, Berechtigung, Hintergrundgarantie oder Abhängigkeit.

## Prüfungsumfang

[Ergebnis und Quellenbindung](verification/alarm-schedule-admission-20261031.json). Der reproduzierbare [AppModel-Prüftreiber](../Scripts/check_alarm_schedule_admission.py) verwendet nur neue UUID-Testdateien und einen symbolischen Anbieter. Er wählt den vorhandenen Alarmzweig auf macOS durch eine ausgewiesene Plattformbedingungs-Ersetzung; keine AlarmKit-Verknüpfung, echte Freigabe oder OS-Alarmoperation. Die aktuelle Variante verwendet den produktiven Admission-Gate. Der Ersatzanbieter ist kein Nachweis des tatsächlichen AlarmKit-Verhaltens.

Die gemeinsame Verhaltensmatrix umfasst Fristablauf während der Freigabe, Timer-Pause/Löschen, Wecker-Aus/Löschen/Ersetzen, gültige Timer/Wecker sowie veraltete Abschlüsse **nach** begonnenem Effekt. Separate Corefälle prüfen ungültige Fristen, die verbleibende Bruchteilsekunde, Abbruch und Fehlerweitergabe. Produktoberflächen und Ressourcen werden nicht verändert; keine erneute Pixel-/Fokus-Mikroabnahme und keine neue vollständige UI-Suite.

## Ergebnis

**18 gezielte Coretests und zehn aktuelle AppModel-/Ersatzanbieterprozesse bestanden.** Der qualifizierte Vorherlauf mit dem ursprünglichen AppModel hat sechs FAIL und vier PASS; der Ablaufstest wartet dabei ausdrücklich bis nach der tatsächlich gespeicherten Frist. Zwei ältere Ablaufproben mit einer falschen Annahme zur Mindestdauer sind nicht qualifiziert, ihre Ergebnisse bleiben erhalten.

Alle fünf SDK-Ziele bauen am abschließenden Produktstand. Der anfängliche iOS-Isolationsfehler und die erfolgreiche inkrementelle Kompilation mit noch unvollständigen Shortcut-Metadaten bleiben erhalten. Der bestehende einzelne Clean-Recovery lieferte vollständige Metadaten, entfernte aber auch die anderen vier Produkte aus DerivedData; diese wurden anschließend wiederhergestellt. Der anfängliche nur iOS enthaltende ZIP-Versuch wurde niemals als vollständiges Fünf-Plattform-Archiv bestätigt. Das endgültige Archiv ist vollständig zurückgelesen. Die Core-/symbolischen Verhaltenstests wurden wegen der ausschließlich nativen Adapter-Isolationskorrektur nicht wiederholt; die getrennten Pins und unveränderten Inputs stehen im Receipt.

Keine neue vollständige Core-/UI-Regression, installierte Geräte-/Simulator-App oder akustische/OS-Zustellung wird aus diesen Builds behauptet.

## Weiter offen

**#49 und #52 bleiben OPEN.** Systemwiderruf/-neustart, tatsächlicher AlarmKit-Abgleich, Zustellung außerhalb der App, physische/akustische Abnahme und die unbelegten ursprünglichen Regeln sind damit nicht erfüllt. Home und die vom Eigentümer pausierten Geräte-/Signing-Abnahmen bleiben unverändert pausiert. Es wurden keine realen Timer/Wecker, persönlichen Konten oder Hausgeräte bedient.
