#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLIST="$ROOT_DIR/DrevosIOS/Resources/GoogleService-Info.plist"
OUT="$ROOT_DIR/Config/Generated.xcconfig"
EXPECTED_BUNDLE_ID="mobile.ios"

if [[ ! -f "$PLIST" ]]; then
  echo "ERROR: Missing DrevosIOS/Resources/GoogleService-Info.plist"
  echo "Register an iOS app in Firebase using bundle ID: $EXPECTED_BUNDLE_ID"
  echo "Then download GoogleService-Info.plist and put it at that exact path."
  exit 20
fi

PLISTBUDDY=/usr/libexec/PlistBuddy
REVERSED_CLIENT_ID="$($PLISTBUDDY -c 'Print :REVERSED_CLIENT_ID' "$PLIST" 2>/dev/null || true)"
BUNDLE_ID="$($PLISTBUDDY -c 'Print :BUNDLE_ID' "$PLIST" 2>/dev/null || true)"
GOOGLE_APP_ID="$($PLISTBUDDY -c 'Print :GOOGLE_APP_ID' "$PLIST" 2>/dev/null || true)"

if [[ -z "$REVERSED_CLIENT_ID" || -z "$GOOGLE_APP_ID" ]]; then
  echo "ERROR: GoogleService-Info.plist is not a valid Firebase iOS config."
  exit 21
fi

if [[ "$BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ]]; then
  echo "ERROR: Firebase plist bundle ID is '$BUNDLE_ID'."
  echo "Expected: '$EXPECTED_BUNDLE_ID'"
  exit 22
fi

cat > "$OUT" <<CFG
// Generated automatically. Do not edit.
GOOGLE_REVERSED_CLIENT_ID = $REVERSED_CLIENT_ID
CFG

echo "Firebase iOS config OK: $BUNDLE_ID"
