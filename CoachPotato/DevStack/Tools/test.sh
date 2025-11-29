#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="$ROOT_DIR/Coach Potato/Coach Potato.xcodeproj"
SCHEME="Coach Potato"
DESTINATION_ID="64DF4DC0-45D5-4D60-9848-88F4AFF633E4"
DESTINATION="id=$DESTINATION_ID"

echo ">>> [test] Testing scheme: $SCHEME"
echo ">>> [test] Using project: $PROJECT"
echo ">>> [test] Using destination: $DESTINATION"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  test
