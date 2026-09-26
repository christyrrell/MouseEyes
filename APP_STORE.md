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

### Option C: GitHub Actions

`.github/workflows/app-store.yml` archives and uploads on every `v*` tag push,
or manually from the Actions tab. It signs with Xcode cloud signing through an
App Store Connect API key, so no certificates live in the repo or runner.
Versioning is automatic: a `v1.3` tag sets `CFBundleShortVersionString` to
`1.3` (manual runs keep the version in `Info.plist`), and `CFBundleVersion` is
the workflow run number + 100, so Step 1 doesn't apply to CI builds.

One-time setup:

1. App Store Connect > Users and Access > Integrations > App Store Connect API >
   **Generate API Key** with the **Admin** role (cloud signing needs Admin to
   create distribution certificates). Download the `.p8` file; it can only be
   downloaded once.
2. Add three repository secrets (Settings > Secrets and variables > Actions):
   - `ASC_KEY_ID`: the key ID
   - `ASC_ISSUER_ID`: the issuer ID shown above the key list
   - `ASC_KEY_P8`: the full contents of the `.p8` file

Release: `git tag v1.3 && git push origin v1.3`. Create the matching version
(1.3) in App Store Connect so the build can be attached to it. The processed build appears
in App Store Connect after a few minutes; Step 4 is still done by hand.

## Step 4: Submit for Review

In App Store Connect, attach the processed build to a new version, then fill in:

- **Screenshots**: upload `AppStore/screenshots/*.png` (2880x1800). Regenerate
  them with `AppStore/screenshots/make.sh`, which renders the real
  `EyeballView` drawing code.
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
