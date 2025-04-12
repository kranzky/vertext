# Codesigning guide for Vertext

## Build a release version of the app

flutter build macos --release

## Create a fancy DMG

create-dmg --volname "Vertext" --window-pos 200 120 --window-size 800 400 --icon-size 100 --icon "vertext.app" 200 190 --hide-extension "vertext.app" --app-drop-link 600 185 dist/Vertext-1.0.0.dmg build/macos/Build/Products/Release/vertext.app

## Sign it

1. Get an Apple Developer account and Developer ID certificate
2. Use these commands to sign the app:

```
### Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name (TEAM_ID)" /path/to/vertext.app

### Verify signature
codesign --verify --verbose /path/to/vertext.app

### Create DMG with signing
create-dmg --volname "Vertext" --window-pos 200 120 --window-size 800 400 --icon-size 100 --icon "vertext.app" 200 190 --hide-extension "vertext.app" --app-drop-link 600 185 --codesign "Developer ID Application: Your Name (TEAM_ID)" Vertext-1.0.0-signed.dmg /path/to/vertext.app

### Submit for notarization
xcrun notarytool submit Vertext-1.0.0-signed.dmg --apple-id your.email@example.com --team-id TEAM_ID --wait

### Staple notarization ticket
xcrun stapler staple Vertext-1.0.0-signed.dmg
```

3. Distribute the signed and notarized DMG to users
