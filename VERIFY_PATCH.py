from pathlib import Path
import sys

root = Path(__file__).resolve().parent
checks = {
    "DrevosIOS/Devices/DevicesViewModel.swift": [
        '{ [self] in try await self.service.addDevice(id: id) }',
        '{ [self] in try await self.service.renameDevice(id: device.id, name: name) }',
        '{ [self] in try await self.service.removeDevice(id: device.id) }',
    ],
    "DrevosIOS/Home/HomeViewModel.swift": [
        '{ [self] in self.state.heatingEnabled',
        'try await self.service.stopRecipe(smokerId: id)',
        'try await self.service.setState(smokerId: id, field: field, value: value)',
    ],
    "DrevosIOS/Recipes/RecipesViewModel.swift": [
        'try await self.service.setFavorite',
        'try await self.service.start(recipe)',
        'self.isWorking = false',
    ],
    "DrevosIOS/Auth/AuthSession.swift": [
        'self.errorMessage = error.localizedDescription',
        'self.isLoading = false',
    ],
}

failed = False
for rel, needles in checks.items():
    p = root / rel
    if not p.is_file():
        print(f"MISSING: {rel}")
        failed = True
        continue
    text = p.read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            print(f"FAILED: {rel}: missing {needle!r}")
            failed = True

if failed:
    sys.exit(1)

print("PATCH VALIDATION PASSED")
print("DevicesViewModel explicit escaping-closure captures: present")
print("HomeViewModel explicit local-update captures: present")
print("Recipes/Auth async self references: present")
