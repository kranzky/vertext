# Codesigning guide for Vertext

To change the app icon for all platforms, follow these steps:

  1. Prepare your icon files:
    - Create a high-resolution icon file (ideally 1024x1024 pixels) and save it as assets/icons/app_icon.png
    - For Android adaptive icons, create a foreground image and save it as assets/icons/app_icon_foreground.png
  2. Run the icon generator:
  After placing your icon files in the correct locations, run:
  flutter pub run flutter_launcher_icons

  This will generate all the necessary icon files for each platform with the correct sizes and formats.

## macOS

### Build a release version of the app

flutter build macos --release

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

## Windows

### Build a release version of the app

flutter build windows --release

### Sign the application

1. Obtain a Code Signing Certificate from a trusted Certificate Authority (Comodo, DigiCert, GlobalSign, etc.)
2. Use SignTool (part of Windows SDK) to sign the application:

cd build\windows\runner\Release

signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a vertext.exe

### Package as an installer

There are several options for creating Windows installers:

#### Option 1: Inno Setup

1. Download and install [Inno Setup](https://jrsoftware.org/isinfo.php)
2. Create an Inno Setup Script (.iss) file:

```
[Setup]
AppName=Vertext
AppVersion=1.0.0
DefaultDirName={pf}\Vertext
DefaultGroupName=Vertext
OutputDir=..\Output
OutputBaseFilename=VertextSetup-1.0.0
Compression=lzma
SolidCompression=yes
SignTool=signtool $f

[Files]
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Vertext"; Filename: "{app}\vertext.exe"
Name: "{commondesktop}\Vertext"; Filename: "{app}\vertext.exe"
```

3. Compile the script to create the installer:

```
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" YourScript.iss
```

#### Option 2: MSIX Package

1. Install the MSIX Packaging Tool from the Microsoft Store
2. Use the tool to create an MSIX package from your build folder
3. Sign the MSIX package:

```
signtool sign /fd SHA256 /a /f YourCertificate.pfx /p YourPassword Vertext.msix
```

#### Option 3: NSIS (Nullsoft Scriptable Install System)

1. Download and install [NSIS](https://nsis.sourceforge.io/)
2. Create an NSIS script (.nsi) file:

```
!include "MUI2.nsh"

Name "Vertext"
OutFile "VertextSetup-1.0.0.exe"
InstallDir "$PROGRAMFILES\Vertext"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "build\windows\runner\Release\*.*"
  
  CreateDirectory "$SMPROGRAMS\Vertext"
  CreateShortcut "$SMPROGRAMS\Vertext\Vertext.lnk" "$INSTDIR\vertext.exe"
  CreateShortcut "$DESKTOP\Vertext.lnk" "$INSTDIR\vertext.exe"
  
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR"
  Delete "$SMPROGRAMS\Vertext\Vertext.lnk"
  RMDir "$SMPROGRAMS\Vertext"
  Delete "$DESKTOP\Vertext.lnk"
SectionEnd
```

3. Compile the script to create the installer:

```
makensis YourScript.nsi
```

4. Sign the installer:

```
signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a VertextSetup-1.0.0.exe
```

### Distribute the signed installer

Users can download and run the signed installer directly. Windows will show the publisher name from your certificate.
