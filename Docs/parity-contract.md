# Parity-Vertrag

Stand 17. Oktober 2026. Primärziel ist eine native gemeinsame HomeView-Oberfläche auf dem iPad. Referenzgeometrie sind 600 × 600 logische Punkte. iPhone ist eine angepasste Ansicht. Mac, TV, Vision und Watch werden separat geprüft; Watch ist eine reduzierte Begleitansicht. Zusätzliche Watch-inspirierte Faces sind optionale Erweiterungen und kein Ersatz für fehlende Originalfunktionen.

## Verbindliche Zielkorrektur nach Eigentümerreview

Olli hat am 17. Oktober 2026 ausdrücklich bekräftigt: Ziel ist eine visuelle
Apple-HomeView-Kopie, keine eigenständige Gestaltungsvariante. Eigene Implementierung
und redistribuierbare Assets sind kein Grund für abweichende Formen, Proportionen,
Farben oder Abläufe. Funktionsbreite und grüne Tests ersetzen diesen Abgleich nicht.
Der bisherige Videoentwurf ist als Präsentation verworfen; #15 ist wieder geöffnet.

Weitere Arbeit priorisiert jetzt passende Original-/Simulatorvergleiche und die
sichtbaren Abweichungen (zunächst Flow, dann Raster/Icons und Wetterdarstellung).
Unbekannte Originalzustände bleiben unbekannt; neue Ersatzideen werden nicht als
Erledigung der Kopie ausgegeben. Originalreferenzen bleiben von öffentlichem
Projektcode und dessen MIT-Lizenz getrennt.

## Belegstärke

Die historischen Quellenkürzel bleiben erhalten, sind aber kein automatisches Gütesiegel. Ein konkreter UI-Zustand oder eine beobachtete Bewegungssequenz gilt als beobachtet. Hersteller-/Berichtsaussagen ohne passenden Zustand gelten als berichtet. Ist eine Eigenschaft oder Regel aus den vorhandenen Belegen nicht bestimmbar, bleibt sie unbekannt. Eine sichtbare Taste belegt weder den Transport noch eine erfolgreiche Live-Aktion.

Die strukturierte Matrix enthält pro Funktion die eigene Belegbewertung mit Begründung. Eine spätere genauere Quelle darf diese Bewertung ändern. Das Datum und der konkrete Beleg müssen dann mit aktualisiert werden. Die ursprünglichen Medien werden nicht mit veröffentlicht.

## Drei getrennte Abnahmen

| Dimension | Erforderlicher Nachweis | Was nicht genügt |
|---|---|---|
| Funktion | Reproduzierbare Aktion und bestätigter resultierender Zustand, inklusive Fehler, Abbruch und Neustart | Sichtbare Taste, erfolgreiches API-Aufrufen oder Mockantwort |
| Optik und Bewegung | Aktuelle echte Aufnahme gegen passenden datierten Originalzustand, mit Geometrie und verbleibenden Abweichungen | Erfolgreicher Build, View im Accessibility-Baum oder perspektivisches Foto als angeblicher Pixelscreen |
| Gerät und Dienst | Bewusster Test auf benanntem Gerät/OS mit tatsächlicher Freigabe und Providerzustand | Simulator, SDK-Verfügbarkeit oder simulierte Accountfreigabe |

Ein Issue darf für seinen ausdrücklich begrenzten Umfang geschlossen werden. Das nimmt nicht automatisch die verknüpfte Originalfunktion als vollständig gleichwertig ab. `parity_accepted` bleibt false, bis alle für diese Funktion erforderlichen Dimensionen durch konkrete Nachweise gedeckt sind.

## Systemgrenzen

Persönlicher Siri-Kontext, FaceTime-Sitzungssteuerung, Messages-Historie, HomePod-Intercom, Find My, HKSV-Archivfunktionen, biometrische Haushaltsidentifikation, Secure Exclaves und Private Cloud Compute benötigen jeweils einen belegten öffentlichen Pfad. Eine andere Engine oder lokale Simulation erfüllt diese Originalanforderung nicht. Unzugängliche Funktionen bleiben im Nenner und als blockiert sichtbar. Ein vereinbarter Ersatz wird gesondert als Alternative bezeichnet.

Apple Home bleibt bis zur ausdrücklichen Fortsetzung der Einrichtung gesperrt. Es werden keine echten Geräte entdeckt oder gesteuert. Standardtests verwenden nur synthetische persönliche Daten und MockHome. Nachrichten und Anrufe werden nie automatisch gesendet oder gestartet. Reale Foto-, Kamera-, Mikrofon-, Kalender-, Listen- und Musikfreigaben gehören zu einem bewusst ausgelösten separaten Abnahmeschritt.

## Abschluss pro Referenzfunktion

Jede der 105 Funktionen in [function-coverage.json](function-coverage.json) hat:

- eine Belegbewertung und den bisherigen Referenzzustand,
- einen konkreten Status und ein primäres Ziel,
- verlinkte Issues und deren Abnahmekriterien,
- getrennte offene Funktions-, visuelle und Geräteabnahmen.

Unbekannte Quellen, fehlende Hardware und API-Blockaden werden nicht durch Defaultwerte als erfüllt erklärt. Die Liste der Pakete steht in [backlog.md](backlog.md). Die maschinenlesbaren Abschlussbedingungen stehen zusätzlich in [backlog.json](backlog.json).
