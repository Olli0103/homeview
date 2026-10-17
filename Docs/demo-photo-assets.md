# Eigene Foto-Demos und Schutz ohne Freistellung

Zwei eigenständig erzeugte, fiktive Bilder ersetzen die Foto-Demo-Platzhalter:
ein alpiner See und das Porträt einer erfundenen erwachsenen Person. Die beiden
1254×1254-RGB-PNGs stammen aus dem eingebauten image_gen-Werkzeug, ohne Bildreferenzen,
CLI oder API-Key. Keine Originalperson, Apple-Fotografie oder private Aufnahme
wurde als Eingabe verwendet. Die Dateien werden unter der Projektlizenz gebündelt.

[Ausgewählte Assets und SHA-256](demo-photo-assets.json) ·
[vollständige finale Prompts und Toolmodus](demo-photo-prompts.json).

„Use Demo Photo“, „Use Demo Gallery“ und der ausdrücklich synthetische Album-Test
verwenden diese Assets. Der Foto-Preview im persönlichen Bildschirm zeigt den
Demo-See. Rezeptbilder und andere unabhängig genutzte Ressourcen bleiben erhalten.
PhotosPicker-, PhotoKit- und Album-Berechtigungen werden nicht erweitert.

## Beobachteter Fehler und öffentlicher Fallback

Die tatsächliche erste Simulatoraufnahme zeigte die deckende Uhr vor dem Kopf.
Eine abgeschlossene Analyse hatte keine Freistellung geliefert; es war nicht nur
eine verspätete Analyse. Sowohl Vision-Gesichtsrechtecke als auch die
Vordergrundanfrage meldeten auf diesem Simulator Fehlercode 9. Dessen genauere
Ursache ist nicht geklärt. Eine Host-macOS-Erkennung desselben erzeugten Porträts
ist kein Beweis für Simulator- oder Gerätefreistellung.

Die App versucht nun zusätzlich den öffentlichen Core-Image-CPU-Gesichtsdetektor.
Erkannte Gesichtsrechtecke werden lokal konservativ um den Kopf erweitert.
Diese Bereiche sind Layoutschutz, **keine Alpha-Maske und kein Tiefeneffekt**.
Ohne tatsächlichen freigestellten Vordergrund muss die automatische Uhr diese
Bereiche freilassen. Wenn keine große Überlagerung passt, bleibt das vollständige
Bild unter einer getrennten Uhrzone sichtbar. Sind Vordergrundanalyse und sämtliche Gesichtsdetektoren nicht verfügbar,
wird vorsichtshalber das ganze Bild statt einer erfundenen Gesichtserkennung
geschützt. Eine abgeschlossene Gesichtsprüfung mit null Treffern ist dagegen
kein ganzflächiges Motiv: die Landschaft behält die normale Bildrahmung. Manuelle Position und
manueller Ausschnitt bleiben bewusste Nutzerkorrekturen.

Die ursprüngliche Maskenabdeckungsgrenze von 18 Prozent wird nicht gelockert.
Depth wird nur mit tatsächlich erzeugten Vordergrundbytes aktiviert. Der alte
frei gezeichnete Vordergrund über dem Landschaftsplatzhalter entfällt.

Der erste korrigierte native Porträt-Pilot erkennt einen Schutzbereich, zeigt
keine Uhrüberdeckung dieses Bereichs und setzt die Uhr nach unten. Er meldet
weiterhin keine echte Freistellung. Die Bildprüfung bestätigt den freien Kopf.
Die integrierte betroffene UI-Regression ist unten separat belegt. Dieser
Pilot und der integrierte Lauf sind kein Original-PASS.

## Noch offen

Die deckende gerundete Foto-Uhr ist noch nicht die hohe transparente
Originaltypografie. Original-Tiefenwirkung, allgemeine Motivqualität, reale
Albumfreigaben, Performance und physische Geräte sind gesondert offen.

## Bedienprüfung der Galerie

Ein früher betroffener UI-Lauf bestand sieben Fälle, scheiterte aber beim
Galerie-Einstieg. Das exportierte Testvideo und die Hierarchie zeigten den Knopf
teilweise außerhalb der unten abgerundeten Viewportfläche. Accessibility meldete
ihn trotzdem als hittable. Der korrigierte Test fordert das gesamte Element mit
Abstand zum Rand im sichtbaren Scrollbereich an und prüft danach unverändert
zwei Bilder sowie einen tatsächlichen automatischen Indexwechsel. Es gibt keine
Produkt-Sonderroute, verlängerte Wartefrist oder abgeschwächte Rotationserwartung.

Eine weitere Bildprüfung fand eine unnötige getrennte Uhrzone für die Landschaft:
der erste Fallback hatte null Gesichter wie eine nicht verfügbare Erkennung
behandelt. Diese Zustände sind nun getrennt. Die Landschaft darf ohne Alpha
normal hinter der Uhr bleiben; es wird weiterhin kein Tiefeneffekt behauptet.

## Integrierter Nachweis

Feature `dc5316e`, Integration `c87e3098ffd0645a7bfe06c7d57fd5b6138167e5`:
108 Modelltests, acht gezielte UI-Fälle je iPad/iPhone (16 Ausführungen) und fünf
SDK-Builds bestanden. Null Fehler, Skips oder gemeldete Runtime-Warnungen. Keine
neue Vollsuite oder physische Geräteabnahme. 128 Quellen sind vor/nach dem Lauf
und gegen den Mergecommit identisch; nach Featurecommit erneut 108 Core.

Die Fälle prüfen die echte Demo-Porträtanalyse, automatische Galerie-Rotation,
synthetischen Shared-Album-Import, Top-/Randmotive, dichte Masken, manuelle
Uhrposition samt Neustart/Reset, manuellen Ausschnitt samt Reset und das
persönliche Foto-Widget. Die tatsächlichen finalen Bilder beider Größen wurden
gesichtet: freier Porträtkopf, vollflächiger See, Foto-Preview und Albumimport.
Alle 24 aktuellen PNGs im allgemeinen Assetindex und die beiden neuen Bilder
sind bytegeprüft; aktuelle Konfigurationen sind im vollständigen Quellmanifest
gebunden, nicht durch historische Erstveröffentlichungsdigests ersetzt.

[Quellen und Ergebnisse](verification/photo-demo-integrated.json) ·
[eigene Bilder und Digests](screenshots/goal-20261017/photo-demo-manifest.json).
