# Changelog

## [Unreleased]

### Added

- **38 Pilates and yoga exercises**, each with a MET value so calories can be
  worked out from body weight and duration.
- **GymPit speaks HealthPit's identifiers.** A set now travels as
  `WRK_SET_WEIGHT`, `WRK_SET_REPS`, `WRK_SET_VOLUME`, `WRK_SET_RPE` instead of
  GymPit's own field names. The translation table in the middle — which both
  sides had to maintain — is gone. The identifiers come from a generated file
  (`HealthPitMetricIDs.swift`); renaming one in HealthPit breaks this build
  instead of letting the two apps drift apart quietly.
- Manually created exercises travel as `custom-<uuid>` with their plain name,
  so they arrive as their own value rather than being dropped.
- Set types are sent as language-neutral codes (`WORKING`, `WARMUP`,
  `DROPSET`, `FAILURE`). The German words would change with a translation and
  are useless as identifiers.

### Changed

- **Equipment presets removed from the catalogue.** Seat, backrest, handle and
  range start empty. Before, adding an exercise copied a preset from the
  catalogue, and that number travelled to Home Assistant as if the user had
  set it — a sensor that always said "4". Only what is actually entered is
  sent now.

All notable changes to GymPit are documented in this file.

## [Unreleased]

### Added

- Saved workouts can be edited. Open an entry in the history and tap Edit to
  correct its date, duration, calories, note, exercises, sets, weights, and RPE.
  The corrected workout replaces the previous one in Apple Health and HealthPit
  instead of being written a second time.
- The exercise overview has an Edit button that jumps straight into the
  exercise and device editor, so a machine's settings can be changed from the
  screen that opens when an exercise is tapped during a workout.

### Changed

- The weight step of an exercise is now typed in as a number instead of being
  picked from a preset list. Steps a gym actually has, such as 1.75 kg, can be
  entered directly. The value is still stored in kilograms and shown in the
  selected unit.

- The Apple Health and local network permission prompts, the project's
  development region, and the internal StoreKit product labels are now English.
  The German product texts stay in place as the German localization.

### Fixed

- The progress ring no longer shows a pale dot at the twelve o'clock position.
  Its angular gradient wrapped the full turn, so the seam between its opaque
  and translucent ends sat exactly under the round cap at the start of the arc.
  At 0 % the arc is left out entirely, because a round cap on a zero-length
  trim still paints a dot.
- Muscle groups at 0 % no longer show a sliver of the filled bar. The bar was
  drawn with width 0, and a rounded rectangle narrower than its corner radius
  still renders a hairline of antialiased colour. The fill is now omitted at 0
  and clipped to the track, which also keeps it inside the track when a group
  is trained beyond its planned sets.

## [26.08] - 2026-08-08

### Added

- Standalone strength workouts on Apple Watch without requiring an active
  iPhone connection.
- Live heart rate, active calorie, and workout duration tracking through
  HealthKit on Apple Watch.
- Watch controls for pausing a workout, editing the current set, adjusting or
  skipping rest timers, and switching between exercises.
- Reliable deferred WatchConnectivity delivery when the iPhone is temporarily
  unavailable.
- Per-machine weight step, configurable for every exercise under Device →
  Weight. Presets follow the selected unit (0.5–20 kg or 1–45 lbs) and the
  stored value survives a unit switch.

### Changed

- Reworked the Apple Watch interface for legibility: solid cards instead of
  translucent material on the black background, tappable exercise rows, larger
  minimum tap targets, and readable contrast on the pause button.
- The plus and minus buttons and the Digital Crown on Apple Watch now move the
  weight by the machine's own step, snapping to the next reachable notch.

- Finished Watch workouts now send their measured duration, active calories,
  HealthKit state, and workout identifier back to the iPhone history.
- The iPhone app embeds the Watch app and keeps Home Assistant entities in sync
  through idempotent history uploads.
- Project documentation, release guidance, source comments, fallback system
  messages, and development-region defaults now use English.
- All app targets now share marketing version `26.08` and build number `2`.

### Fixed

- Rest-timer completion now provides haptic feedback on Apple Watch.
- Watch commands are queued until connectivity is active instead of being
  silently dropped.
- The set editor on Apple Watch no longer wraps its stepper labels across
  several oversized lines, which made reps and weight unreadable and the
  controls hard to hit.
- The rest timer's skip button is no longer covered by the page indicator dots.

## [1.0] - 2026-08-06

### Fixed

- Set input fields remain tappable while the keyboard is open.
- Tapping a set value selects its contents, and weights no longer require two
  decimal places in compact fields.

### Added

- Native iPhone and iPad workout tracking with Live Activities.
- Apple Watch companion app, Apple Health export, CSV export, and optional
  Home Assistant integration through HealthPit.
- Multilingual interface support and optional StoreKit contributions.
