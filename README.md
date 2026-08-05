# GymPit

GymPit is a native workout app for iPhone, iPad, and Apple Watch. The Xcode
project also contains a Live Activity for active workouts and optional support
through StoreKit 2.

## Open the project

Open `GymPit.xcodeproj` in Xcode and select the shared `GymPit` scheme.

## Folder structure

- `Sources/`: iPhone/iPad app, Live Activity, and Watch app
- `Config/`: StoreKit and App Store export configuration
- `Docs/`: release instructions, App Store copy, and integration notes
- `Scripts/`: helper scripts for generating exercise images
- `Release/`: current signed archive, App Store export, and older archives

## Requirements

- Xcode 16 or later
- iOS 18 or later
- watchOS 11 or later
- Apple Developer Team `Q3CD6ZPU9J`

## Healthpit bridge role

GymPit always connects as a slave to the Healthpit Docker master. It validates
the master role during discovery and during the session handshake. A session
with another master is rejected, and workout synchronization requires a valid
slave session token.

The Apple Watch does not open a separate Docker session. It remains subordinate
to the paired GymPit iPhone, which is the registered Docker slave.

Release-related steps are documented in `Docs/Release.md`.
