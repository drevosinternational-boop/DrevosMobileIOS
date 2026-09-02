from pathlib import Path
import hashlib
import sys

root = Path.cwd().resolve()
if not (root / "DrevosIOS").is_dir():
    root = Path(__file__).resolve().parent

checks = {
    "DrevosIOS/Core/TemperatureUnit.swift": [
        "import Combine",
        "enum TemperatureUnit: String, CaseIterable, Identifiable, Sendable",
        "@MainActor\nfinal class AppSettings: ObservableObject",
    ],
    "DrevosIOS/Recipes/RecipeService.swift": [
        "let smokerId = try await MainActor.run",
        "let controlState = await MainActor.run",
        "testingMode: AppSettings.shared.testingMode",
        "canControl: ConnectionMonitor.shared.canControl(smokerId: smokerId)",
        "if controlState.testingMode { return }",
        "guard controlState.canControl else",
    ],
}

errors = []
for relative, required in checks.items():
    path = root / relative
    if not path.is_file():
        errors.append(f"Missing: {relative}")
        continue
    text = path.read_text(encoding="utf-8")
    for marker in required:
        if marker not in text:
            errors.append(f"{relative}: missing expected marker: {marker!r}")

service_path = root / "DrevosIOS/Recipes/RecipeService.swift"
if service_path.is_file():
    service = service_path.read_text(encoding="utf-8")
    if "guard !AppSettings.shared.testingMode" in service:
        errors.append("RecipeService still contains unsafe direct AppSettings access.")

project_path = root / "project.yml"
if project_path.is_file():
    project = project_path.read_text(encoding="utf-8")
    if "PRODUCT_BUNDLE_IDENTIFIER: mobile.ios" not in project:
        errors.append("project.yml does not use Firebase Apple bundle ID mobile.ios.")
    if "DrevosIOS/Resources/Info.plist\n        buildPhase: resources" in project:
        errors.append("Info.plist is incorrectly configured as a copied resource.")

if errors:
    print("PATCH VALIDATION FAILED")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("PATCH VALIDATION PASSED")
print("Swift 6 AppSettings and RecipeService actor isolation is present.")
