DREVOS IOS V11 - EXPLICIT SELF CLEANUP
=====================================

This patch is for Codemagic build #13.

Replace these four files in the repository root:

DrevosIOS/Devices/DevicesViewModel.swift
DrevosIOS/Home/HomeViewModel.swift
DrevosIOS/Recipes/RecipesViewModel.swift
DrevosIOS/Auth/AuthSession.swift

Do NOT replace project.yml, codemagic.yaml, RecipeModels.swift,
or DrevosIOS/Resources/GoogleService-Info.plist.

Why this patch contains more than the three currently reported lines:
Build #13 stopped in the DevicesViewModel batch. HomeViewModel contains the
same escaping-closure capture pattern, so it is fixed at the same time to
avoid another build failing one batch later. RecipesViewModel and AuthSession
also use asynchronous closures and now use explicit self consistently.

The Swift 5 / minimal-concurrency settings from V9 must remain in place.
The RecipeModels fix from V10 must remain in place.
