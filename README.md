# GymPit

GymPit is a native workout app for iPhone, iPad, and Apple Watch. The Xcode
project also contains a Live Activity for active workouts and optional support
through StoreKit 2.

Workout data stays on the device. Apple Health, file export, and the connection
to Home Assistant are optional and only run once you set them up.

The Apple Watch app can run a strength workout without an active iPhone
connection. It shows the current exercise and set, controls rest timers,
records heart rate, active calories, and duration through HealthKit, and syncs
the finished session back to the iPhone history.

## Open the project

Open `GymPit.xcodeproj` in Xcode and select the shared `GymPit` scheme.

## Folder structure

- `Sources/`: iPhone/iPad app, Live Activity, and Watch app
- `Config/`: StoreKit and App Store export configuration
- `Docs/`: release instructions, App Store copy, and integration notes
- `Scripts/`: helper scripts for generating exercise images
- `Release/`: local build output, not part of this repository

Release history is maintained in [`CHANGELOG.md`](CHANGELOG.md).

## Requirements

- Xcode 16 or later
- iOS 18 or later
- watchOS 11 or later
- Your own Apple Developer team (set it in the project's signing settings)

## Home Assistant connection

GymPit sends finished workouts straight to Home Assistant. The receiving end is
the **HealthPit** custom integration, installed through HACS. It stores the
workouts and creates the entities.

In GymPit, the connection lives under
**Settings ▸ Data / Interfaces ▸ Home Assistant**:

1. Install the HealthPit integration in Home Assistant and add it under
   **Devices & services**.
2. Create a **long-lived access token** in your Home Assistant profile.
3. Enter the local address (and port, `8123` by default), optionally an
   external HTTPS address, and paste the token.

The token is the entire sign-in — there is no user name and no session. Home
Assistant derives from the token which user the workouts belong to, so every
person in the household uses their own token and gets their own entities. The
token is kept in the iOS keychain.

The local address is tried first; the external address is only used when the
local one cannot be reached, which makes the app work at home and away without
switching anything. Local connections go over HTTP, external ones must be
HTTPS.

The Apple Watch does not connect on its own. It stays paired with the iPhone,
and the iPhone does the sending.

Release-related steps are documented in [`Docs/Release.md`](Docs/Release.md).
