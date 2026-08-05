# Release-Artefakte

## Aktueller Release

`Current/GymPit-1.0.xcarchive` ist das aktuelle, lokal signierte
Release-Archiv mit der finalen Bundle-ID `app.gympit`. Es wurde inklusive Live
Activity und Apple-Watch-App erfolgreich als Version 1.0, Build 2 archiviert.

`Current/AppStoreExport/GymPit.ipa` ist der daraus erzeugte App-Store-Export.
Er ist mit einem „Cloud Managed Apple Distribution“-Zertifikat und Store-
Provisioning-Profilen für Haupt-App, Live Activity und Watch-App signiert. Die
Datei wurde noch nicht zu App Store Connect hochgeladen.

Der Release enthält ausschließlich die 68 gezeichneten Übungsillustrationen
aus `Sources/GymPit/ExerciseDetailImages`. Die alten Strichgrafiken, ihr
Generator und die damit erzeugten Release-Artefakte wurden entfernt.

Für TestFlight `Current/GymPit-1.0.xcarchive` doppelklicken und in Xcodes
Organizer „Distribute App > TestFlight & App Store > Upload“ wählen.
