# Before the first Codemagic build

1. In Firebase project `drevos-9827e`, register an Apple app with bundle ID **`mobile.ios`**.
2. Download the resulting **`GoogleService-Info.plist`**.
3. Put it at `DrevosIOS/Resources/GoogleService-Info.plist`.
4. Make sure Google is enabled in Firebase Authentication.
5. Push the repository contents to GitHub with `codemagic.yaml` at the repository root.
6. Connect that repository to Codemagic.
7. Run **`ios-simulator-check`** first. This is the fastest way to catch any macOS/Xcode compile issue before Apple signing is involved.
8. For a real iPhone/TestFlight build, create the app record for `mobile.ios` in App Store Connect and configure the Codemagic App Store Connect integration named **`codemagic`**.
9. Run **`ios-testflight`**.
10. Install TestFlight on the iPhone and accept the build.

## Current backend paths

- `standard_recipes/*`
- `users/<firebaseUid>/devices/*`
- `users/<firebaseUid>/recipes/saved/*`
- `users/<firebaseUid>/recipes/favorites`
- `smokers/<smokerId>/presence/last_seen`
- `smokers/<smokerId>/state/*`
- `smokers/<smokerId>/telemetry/*`
- `smokers/<smokerId>/current_recipe/*`

Smokers are linked by ID only. There is no pairing-code requirement in this iOS build.
