#!/bin/bash
# Check that feature packages don't depend on the root app
set -euo pipefail

cd "$(dirname "$0")/.."

if grep -rq "package:my_app" packages/features/; then
  echo "❌ Feature packages must not import my_app"
  grep -r "package:my_app" packages/features/
  exit 1
fi
echo "✅ No forbidden my_app imports in feature packages"
exit 0
