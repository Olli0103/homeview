# Reduce Motion über die tatsächliche OS-Einstellung

30. Oktober 2026 · Teilumfang von [#73](https://github.com/Olli0103/homeview/issues/73), weiterhin **OPEN/F103 partial**. [Einzelreceipts, PIDs und Pixelpaare](verification/system-reduce-motion.json).

## Acht native, prozessgebundene Fälle

Die eigene iOS27-Simulator-Settings-App wird über den beobachteten Pfad Accessibility → Motion bedient. Der benannte `REDUCE_MOTION`-Knoten enthält den tatsächlichen physischen Switch. Sein Wert und `UIAccessibility.isReduceMotionEnabled` werden vor und nach jedem nötigen Tap zurückgelesen. Keine private Setter-/KVC-API, kein `--reduce-motion`-Ersatzflag; `--animation-test` lässt die normale Bewegung ausdrücklich zu.

Vier Szenen auf iPhone und iPad bestehen jeweils im Zyklus **OFF → ON → OFF**:

1. OFF: Die vorher festgelegte Bildregion bewegt sich.
2. ON: Dieselbe Region bleibt in zwei nativen Aufnahmen exakt RGBA-gleich.
3. OFF erneut: Die Bewegung kehrt zurück.

Die tatsächliche App-Prozess-ID wird in allen drei Phasen aus den Root-Attributen des öffentlichen XCTest-Snapshots gelesen und muss gleich bleiben. Ein unbekanntes Format scheitert ausdrücklich. Vordergrundzustand, erwartete Oberfläche und nichtuniformer Bildinhalt sind weitere Voraussetzungen. Das trennt eine beobachtete Einstellungsreaktion von einem bloßen Hintergrund-Freeze, falscher Oberfläche oder leerem Bild.

Die unabhängige Dekodierung bestätigt **24 Regionpaare: acht ON-Paare mit null geänderten Pixeln/Kanälen, 16 bewegte OFF-/Rückkehr-Paare**. Kein Bildabgleich per Registrierung, Maske oder Toleranz. Die vorhandenen ROIs bleiben gleich: Flow innen90%, Home-Prisma innen80%, App-Wetterhimmel und Wetter-Face in ihren bereits vorher deklarierten Bereichen. Der zusätzliche Inhaltstest verlangt mindestens100 Pixel mit RGB-Abstand>16 zum ersten Pixel; das ist nur ein Uniformbild-Guard, keine Kontrastmessung oder Toleranz in der exakten Paarbedingung.

Bei Flow bleibt zusätzlich der vorhandene Compute-Revisions-/Pending-Text während der ON-Beobachtung unverändert, `active=true` und `pending=false`. Das ist keine Energie-, FPS- oder allgemeine GPU-Idle-Messung. Die tatsächlichen kurzen Beobachtungsintervalle stehen im Einzelbeleg; daraus folgt kein unbegrenzter Stillstand aller Animationen.

## Eigene native Belegbilder

Die Bilder zeigen unterschiedliche **OS-Einstellungen derselben unveränderten App**, keinen erfundenen Vorher-/Nachher-Produktfix.

| Szene | iPhone OFF / ON | iPad OFF / ON |
|---|---|---|
| Flow | [OFF](screenshots/system-reduce-motion/phone-flow-off-first.png) · [ON](screenshots/system-reduce-motion/phone-flow-on-first.png) | [OFF](screenshots/system-reduce-motion/pad-flow-off-first.png) · [ON](screenshots/system-reduce-motion/pad-flow-on-first.png) |
| Home-Prisma | [OFF](screenshots/system-reduce-motion/phone-home-prism-off-first.png) · [ON](screenshots/system-reduce-motion/phone-home-prism-on-first.png) | [OFF](screenshots/system-reduce-motion/pad-home-prism-off-first.png) · [ON](screenshots/system-reduce-motion/pad-home-prism-on-first.png) |
| Wetter-App | [OFF](screenshots/system-reduce-motion/phone-weather-app-off-first.png) · [ON](screenshots/system-reduce-motion/phone-weather-app-on-first.png) | [OFF](screenshots/system-reduce-motion/pad-weather-app-off-first.png) · [ON](screenshots/system-reduce-motion/pad-weather-app-on-first.png) |
| Wetter-Face | [OFF](screenshots/system-reduce-motion/phone-weather-face-off-first.png) · [ON](screenshots/system-reduce-motion/phone-weather-face-on-first.png) | [OFF](screenshots/system-reduce-motion/pad-weather-face-off-first.png) · [ON](screenshots/system-reduce-motion/pad-weather-face-on-first.png) |

## Rückstellung und Quellenbindung

Alle17 ausgeführten Präferenz-Tests – erster Pilot, frühere Bildmatrix und aktuelle PID-Matrix – stellen den tatsächlich gelesenen ursprünglichen Wert `false` wieder her und lesen Switch0 sowie nativen Getterfalse zurück. Keine Host-, TCC-, Konto-, Home-, Mikrofon-/Kamera-, Nachrichten-/Anruf- oder physische Geräteeinstellung wurde geändert. Die Simulator-Motion-Einstellung war jeweils vorübergehend geändert und ist am Ende wieder im Ausgangszustand.

Alle165 Produkt-/Ressourceninputs bleiben exakt wie `0c42086`. Der aktuelle Teststand bindet233 Inputs mit Digest `6c9c4ea64700ba21bf46454235243e41d94b43eb592236865d5a029b623b9051`. Zehn vollständige Inputarchive sind byteweise zurückgelesen; die22 kompilierten Appdateien sind zwischen diesen Archiven gleich. Funktionale Läufe installieren und prüfen die eigene eingefrorene Simulator-App vor/nach der Ausführung; der tatsächlich installierte Runner/Testbundle und die Settings-Binär-/Plist-Identität werden getrennt geprüft.

Die fünf reinen OS-Inventuren behalten ihr historisches `installed_app_verified=false`: Sie starteten nur Settings und waren keine Produktlaufzeit-Abnahme. Das wird nicht durch die spätere explizite App-Installation rückwirkend grün gemacht. Kein neuer fünf-SDK-/Core-Lauf für diese UITest-/Docs-Änderung; die Produkt-Gates von `0c42086` und405 frühere Core-Tests sind historische Belege bei89 unveränderten Core-Inputs.

## Erhaltene Kalibrierung und Grenzen

Gesamthistorie: **22 UI-Ausführungen,21 PASS und ein erhaltener FAIL**. Nur die letzten acht sind die aktuelle PID-gebundene Abnahme. Davor liegen fünf OS-Inventuren (vier bestanden, eine Live-Index-Snapshot-Abfrage scheiterte), ein erster Flow-Pilot und acht Bild-/Schalterfälle ohne gemessene Prozesskontinuität. Deren wörtliches `same_app_lifetime=true` war Testabsicht, kein PID-Beleg; es bleibt ausdrücklich unqualifiziert für „ohne Neustart“. Es gibt auch keinen Beleg, dass dort tatsächlich ein Neustart stattfand. [Exakte frühere Quellen](verification/system-reduce-motion-probes/README.md) und Fehler bleiben erhalten.

Die ursprüngliche vollständige Root-Inventur war teuer: etwa70 Sekunden auf dem iPhone,240 auf dem iPad. Der angeforderte120-Sekunden-Testwert war wegen `TestTimeoutsEnabled=false` kein wirksames Wall-Limit. Die spätere stabile Snapshot-Aufnahme vermeidet live indizierte Baumabfragen; Navigation und Switch-/Getter-Prüfungen bleiben erhalten. Ein früher Compilerfehler an einer Defaultparameter-Methodenreferenz ist separat erhalten: keine UI-Ausführung oder Präferenzänderung bei diesem Fehlschlag.

106 native PNGs sind dekodiert, alle13 erzeugten nativen Kontaktbögen tatsächlich gesichtet;16 eigene Viewports sind veröffentlicht. Vollständige OS-Screens, AX-Texte, Rohlogs und kompilierte Bundles bleiben privat. Fade, Übergangskennlinien, andere Hilfsmittel, physische Geräte, Energie und Original-Parity sind nicht mit abgenommen. Die Backlog-Arbeit geht mit weiteren Datenschutz-Präsentationsgrenzen weiter; Snoopy-Ausschluss und Geräte-/Signing-Pause bleiben unverändert.
