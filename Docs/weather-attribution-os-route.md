# Wetter-Quellenlink: tatsächliches OS-Ziel

29. Oktober 2026 · getrennter Nachweis zu [#73](https://github.com/Olli0103/homeview/issues/73), Gesamtissue offen. Produkt unverändert gegenüber `88b068e`.

## Ergebnis

**Vier echte Randberührungen, zwei finale erfolgreiche UI-Ausführungen:** je iPhone und iPad zwei native Punkte innerhalb des oberen/unteren Linkrands. Safari ist vorher nicht im Vordergrund, danach tatsächlich im Vordergrund; seine native Adressanzeige enthält jeweils exakt den Host `open-meteo.com`. Kein abgefangener oder nachgebildeter OpenURLAction-Aufruf. Der Link misst 44,10 × 44,10 native Punkte auf iPhone und 88,22 × 45,11 auf iPad. Der bekannte falsche AX-Hittable-Wert wird protokolliert; die tatsächliche Aktion entscheidet.

Die öffentliche Homepage wird nur lesend geöffnet. HomeViews Wetterdaten bleiben synthetische Fixtures. Keine Anmeldung oder Standortfreigabe. Die unteren Safari-Aufnahmen sind beim Nachweis noch weiß; die native Adressanzeige ist bereits korrekt. **Kein Nachweis vollständigen Ladens, dauernder Webseitenverfügbarkeit oder der internen Netzwerkanfragen der Website.** Die vier nativen PNGs wurden dekodiert und in zwei Übersichten gesichtet; Websitebilder und rohe Browserbäume bleiben privat.

## Erhaltene Fehlversuche

Die ersten zwei Ausführungen öffneten Safari bereits am oberen Rand, scheiterten aber am falschen Testselektor `textFields["URL"]`. Die unteren Ränder wurden in diesen Läufen nicht ausgeführt. Der tatsächliche native iOS-27-Baum liefert `TabBarItemTitle` auf iPhone bzw. `TabBarItemTitleContainer` auf iPad und einen führenden U+200E-Richtungsmarker. Der korrigierte Test verwendet diese beobachteten nativen Felder, entfernt nur LRM/RLM und äußeren Leerraum und behält den exakten Hostvergleich. Kein Produktfehler daraus abgeleitet.

## Quellenbindung und Grenze

225 finale Quelleingaben vor/nach Ausführung und vor Veröffentlichung geprüft. Alle vier ausgeführten Archive mit jeweils 281 Quell-/App-/Test-/Launch-/Steuereingaben vollständig zurückgelesen; installierte Apps geprüft. **Alle 19 Produktdateien bytegleich zu `88b068e`; nur der UI-Test ist neu.** Keine neuen Core- oder SDK-Läufe. Die vorherigen zwölf UI-Ausführungen/fünf SDKs gehören zum Wetter-Oberflächenstand und werden nicht mit diesem geänderten Test zu einer einzigen Vierzehnerprüfung zusammengezählt.

Finaler Quelldigest: `4e5e58b04362d6c0c7c79584d0eb6ef63599596ac98f91be5480915ad1031422`. Finales Eingabearchiv: `bcaf8d5276ec5a3c3655bfebe0ed7dc31c47dfb61bf6fec127c79fcf16f0a492`.

[Ergebnisse und native OS-Belege](verification/weather-attribution-os-route.json) · [beide ausgeführten Quellenvarianten](verification/weather-attribution-os-route-source.json) · [vorheriger Flächenfix](weather-surface-hit-regions.md).

#73 bleibt offen, F103 partial/parity=false. Kein vollständiger Hilfsmittel-, Original- oder Hardware-PASS; keine Home-Anbindung, echten persönlichen Konten, Aufnahme, Wiedergabe, Alarme, Nachrichten oder Anrufe.
