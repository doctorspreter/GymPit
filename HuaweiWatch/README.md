# GymPit Huawei Watch

Dies ist der Startpunkt fuer eine Huawei-Watch-Version von GymPit.

## Aktueller Stand

- Die iPhone-App kann unter `Mehr > Huawei Watch` eine JSON-Datei exportieren.
- Der Export enthaelt die aktive Routine, den aktuellen Satzstatus, Pausenende und bis zu 20 letzte Trainings.
- Die iPhone-App kann abgeschlossene Watch-Trainings im selben JSON-Format wieder importieren.
- Direkte iPhone-zu-Huawei-Watch-Kommunikation ist nicht Teil dieses Xcode-Projekts. Huawei-Wearable-Apps werden in DevEco Studio mit ArkTS/HarmonyOS gebaut; Huaweis Wear Engine ist fuer Android ausgelegt, waehrend Huawei Health Kit auch iOS/Web/HarmonyOS als Integrationswege nennt.

## Export

Die iPhone-App schreibt Dateien wie:

```text
gympit-huawei-watch-2026-07-12-1046.json
```

Die Wurzelstruktur ist:

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-07-12T08:46:00Z",
  "source": "GymPit iPhone",
  "activeRoutine": {},
  "recentSessions": []
}
```

`activeRoutine.exercises[].sets[]` ist fuer die Uhr am wichtigsten: `reps`, `weight`, `rpe`, `isLogged` und `index` reichen fuer eine kompakte Satz-Erfassung auf dem Watch-Display.

## Import

Eine Huawei-Watch-App kann abgeschlossene Trainings als Objekt mit `sessions` zurueckgeben:

```json
{
  "schemaVersion": 1,
  "source": "GymPit Huawei Watch",
  "sessions": [
    {
      "id": "B8D6F481-21EF-4E94-B52B-80F49CF2F376",
      "planName": "Push",
      "date": "2026-07-12T09:45:00Z",
      "notes": "",
      "durationMinutes": 52,
      "calories": 320,
      "exercises": [
        {
          "id": "6108B91A-0374-4E7E-A97D-98D9E63D0871",
          "catalogID": "chest-press",
          "name": "Brustpresse",
          "category": "Brust",
          "notes": "",
          "sets": [
            {
              "id": "5FA208DB-2EC7-49B3-86F3-B274E3804878",
              "type": "Arbeit",
              "reps": 10,
              "weight": 60,
              "rpe": 8
            }
          ]
        }
      ]
    }
  ]
}
```

Beim Import ueberspringt GymPit bereits vorhandene Sessions per `id` oder gleicher Trainingssignatur.

## Naechster HarmonyOS-Schritt

In DevEco Studio sollte die Watch-App zuerst diese minimale Oberflaeche bekommen:

- Routine laden
- aktive Uebung anzeigen
- naechsten Satz abhaken
- Gewicht/Wiederholungen/RPE anpassen
- Pause anzeigen
- Session als `sessions`-Payload exportieren

Danach kann je nach Zielgeraet ein komfortablerer Sync ueber Huawei Health Kit oder eine Android-Companion-App ergaenzt werden.
