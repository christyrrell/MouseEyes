# Distributing MouseEyes Outside the App Store

This guide covers building, notarizing, and distributing MouseEyes as a direct download.

## Prerequisites

- An **Apple Developer Program** membership ($99/year)
- Xcode with command-line tools installed
- A **Developer ID Application** signing certificate in your keychain
- An app-specific password for your Apple ID (for `notarytool`)

### One-Time Setup: App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com) > Sign-In and Security > App-Specific Passwords
2. Generate a new password and label it something like `notarytool`
3. Store the credentials in your keychain for reuse:

```bash
xcrun notarytool store-credentials "MouseEyes-Notary" \
  --apple-id "your@email.com" \
  --team-id "4772RJKZ43" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

This saves a named profile so you don't need to pass credentials each time.

## Step 1: Archive the Build

Clean and archive a release build via Xcode:

```bash
xcodebuild archive \
  -project MouseEyes.xcodeproj \
  -scheme MouseEyes \
  -configuration Release \
  -archivePath build/MouseEyes.xcarchive
```

Or use the Xcode GUI: **Product > Archive**.

## Step 2: Export the App

Export the archive as a Developer ID-signed application:

```bash
xcodebuild -exportArchive \
  -archivePath build/MouseEyes.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

You'll need an `ExportOptions.plist` that specifies Developer ID distribution:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>4772RJKZ43</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

Alternatively, if you're building from the command line without archiving:

```bash
xcodebuild -project MouseEyes.xcodeproj \
  -scheme MouseEyes \
  -configuration Release \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  DEVELOPMENT_TEAM="4772RJKZ43" \
  build
```

## Step 3: Verify Code Signing

Before notarizing, confirm the app is signed correctly:

```bash
codesign --verify --deep --strict build/export/MouseEyes.app
codesign -dv --verbose=4 build/export/MouseEyes.app
```

Check that:
- `Authority` starts with `Developer ID Application:`
- The `TeamIdentifier` matches `4772RJKZ43`
- The hardened runtime is enabled (`flags=0x10000(runtime)`)

If the hardened runtime flag is missing, re-sign:

```bash
codesign --force --deep --options runtime \
  --sign "Developer ID Application: Your Name (4772RJKZ43)" \
  build/export/MouseEyes.app
```

## Step 4: Create a ZIP for Notarization

Apple's notary service accepts ZIP, DMG, or PKG. A ZIP is simplest:

```bash
ditto -c -k --keepParent build/export/MouseEyes.app build/MouseEyes.zip
```

Use `ditto`, not `zip` — it preserves macOS metadata, extended attributes, and the code signature.

## Step 5: Submit for Notarization

```bash
xcrun notarytool submit build/MouseEyes.zip \
  --keychain-profile "MouseEyes-Notary" \
  --wait
```

The `--wait` flag blocks until Apple finishes processing (usually 2-15 minutes). On success you'll see:

```
  status: Accepted
```

If rejected, inspect the log:

```bash
xcrun notarytool log <submission-id> \
  --keychain-profile "MouseEyes-Notary"
```

Common rejection reasons:
- **Hardened runtime not enabled** — re-sign with `--options runtime`
- **Unsigned nested code** — embedded frameworks or helpers need signing too
- **Deprecated APIs flagged** — check the detailed JSON log for specifics

## Step 6: Staple the Ticket

Stapling attaches the notarization ticket to the app so users can verify it offline, without Apple's servers:

```bash
xcrun stapler staple build/export/MouseEyes.app
```

Verify the staple:

```bash
xcrun stapler validate build/export/MouseEyes.app
```

## Step 7: Package for Distribution

### Option A: ZIP

Re-create the ZIP after stapling (the previous ZIP doesn't contain the ticket):

```bash
ditto -c -k --keepParent build/export/MouseEyes.app build/MouseEyes.zip
```

### Option B: DMG (Recommended)

A DMG provides a better user experience — the user opens it and drags the app to Applications:

```bash
hdiutil create -volname "MouseEyes" \
  -srcfolder build/export/MouseEyes.app \
  -ov -format UDZO \
  build/MouseEyes.dmg
```

Then notarize and staple the DMG itself:

```bash
xcrun notarytool submit build/MouseEyes.dmg \
  --keychain-profile "MouseEyes-Notary" \
  --wait

xcrun stapler staple build/MouseEyes.dmg
```

## Quick Reference

Full pipeline in one block (after initial setup):

```bash
# Archive
xcodebuild archive \
  -project MouseEyes.xcodeproj \
  -scheme MouseEyes \
  -configuration Release \
  -archivePath build/MouseEyes.xcarchive

# Export
xcodebuild -exportArchive \
  -archivePath build/MouseEyes.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist

# Notarize
ditto -c -k --keepParent build/export/MouseEyes.app build/MouseEyes.zip
xcrun notarytool submit build/MouseEyes.zip \
  --keychain-profile "MouseEyes-Notary" --wait

# Staple
xcrun stapler staple build/export/MouseEyes.app

# Package as DMG
hdiutil create -volname "MouseEyes" \
  -srcfolder build/export/MouseEyes.app \
  -ov -format UDZO build/MouseEyes.dmg
xcrun notarytool submit build/MouseEyes.dmg \
  --keychain-profile "MouseEyes-Notary" --wait
xcrun stapler staple build/MouseEyes.dmg
```

## Troubleshooting

### "MouseEyes can't be opened because Apple cannot check it for malicious software"

The app wasn't notarized, or the ticket wasn't stapled. Re-run steps 5 and 6.

### Gatekeeper rejects after notarization

```bash
spctl --assess --type exec -vv build/export/MouseEyes.app
```

The output should say `source=Notarized Developer ID`. If it says `source=Developer ID` without "Notarized", the staple is missing.

### Users on older macOS

Notarization is enforced on macOS 10.15+. Users on 10.14 and earlier can run Developer ID-signed apps without notarization, though MouseEyes requires macOS 15.0+ per `LSMinimumSystemVersion`.

### Checking a downloaded copy

Users (or you) can verify a downloaded copy:

```bash
codesign --verify --deep --strict /Applications/MouseEyes.app
spctl --assess --type exec -vv /Applications/MouseEyes.app
stapler validate /Applications/MouseEyes.app
```
