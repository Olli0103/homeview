# Timer- und Kochbefehle

17. Oktober 2026 · [DAY-04, #50](https://github.com/Olli0103/homeview/issues/50).

Der lokale Parser versteht ausdrücklich gesendete Timerbefehle auf Deutsch und Englisch, inklusive Sekunden, Minuten, Stunden, kombinierter Dauer, Dezimaldauer und optionalem Namen. Beispiele: `Timer auf 90 Sekunden namens Tee`, `set a timer for 1 hour and 30 minutes named Pasta`.

Vage Angaben, Alternativen, negative/zu große Dauern, doppelte Einheiten und Abbruch-/Negationsbefehle erzeugen eine Rückfrage beziehungsweise einen Hinweis — keinen geratenen Fünf-Minuten-Timer. Der zulässige Bereich bleibt eine Sekunde bis 24 Stunden. Englische Zahlwörter sind für eins bis zwanzig abgedeckt, deutsche für eins bis zwölf sowie ausgewählte weitere Zahlen und Zehner; nicht unterstützte Formulierungen werden nicht geraten. Zusammengesetzte Zahlwörter sind nicht allgemein implementiert.

`next step` / `nächster Schritt`, `previous step` / `vorheriger Schritt` und `repeat this step` / `Schritt wiederholen` arbeiten nur auf einer ausdrücklich gestarteten Kochsitzung. UI-Schaltflächen und Befehle nutzen dieselben Schrittwechsel. Rezeptwechsel beendet die alte Kochsitzung. Wiederholen zeigt den tatsächlichen aktuellen Schritt als Text; es behauptet keine automatische Sprachausgabe.

Spracherkennung erstellt weiterhin nur einen Entwurf. Erst Senden oder eine ausdrückliche Tastaturaktion führt den Befehl aus. Aufnahmebegrenzung und On-device-only-Erkennung sind unverändert. Kein Siri-/Allgemeinwissensdienst und keine Smart-Home-Verbindung wurde ergänzt.

76 Modelltests, drei gezielte UI-Fälle je iPad/iPhone und fünf SDK-Builds bestanden. UI: benannter 90-Sekunden-Timer, kein zweiter Timer bei unklarem Auftrag, deutsch/englische Kochschritte und bestehender Zutaten-/Kochtimerfluss. [Quellenbindung und Ergebnisse](verification/voice-final.json).

Die automatische Prüfung verwendet synthetische Texte, keine Mikrofone. Reale Erkennung bei Musik, Entfernung oder Störgeräuschen bleibt in #75 offen. Timer-Systemalarm und dessen physische Auslösung sind eine separate Abnahme.

## Ergänzung am 19. Oktober 2026

Die synthetische Software-Abnahme von #50 ist ergänzt: besitzgebundene Aufnahme/Start-Tasks, keine späten Fremdsitzungs-Transkripte, Fehler-/Längen-/Finalisierungsgrenzen, ausdrückliches Senden und vollständig lesbare Entwurfsvorschau. Sieben native Szenarien/120 Assertions sowie zehn finale UI-Ausführungen auf iPad/iPhone bestanden. Die 76 Modelltests oben sind der historische Parserstand, kein neuer Lauf. [Aktuelle Belege und genaue Grenzen](voice-lifecycle.md). Physische Sprachqualität und Originalgleichheit sind damit nicht abgenommen.
