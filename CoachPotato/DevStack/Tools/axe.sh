#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT="$ROOT_DIR/Coach Potato/Coach Potato.xcodeproj"
SCHEME="Coach Potato UI Tests"   # change later if you make a dedicated UITest scheme
DESTINATION_ID="64DF4DC0-45D5-4D60-9848-88F4AFF633E4"
DESTINATION="id=$DESTINATION_ID"

echo ">>> [axe] Running accessibility test suite (placeholder)"
echo ">>> [axe] Using project: $PROJECT"
echo ">>> [axe] Using destination: $DESTINATION"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  test
