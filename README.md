# DREVOS iPhone app

Native SwiftUI iOS port of the current Drevos Android controller, prepared for a Windows -> GitHub -> Codemagic -> TestFlight workflow.

## Implemented in this repository

- Firebase Authentication: email/password + Google Sign-In
- Firebase UID is the database user ID: `/users/<firebaseUid>`
- Multi-user smoker linking by **smoker ID only**
- Same smoker can be linked by unlimited accounts
- Per-user smoker alias and active-smoker selection
- Home telemetry and smoker controls
- Physical-smoker connectivity from `/smokers/<id>/presence/last_seen`
- `Smoker is offline` only when Firebase is live and the heartbeat is stale
- Shared `/standard_recipes`
- User `/users/<uid>/recipes/saved`
- User `/users/<uid>/recipes/favorites`
- Editing a standard preset creates a personal UUID copy
- Recipe Start stages one execution copy under the active smoker and writes the current recipe command
- Dark Drevos UI with orange selection state
- Settings and sign-out
- Codemagic compile-check and TestFlight workflows

The Instructions tab is intentionally a placeholder, matching the current Android state.

## Important: one Firebase iOS file is required

Android `google-services.json` cannot be used for an iPhone app.

In Firebase Console, open project `drevos-9827e` and add an **Apple/iOS app** with this exact bundle ID:

```
com.drevos.smoker
```

Download:

```
GoogleService-Info.plist
```

Put it here before pushing/building:

```
DrevosIOS/Resources/GoogleService-Info.plist
```

The file must contain the iOS `REVERSED_CLIENT_ID` used by Google Sign-In. The build script reads it automatically, so you do not need to manually edit an Xcode project.

## Push to GitHub from Windows

Upload the **contents** of this folder to one GitHub repository. Keep `codemagic.yaml` at the repository root.

Recommended first commit:

```
project.yml
codemagic.yaml
Config/
DrevosIOS/
scripts/
README.md
```

`DrevosIOS.xcodeproj` is generated on the macOS builder by XcodeGen and should not be committed.

## Codemagic: first compile check

1. Connect GitHub to Codemagic and give the integration access to this repository.
2. Add the repository as an application.
3. Codemagic will find `codemagic.yaml`.
4. Run workflow:

```
ios-simulator-check
```

This does not need Apple signing. It proves that the iOS code, Firebase packages and project generation compile on macOS/Xcode.

## Codemagic: real iPhone through TestFlight

You need Apple Developer Program membership for normal signed/TestFlight distribution.

One-time setup:

1. In Apple Developer / App Store Connect create the app ID `com.drevos.smoker`.
2. Create the app in App Store Connect.
3. In Codemagic add your App Store Connect API integration and name it exactly:

```
codemagic
```

4. In Codemagic Code signing identities, generate/upload an Apple Distribution certificate and App Store provisioning profile for `com.drevos.smoker`.
5. Run workflow:

```
ios-testflight
```

The workflow builds a signed `.ipa` and uploads it to TestFlight.

## Firebase database layout expected by the app

```
standard_recipes/
  drevos_preset_001/
  ...

users/
  <firebaseUid>/
    devices/
      smoker_1/
        alias: "malina"
        linked_at: 123...
    recipes/
      favorites: [...]
      saved/
        <uuid>/...

smokers/
  smoker_1/
    presence/
      last_seen: 123...
    state/
    telemetry/
    current_recipe/
```

No pairing-code node is used by the iOS code.

## Firebase rules

`FIREBASE_RULES_REFERENCE.json` contains the same ID-only rule model used by the current Android update. It is included as a reference; do not overwrite newer production rules blindly.

## Local Mac build later, if you ever get access to a Mac

```
brew install xcodegen
bash scripts/prepare_firebase.sh
xcodegen generate
open DrevosIOS.xcodeproj
```

Until then Codemagic performs those exact macOS-only steps for you.
