DREVOS iOS - Info.plist duplicate build fix v4

Replace the repository-root project.yml with this file.
Commit and push to main, then start a NEW Codemagic compile-check build.

Why this version is different from the previous patch:
The previous project.yml still declared the whole DrevosIOS/Resources directory as a resource source and tried to exclude Info.plist. The build log proves XcodeGen nevertheless put Info.plist into Copy Bundle Resources.

This v4 configuration does not include the Resources directory at all. It lists only the resources that must actually be copied:
  - DrevosIOS/Resources/Assets.xcassets
  - DrevosIOS/Resources/GoogleService-Info.plist

Info.plist is managed only by the target `info:` block:
  DrevosIOS/Resources/Info.plist

Expected result: Xcode has exactly one producer for DREVOS.app/Info.plist: ProcessInfoPlistFile.
