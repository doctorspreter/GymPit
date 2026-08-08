# GymPit 26.08 – Release Guide

## Already prepared

- Product name, targets, schemes, files, and bundle identifiers are consistently
  named `GymPit`.
- The iOS/iPadOS app, Live Activity, and watchOS app build in Release mode.
- Bundle identifiers:
  - `app.gympit`
  - `app.gympit.liveactivity`
  - `app.gympit.watchkitapp`
- App Group: `group.app.gympit`
- HealthKit usage descriptions and entitlements for iOS and watchOS.
- Validated app icons for iOS, iPadOS, and watchOS.
- A privacy manifest in all three bundles.
- Export compliance for non-exempt encryption set to `NO`.
- StoreKit 2 purchase handling with four consumable products.
- A local StoreKit configuration attached to the `GymPit` scheme.
- 68 original exercise illustrations.
- App Store Connect export options in
  `Config/Distribution/AppStoreUpload.plist`.
- Version `26.08` and build number `2` across all targets.

## One-time Apple account setup

These steps require Apple Developer and App Store Connect access and cannot be
completed from the source project alone:

1. Register App IDs for all three bundle identifiers.
2. Register `group.app.gympit` and assign it to all three App IDs.
3. Enable HealthKit and App Groups for the iOS and Watch apps. Enable App Groups
   for the Live Activity extension.
4. Create an iOS app record for `app.gympit` in App Store Connect.
5. Complete the Paid Apps Agreement, tax information, and banking information.
   Apple also requires this before testing in-app purchases in the sandbox.
6. Under **Monetization > In-App Purchases**, create these four products as
   **Consumable** products:

| Reference name | Product ID | Local test price |
|---|---|---:|
| Small coffee | `app.gympit.support.small_coffee` | €0.99 |
| Supporter | `app.gympit.support.supporter` | €2.99 |
| Big support | `app.gympit.support.big_support` | €5.99 |
| Fund the project | `app.gympit.support.project` | €9.99 |

Do not change product IDs after creation. Add prices, availability, localized
copy, and one review screenshot per product. Submit the in-app purchases with
the first app version that includes them.

Apple documentation:

- [Create consumable products](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases/)
- [Configure in-app purchases](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/)
- [Enable app capabilities](https://developer.apple.com/help/account/identifiers/enable-app-capabilities/)
- [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)

## Test StoreKit locally

1. Select the `GymPit` scheme.
2. Run the app from Xcode. The Run action already uses
   `Config/StoreKit/GymPitProducts.storekit`.
3. Open **Settings > Support**.
4. Confirm that all four prices appear.
5. Use Xcode's StoreKit Transaction Manager to test a successful purchase, a
   cancellation, and a pending transaction.

App Store and TestFlight builds receive product names and localized prices only
from App Store Connect. If products are missing or unavailable there, the app
does not invent fallback prices.

## Archive and upload

Increase `CURRENT_PROJECT_VERSION` before every upload. Then in Xcode:

1. Select **Any iOS Device (arm64)**.
2. Choose **Product > Archive**.
3. In Organizer, choose **Validate App**, then
   **Distribute App > App Store Connect**.
4. Assign the processed build to version 26.08 in App Store Connect and test it
   through TestFlight first.

Alternatively, use the terminal:

```sh
xcodebuild \
  -project GymPit.xcodeproj \
  -scheme GymPit \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath Release/Current/GymPit-26.08.xcarchive \
  -allowProvisioningUpdates \
  archive

xcodebuild \
  -exportArchive \
  -archivePath Release/Current/GymPit-26.08.xcarchive \
  -exportOptionsPlist Config/Distribution/LocalAppStoreExport.plist \
  -exportPath Release/Current/AppStoreExport \
  -allowProvisioningUpdates
```

The local export creates
`Release/Current/AppStoreExport/GymPit.ipa` without uploading it. For a direct
upload, use **TestFlight & App Store** in Organizer or
`Config/Distribution/AppStoreUpload.plist` in the terminal.

## Required information before submission

- A public URL for the privacy policy in `Docs/AppStore/Privacy.md`.
- Support URL and support email address.
- App screenshots for every required iPhone, iPad, and Apple Watch size.
- Age-rating questionnaire.
- App Privacy answers consistent with the privacy policy.
- A review screenshot for every in-app purchase.
- TestFlight smoke test covering workout tracking, rest notifications, history,
  CSV, Apple Health, Home Assistant, Watch sync, Live Activity, and all four
  contribution options.

Release history lives in [`CHANGELOG.md`](../CHANGELOG.md).
