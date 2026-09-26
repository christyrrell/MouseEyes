# Distributing MouseEyes on the Mac App Store

MouseEyes ships two ways from the same codebase: a notarized direct download
(see `DISTRIBUTION.md`) and the Mac App Store. Both builds are sandboxed
(`MouseEyes.entitlements`), so the only difference is how the archive is signed
on export.

## One-Time Setup

1. **Create the app record** in [App Store Connect](https://appstoreconnect.apple.com)
   > Apps > **+** > New App:
   - Platform: macOS
   - Bundle ID: `com.mouseyes.app` (register it under Certificates, Identifiers
     & Profiles first if it isn't listed)
   - SKU: anything unique, e.g. `mouseeyes`
2. **Signing assets.** App Store export needs an *Apple Distribution* (or
   *Mac App Distribution*) certificate, a *Mac Installer Distribution*
   certificate, and a Mac App Store provisioning profile for `com.mouseyes.app`.
   The easiest way to get all three is to let Xcode create them during the
   first upload (see Option A below).

## Step 1: Bump the Build Number

Every upload needs a `CFBundleVersion` higher than the last one uploaded, even
when `CFBundleShortVersionString` is unchanged. Edit `Info.plist`.

## Step 2: Archive

```bash
xcodebuild archive \
  -project MouseEyes.xcodeproj \
  -scheme MouseEyes \
  -configuration Release \
  -archivePath build/appstore/MouseEyes.xcarchive
```

The archive is signed with Developer ID; export re-signs it for the App Store.

## Step 3: Export and Upload

### Option A: Xcode Organizer (recommended for the first upload)

Open the archive (`open build/appstore/MouseEyes.xcarchive`), then in the
Organizer choose **Distribute App > App Store Connect > Upload**. Xcode creates
any missing certificates and profiles, validates the build, and uploads it.

### Option B: Command line

```bash
xcodebuild -exportArchive \
  -archivePath build/appstore/MouseEyes.xcarchive \
  -exportPath build/appstore/export \
  -exportOptionsPlist ExportOptions-AppStore.plist \
  -allowProvisioningUpdates
```

This produces `build/appstore/export/MouseEyes.pkg`. Upload it with the
Transporter app, or change `destination` to `upload` in
`ExportOptions-AppStore.plist` to have `xcodebuild` upload it directly.

## Step 4: Submit for Review

In App Store Connect, attach the processed build to a new version, then fill in:

- **Screenshots**: at least one at 1280x800, 1440x900, 2560x1600, or 2880x1800.
  Multi-monitor shots showing each display's eyes looking a different way sell
  the app best.
- **Privacy**: "Data Not Collected"; privacy policy URL
  `https://www.tyrrellsworld.com/privacy.html`.
- **Category**: Utilities (matches `LSApplicationCategoryType`).
- **Export compliance** is pre-answered by `ITSAppUsesNonExemptEncryption = false`.

## Review Notes

- Describe the alternate eye style generically in store metadata ("a fiery,
  lidless eye mode") rather than by the trademarked in-app name. If review
  objects to the in-app name, rename it in `EyeballView.swift` / the menu.
- Users coming from the pre-sandbox direct download start with fresh
  preferences (eye style and Cmd-drag position reset once), because sandboxed
  apps read preferences from their container.
