from pathlib import Path
import sys

root = Path(__file__).resolve().parent
project = (root / 'project.yml').read_text(encoding='utf-8')
cm = (root / 'codemagic.yaml').read_text(encoding='utf-8')

checks = {
    'bundle id mobile.ios': 'PRODUCT_BUNDLE_IDENTIFIER: mobile.ios' in project,
    'project Swift 5': 'SWIFT_VERSION: 5.0' in project,
    'project minimal concurrency': 'SWIFT_STRICT_CONCURRENCY: minimal' in project,
    'Codemagic validates Swift 5': "grep -q 'SWIFT_VERSION = 5.0'" in cm,
    'Codemagic validates concurrency': "grep -q 'SWIFT_STRICT_CONCURRENCY = minimal'" in cm,
    'build forces Swift 5': 'SWIFT_VERSION=5.0' in cm,
    'build forces minimal concurrency': 'SWIFT_STRICT_CONCURRENCY=minimal' in cm,
    'generic simulator retained': "-destination 'generic/platform=iOS Simulator'" in cm,
    'arm64 retained': 'ARCHS=arm64' in cm,
}
failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(('OK  ' if ok else 'FAIL') + name)
if failed:
    print('\nPATCH VALIDATION FAILED')
    sys.exit(1)
print('\nPATCH VALIDATION PASSED')
