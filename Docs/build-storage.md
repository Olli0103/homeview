# Build-Speicher begrenzen

30. Oktober 2026. Nach dem Kapazitätsvorfall wird der bestehende SDK-Builder
weiterverwendet, statt eine neue Cache-/Aufräumautomatik einzuführen.

- Ein explizites `HOMEVIEW_BUILD_DIR` für den aktiven Worktree wiederverwenden;
  keine neue DerivedData-Kopie pro Bericht, Gerät oder Testselektion.
- Vor jedem SDK-Build und dem optionalen iOS-Metadaten-Clean-Build liest
  `Scripts/build_platforms.py` den freien Platz des tatsächlich aufgelösten Ziels.
  Standardreserve: **16 GiB**. `HOMEVIEW_MIN_FREE_GIB` akzeptiert ausschließlich
  einen ausdrücklich gesetzten endlichen positiven Wert.
- Nicht eingehängte macOS-Pfade unter `/Volumes/<name>` werden abgewiesen,
  statt auf dem Startvolume einen Ersatzordner anzulegen. Unlesbare Kapazität
  ist ebenfalls ein Stop, kein angenommener freier Platz.
- Fällt die Reserve nach einem Build weg, startet kein weiteres SDK.
  Compilererfolg und Platzmangel bleiben getrennte Ergebnisse.
- Buildlogs erhalten unverwechselbare Pfade unter `HomeViewBuildReceipts`;
  frühere Logs bleiben bei Wiederverwendung des Compilercaches erhalten.
- **Keine automatische Löschung.** Getestete Apps/Tests/Launchkonfigurationen
  vor Wiederverwendung quell- und bytegebunden sichern; Ergebnisbündel nicht
  überschreiben. Unveränderte Archive nicht pro Einzeltest duplizieren.

## Nachweis und Grenze

15 Tooling-Tests bestanden, darunter die sechs bisherigen Shortcut-Paketfälle.
Zusätzlich wurde auf dem echten externen Zielfilesystem eine absichtlich
unerfüllbare Reserve geprüft: Stop75, kein gestartetes Xcode und kein angelegtes
DerivedData-Verzeichnis. Der normale 16-GiB-Preflight bestand zur selben Zeit
bei 68.871.184.384 freien Bytes. [Quellen und Ergebnisse](verification/build-storage-20261030.json).

Das ist **keine** Reservierung oder Quota: Ein einzelner laufender Build und
andere Prozesse können die Reserve verbrauchen. Direkte `xcodebuild`-/UI-Aufrufe
sind nicht vom Skript umfasst; für sie gilt dieselbe manuelle Vorprüfung.
Keine neuen SDK-/UI-/Core-Läufe und keine App-/Original-Parity aus diesen
Tooling-Tests. Produktquellen unverändert; Home-/Geräte-/Signing-Holds bleiben.
