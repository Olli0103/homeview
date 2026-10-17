# Bearbeitungsstand

## 17. Oktober 2026, erstes Issue-Paket

| Paket | Status | Ergebnis |
|---|---|---|
| [BASE-01, #1](https://github.com/Olli0103/homeview/issues/1) | Abgeschlossen | Vertrag, Belegstärke und Abnahmekriterien für alle 105 Referenzfunktionen. |
| [PHOTO-02, #12](https://github.com/Olli0103/homeview/issues/12) | Abgeschlossen | Motivgeschützte Uhr-/Ausschnittwahl, manuelle Korrektur, Reset und robuste Speicherung. |
| [SYS-04, #67](https://github.com/Olli0103/homeview/issues/67) | Teilweise umgesetzt | Späte Auth-/Datenantworten, Caches und EventKit-Lesezugriffe abgesichert. Reale Präsenz und Hardwareprüfung fehlen. |
| [FACE-09, #18](https://github.com/Olli0103/homeview/issues/18) | Teilweise umgesetzt | Eigener konischer Verlauf und Reduce Motion. Originalzeitkurve und vollständige visuelle Kalibrierung fehlen. |
| [QA-01, #76](https://github.com/Olli0103/homeview/issues/76) | Weiter offen | Vollsuite für Foto/Datenschutz bestanden; spätere Fade-Änderung gesondert, keine vollständige 52er-Folge-Suite. |

[Prüfbericht und Bilder](iteration-20261017.md). Foto/Datenschutz: 50 Coretests und je 50 UI-Fälle bestanden, fünf SDK-Builds. Fade separat: 53 Coretests, zwei UI-Fälle und fünf SDK-Builds bestanden. Keine Hardware-/Originalpixelabnahme.

Zwei von 82 Arbeitspaketen sind abgeschlossen. Geschlossene Pakete bedeuten nicht automatisch vollständig originalgleiche Referenzfunktionen. Alle 105 Funktionen behalten ihre gesonderten offenen Originalabnahmen.

Nächste P1-Arbeit: nutzbare variable Flow-Typografie und Metriken, weitere Fade-Referenzphasen sowie die übrigen offenen Renderer- und Funktionslücken. Apple Home bleibt bis zur ausdrücklichen Einrichtung gesperrt. Quellengebundene Ansatzpunkte: [Build-Übernahmekarte](build-transfer-map.md).

[Gesamtbacklog](backlog.md).
