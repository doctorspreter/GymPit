# GymPit 1.0 – Release

## Bereits vorbereitet

- Produktname, Targets, Schemes, Dateien und Bundle-IDs auf `GymPit` vereinheitlicht
- iOS/iPadOS-App, Live Activity und watchOS-App im Release-Modus gebaut
- Bundle-IDs:
  - `app.gympit`
  - `app.gympit.liveactivity`
  - `app.gympit.watchkitapp`
- App Group: `group.app.gympit`
- HealthKit-Nutzungstexte und HealthKit-Entitlement vorhanden
- App-Icons für iOS/iPadOS und watchOS validiert
- Privacy Manifest in allen drei Bundles
- Export-Compliance für nicht ausgenommene Verschlüsselung auf `NO`
- StoreKit-2-Kauflogik mit vier Verbrauchsprodukten
- Lokale StoreKit-Konfiguration am Scheme `GymPit`
- Nicht mehr unterstützte Fremdimporte und die zugehörige Schnittstellenlogik entfernt
- Exportoptionen für App Store Connect in `ExportOptions.plist`

## Einmalig im Apple-Account

Diese Schritte benötigen die Apple-Developer-/App-Store-Connect-Zugangsdaten und können nicht allein im Quellprojekt erledigt werden:

1. App-IDs für die drei Bundle-IDs registrieren.
2. `group.app.gympit` registrieren und allen drei App-IDs zuweisen.
3. Für die iOS-App HealthKit und App Groups aktivieren; für Erweiterung und Watch-App App Groups aktivieren.
4. In App Store Connect einen iOS-App-Eintrag für `app.gympit` anlegen.
5. Paid Apps Agreement, Steuer- und Bankdaten aktivieren. Apple verlangt dies auch zum Sandbox-Test von In-App-Käufen.
6. Unter „Monetarisierung > In-App-Käufe“ diese vier Produkte als **Verbrauchsprodukt** anlegen:

| Referenzname | Produkt-ID | lokaler Testpreis |
|---|---|---:|
| Kleiner Kaffee | `app.gympit.support.small_coffee` | 0,99 € |
| Unterstützer | `app.gympit.support.supporter` | 2,99 € |
| Große Unterstützung | `app.gympit.support.big_support` | 5,99 € |
| Projekt fördern | `app.gympit.support.project` | 9,99 € |

Produkt-IDs nach dem Anlegen nicht mehr ändern. Preise, Verfügbarkeit, deutsche/englische Texte und jeweils ein Review-Screenshot ergänzen. Beim ersten Release die In-App-Käufe gemeinsam mit Version 1.0 zur Prüfung einreichen.

Apple-Hilfe:

- [Verbrauchsprodukte anlegen](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases/)
- [In-App-Käufe konfigurieren](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/)
- [App-Fähigkeiten aktivieren](https://developer.apple.com/help/account/identifiers/enable-app-capabilities/)
- [Build hochladen](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)

## StoreKit lokal testen

1. Scheme `GymPit` auswählen.
2. App aus Xcode starten. `GymPitProducts.storekit` ist dem Run-Scheme zugeordnet.
3. `Einstellungen > Unterstützen` öffnen.
4. Alle vier Preise müssen erscheinen.
5. Je einen erfolgreichen Kauf, Abbruch und „Pending“ über Xcodes StoreKit Transaction Manager testen.

Im App-Store-/TestFlight-Build kommen Produktname und lokalisierter Preis ausschließlich von App Store Connect. Wenn Produkte dort fehlen oder noch nicht verfügbar sind, zeigt die App keine erfundenen Ersatzpreise.

## Archiv und Upload

Vor jedem Upload `CURRENT_PROJECT_VERSION` erhöhen. Danach in Xcode:

1. Ziel „Any iOS Device (arm64)“ wählen.
2. `Product > Archive`.
3. Im Organizer `Validate App`, anschließend `Distribute App > App Store Connect`.
4. Den Build nach Verarbeitung in App Store Connect Version 1.0 zuordnen und zuerst über TestFlight prüfen.

Alternativ per Terminal:

```sh
xcodebuild \
  -project GymPit.xcodeproj \
  -scheme GymPit \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath Release/GymPit-1.0.xcarchive \
  archive

xcodebuild \
  -exportArchive \
  -archivePath Release/GymPit-1.0.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath Release/Export
```

## Pflichtangaben vor Einreichung

- Öffentliche URL für die vorbereitete Datenschutzerklärung aus `AppStore/Datenschutz.md`
- Support-URL und Support-E-Mail
- App-Screenshots für die verlangten iPhone-/iPad-Größen
- Altersfreigabe-Fragebogen
- App-Privacy-Angaben passend zur Datenschutzerklärung
- Review-Screenshot für jeden In-App-Kauf
- TestFlight-Smoke-Test: Training, Pause/Benachrichtigung, Historie, CSV, Apple Health, Watch-Sync, Live Activity und alle vier Unterstützungsoptionen
