DREVOS iOS - V9 Swift language-mode fix

Build #11 reached the Drevos Swift sources successfully.
The full Xcode log contains exactly one compiler error:
  ActiveSmokerStore.swift:23:9
  cannot access property 'authHandle' ... from nonisolated deinit

The important discovery is that the Drevos app target was still compiled with:
  -swift-version 6

That means the earlier Swift-5 compatibility setting was not present in the generated Xcode project used by build #11.

This patch fixes the configuration rather than changing app behavior:
- project.yml: SWIFT_VERSION = 5.0
- project.yml: SWIFT_STRICT_CONCURRENCY = minimal
- codemagic.yaml: verifies those generated settings and FAILS EARLY if they are wrong
- codemagic.yaml: also forces the same two values on the simulator xcodebuild command
- preserves the generic arm64 simulator build from V8

Replace ONLY these two root-level files:
  project.yml
  codemagic.yaml

Do not replace or delete:
  DrevosIOS/Resources/GoogleService-Info.plist

After committing, the "Verify generated project settings" step must print:
  PRODUCT_BUNDLE_IDENTIFIER = mobile.ios
  SWIFT_VERSION = 5.0
  SWIFT_STRICT_CONCURRENCY = minimal

If that verification succeeds, the ActiveSmokerStore deinit issue is no longer a Swift-6 hard error.
