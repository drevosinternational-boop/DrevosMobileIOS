DREVOS iOS FIREBASE BUNDLE ID FIX

Your existing Firebase Apple app is registered as:
  mobile.ios

This patch changes the iOS project, Codemagic signing config, and Firebase validation from com.drevos.smoker to mobile.ios.

Copy these files over the same paths in your Git repository, commit, push, then start the compile-check workflow again.

Keep the real Firebase file at:
  DrevosIOS/Resources/GoogleService-Info.plist

That plist must have BUNDLE_ID = mobile.ios.
