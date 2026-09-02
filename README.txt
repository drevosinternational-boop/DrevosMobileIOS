DREVOS iOS — verified Swift 6 concurrency patch v5
===================================================

Apply at the ROOT of the DrevosMobileIOS repository and overwrite exactly:

  DrevosIOS/Core/TemperatureUnit.swift
  DrevosIOS/Recipes/RecipeService.swift

Do not delete or replace your real Firebase file:

  DrevosIOS/Resources/GoogleService-Info.plist

Then commit both changed Swift files to main and start a NEW Codemagic build:

  Drevos iOS - compile check

WHAT THIS FIXES
---------------
The complete latest Xcode log contains one unique app-source error:

  TemperatureUnit.swift:12:16
  AppSettings.shared is not concurrency-safe under Swift 6.

This patch:
- makes TemperatureUnit explicitly Sendable;
- explicitly imports Combine;
- isolates mutable AppSettings state to @MainActor;
- reads AppSettings and ConnectionMonitor in RecipeService through
  MainActor.run, fixing the immediate follow-on actor-isolation issue too.

No Firebase paths, recipe logic, device logic, bundle ID, project.yml, or
Codemagic configuration are changed by this patch.
