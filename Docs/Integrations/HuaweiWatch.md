# GymPit for Huawei Watch

This document is the starting point for a Huawei Watch version of GymPit.

## Current status

- The iPhone app can export a JSON file from **More > Huawei Watch**.
- The export contains the active routine, current set state, rest-timer end,
  and up to 20 recent workouts.
- The iPhone app can import completed Watch workouts in the same JSON format.
- Direct iPhone-to-Huawei-Watch communication is outside this Xcode project.
  Huawei wearable apps are built with ArkTS/HarmonyOS in DevEco Studio. Huawei's
  Wear Engine targets Android, while Huawei Health Kit also documents iOS, web,
  and HarmonyOS integration paths.

## Export

The iPhone app writes files such as:

```text
gympit-huawei-watch-2026-07-12-1046.json
```

The root structure is:

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-07-12T08:46:00Z",
  "source": "GymPit iPhone",
  "activeRoutine": {},
  "recentSessions": []
}
```

`activeRoutine.exercises[].sets[]` is the most important data for the Watch.
`reps`, `weight`, `rpe`, `isLogged`, and `index` are sufficient for compact set
tracking on the Watch display.

## Import

A Huawei Watch app can return completed workouts in a `sessions` object:

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
          "name": "Chest Press",
          "category": "Chest",
          "notes": "",
          "sets": [
            {
              "id": "5FA208DB-2EC7-49B3-86F3-B274E3804878",
              "type": "Working Set",
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

During import, GymPit skips an existing session when either its `id` or workout
signature matches.

## Next HarmonyOS step

Start with this minimal Watch interface in DevEco Studio:

- Load a routine.
- Show the active exercise.
- Complete the next set.
- Adjust weight, repetitions, and RPE.
- Show the rest timer.
- Export the session as a `sessions` payload.

Afterward, add a more convenient sync path through Huawei Health Kit or an
Android companion app, depending on the target device.
