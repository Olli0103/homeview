# Öffentliche Asset-Historie: lokaler Bereinigungskandidat

29. Oktober 2026 · Teilumfang [#3](https://github.com/Olli0103/homeview/issues/3), **keine öffentliche Historienänderung** und keine pauschale Rechtefreigabe.

**Historischer Prüfstand:** Am [30. Oktober mit frisch abgeglichenem 471-Commit-Kandidaten ausdrücklich freigegeben, veröffentlicht und zurückgelesen](asset-history-publication-20261030.md). Die nachfolgenden 421-Commit-Zahlen und die damalige ausstehende Freigabe bleiben unverändert historisch.

Der [bekannte frühere Provenienzfehler](asset-provenance.md) wurde jetzt in einer getrennten lokalen Kopie gezielt entfernbar gemacht. Keine Änderung am laufenden Arbeitsrepo, keine privaten Worktree-Branches als Quelle, kein Force-Push.

## Tatsächlich vorbereiteter Umfang

| Prüfstand | Öffentliche Ausgangskopie | Lokaler Kandidat |
|---|---:|---:|
| Nur öffentlicher Ref `main` | `d42d80914f320b97d6a89e2c5062033aa5254c8c` | `9b13ad0876ea8db98a85f9150de90eab4604d3b8` |
| Erreichbare Commits | 421 | 421 |
| Erreichbare Gitobjekte | 6.963 | 6.962 |
| Dateiobjekte, sämtliche Bytes gelesen/gehasht | 4.514 / 1.141.095.642 Bytes | 4.513 / 1.140.180.644 Bytes |
| Aktueller vollständiger Git-Dateibaum | `f1ffeed68be33805a9f416eaf9186a4610ac429c` | **exakt identisch** |

Entfernt wird **nur** der positiv identifizierte historische gemischte Icon-Blob `4cf10c89b02c60b53f23d3ca491c1a0c7a344610`: 914.998 Bytes, SHA-256 `5a20b74e22d680eee19b59a6b9cde67a98d370f30e1afab53ee93316e537a3bc`. Kein anderer erreichbarer Datei-Blob verschwindet oder kommt hinzu. Der Digest ist danach in keinem erreichbaren Kandidaten-Blob vorhanden. Der heutige unabhängige Iconbestand bleibt unverändert.

Standardwerkzeug [git-filter-repo 2.47.0](https://github.com/newren/git-filter-repo), ausschließlich in separater externer venv; Wheel-Digest mit offizieller PyPI-Metadatenantwort abgeglichen. Keine eigene History-Engine gebaut. Ausgangs-Bundle (944.492.898 Bytes) mit Git verifiziert und vollständig gehasht; Commit-Mapping und sämtliche Objekt-/Blobinventare privat gesichert. [Gebundener Bericht](verification/asset-history-cleanup-candidate.json).

## Noch nicht freigegebener externer Schritt

Eine spätere Veröffentlichung würde **alle 421 damaligen Commit-IDs ändern**, nicht nur die Icon-Datei löschen. Alte Checkouts/Forks und eingebettete Commit-/Bloblinks werden nicht automatisch migriert. Frühere historische Bäume verlieren die alte Icon-Datei; deren damalige Ressourcen-/Buildvollständigkeit ändert sich. Der aktuelle Produktbaum bleibt dagegen identisch.

Eine lokale Bereinigung oder ein Force-Push garantiert nicht, dass GitHub alte Commit-/Blob-URLs, Caches oder fremde Forks entfernt. Das muss separat geklärt werden. Der Kandidat ist an `d42d809` gebunden; spätere normale Veröffentlichungen brauchen vor einer Umschreibung einen frischen Kandidaten/Abgleich.

**Kein Remote wurde umgeschrieben.** Vor einer destruktiven öffentlichen Umschreibung ist eine konkrete Eigentümerfreigabe erforderlich; der allgemeine Backlogauftrag ist kein stillschweigender Force-Push. Bis dahin läuft andere Arbeit weiter. #3 bleibt außerdem für die vollständige historische Einzelherkunft offen; die Entfernung dieses einen belegten Fehlers ist keine Bestätigung sämtlicher historischer Screenshots/Glyphenableitungen. Der Snoopy-Scope-Ausschluss betrifft diese separate Frage nicht.
