# Öffentliche Asset-Historie: bereinigt und abgeglichen

30. Oktober 2026 · Abschluss des ursprünglichen Quellhygiene-/Ersatzasset-Umfangs von [#3](https://github.com/Olli0103/homeview/issues/3), keine Original-Parity-Abnahme.

Nach ausdrücklicher Eigentümerfreigabe wurde ausschließlich der offizielle Main mit dem exakt geprüften alten Head als `force-with-lease` ersetzt:

| Bindung | Wert |
| --- | --- |
| Alter Main | `91e3d08e8cbfa20b5c50aad26cb819acc59392a8` |
| Veröffentlichter Kandidat | `d2d4b0840f79781f59e202d83ec983fafbdac83c` |
| Vollständiger heutiger Dateibaum vorher/nachher | `e53a4bd87068137c31e2dff8e06271b2fead15cb`, exakt identisch |
| Erreichbare Commits vorher/nachher | 471 / 471, alle IDs geändert |
| Entfernte / ergänzte Datei-Blobs | 1 / 0 |
| Historische Bäume mit ausschließlich diesem entfernten Icon | 371 |

Entfernt wurde nur der bekannte frühere gemischte Icon-Blob `4cf10c89b02c60b53f23d3ca491c1a0c7a344610`, SHA-256 `5a20b74e22d680eee19b59a6b9cde67a98d370f30e1afab53ee93316e537a3bc`, 914.998 Bytes. Der heutige unabhängige Iconbestand ist unverändert.

## Veröffentlichung und Rückleseprüfung

Der echte Push meldete exit0 und nur die erwartete Main-Änderung. Danach bestätigten `ls-remote`, eine frische öffentliche Single-main-Bare-Kopie und der verbundene GitHub-Commitabruf den neuen SHA. Keine Tags/weiteren öffentlichen Branches. Die frische Kopie enthält alle 471 Commit-/Tree-Beziehungen; der alte Icon-Blob ist nicht mehr erreichbar. Sie lädt Blobinhalte zunächst nicht erneut herunter. Die identischen Objekt-IDs binden den zuvor vollständig gelesenen Kandidaten: **5.135 Blobs / 1.259.042.117 Bytes**. Kein zweiter vollständiger Byte-Download behauptet.

Beide unmittelbar zuvor/nachher sauberen aktiven Arbeitskopien auf den dateigleichen neuen Stand angeglichen. Nur ihre zwei Branches und `origin/main` geändert; **129 andere lokale private/historische Refs unverändert**. Die unabhängig NAS-bytegeprüfte und vollständig wiederhergestellte Original-Sicherung bleibt privat erhalten: 1.026.534.344 Bytes, SHA-256 `0b725a7b813befd8d0049779f53013e0d961c74f9db4ba68593bee1134d0ab41`.

## Ursprüngliche Aufgaben: mehr als ein Push

| Kriterium | Nachweis |
| --- | --- |
| Eigenständige Icons, Rezept-/Demobilder und Cover mit Herkunft | Alle 58 aktuellen Ressourcen im [aktuellen Manifest](asset-current-manifest.json), 17 Herkunftsquellen. Primitive Eigengeometrie, dokumentierte referenzfrei erzeugte fiktive KI-Bilder/eigenes Alpha-Replay, eigenes prozedurales Cover und synthetischer Ton getrennt deklariert. 25 verbleibende historische Ressourcenraster entsprechen diesen Herkunftsdatensätzen; alle dekodiert und zwei gebundene Ressourcentafeln tatsächlich gesichtet. |
| Flow/Numerals ohne extrahierte OS-Konturen | Alle sieben historischen Versionen von Flow-Zeichner, Flow-Metrik und hohen Fotoziffern vollständig als Anfangsquellen plus Diffs gelesen: sieben Segmente, eigene kleine kubische Skelette, primitive Ringe/Striche. Keine importierte Fontdatei/Konturdaten. Numerals nutzt öffentliche Runtime-Systemschrift, nicht gebündelte Schriftbytes. Originalform-/Achsenkalibrierung bleibt #15/#19/#78. |
| Digest, Urheber/Generator und Nutzungsbedingungen | Vollständige aktuelle Pfad-/Digest-/Herkunftsprüfung. Historische Erstveröffentlichungsdigests bleiben historisch. Vollständiger neuer [erreichbarer Blobindex](verification/asset-public-history-20261030-blobs.json); keine Font-/Archiv-/LFS-Signatur- oder geprüften Extraktions-API-Treffer. Kein genereller Rechte-Automat. |
| Screenshots nach Austausch | Vier [20.-Oktober-Belege](asset-provenance.md): eigene App nach Austausch und tatsächlich kompilierte 120-/152-Pixel-Icons; aktuelle Quelliconbytes unverändert. Kein neuer UI-/Launcher-/Gerätetest daraus. |
| Gesamte erreichbare Historie und Bildherkunft | Alle 2.327 verbleibenden Raster vollständig dekodiert/gehasht. Alle 2.302 Nicht-Ressourcenbilder direkt an Digest und Bilddatei in den spezifischen Prüfbelegen gebunden, auch ohne pauschale Historien-/Selbstinventare. Bestehende private Referenzakte: 936 Dateien vollständig gegen ihr datiertes Manifest geprüft, 725 unterschiedliche vollständige RGB-Bildfingerprints. Kein Originaldatei-Digest in irgendeinem öffentlichen Blob, kein identisches vollständiges Originalbild im dekodierten öffentlichen Bestand. |

Die Bildprüfung erkennt exakte Dateien und identische vollständige RGB-Pixel einschließlich enthaltener Referenzausschnitte, **nicht beliebig veränderte/verkleinerte Ausschnitte**. Die dokumentierten synthetischen Aufnahme-/Ableitungsketten, Herkunftseinträge, gelesenen Glyphenquellen und vollständigen Objekt-/Byteprüfungen werden gemeinsam bewertet; bloße Hashabwesenheit oder Bilddateinamen reichen allein nicht. Kein universelles Urheberrechtsgutachten und keine neue menschliche Einzel-Sichtung aller 2.302 historischen Aufnahmen behauptet. Unbelegte Originaloptik wird dadurch nicht akzeptiert.

Ein erster Dekodierstarter scheiterte vor der ersten Bilddekodierung am im Kandidatenindex fehlenden Feld `kind`. Korrigiert durch Schnittmenge des klassifizierten Ausgangsinventars mit den exakten Kandidaten-Objekt-IDs; Erstfehler privat erhalten, kein Produktfehler/verdeckter Bildausfall.

## Folgen und Grenzen

[471-zeilige Alt→Neu-Commitmap](verification/asset-history-commit-map-20261030.txt) für frühere Beleglinks. Alte Checkouts/Forks migrieren nicht automatisch. Die 371 alten Bäume verlieren ihre damalige Icon-Datei; frühere Ressourcen-/Buildbelege sind dort nicht mehr byteidentisch. Der heutige Produktbaum ist identisch: keine neuen SDK-/Core-/UI-Läufe allein für die Ref-Umschreibung.

GitHub-Caches, alte Commit-/Blob-URLs und fremde Forks sind **nicht garantiert gelöscht**. Abschluss nur für die von offiziellen öffentlichen Refs erreichbare Quellhistorie, nicht fremde Kopien/Cache-Purge. Runtime-Schrift/SF Symbols und beiläufige System-UI bleiben Material ihrer Rechteinhaber, nicht Projekt-MIT-Eigentum. Die ursprünglichen Kriterien von #3 bleiben im Issue erhalten. Originaltypografie, optische Gleichheit und Geräteabnahme bleiben separat offen.

Home bleibt gesperrt, physische Geräte/Signing bleiben eigentümerpausiert. Keine Aufnahme, persönlichen Konten, echten Nachrichten/Anrufe oder Home-Aktionen.

[Maschinenlesbarer Abschluss](verification/asset-history-publication-20261030.json). Der [lokale Kandidat vom 29. Oktober](asset-history-cleanup-candidate.md) bleibt als früherer, damals unveröffentlichter Prüfstand erhalten.
