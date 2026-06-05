#!/bin/bash
# Check that feature packages don't depend on the root app
set -euo pipefail

cd "$(dirname "$0")/.."

if grep -rq "package:spine_flutter" packages/features/; then
  echo "❌ Feature packages must not import spine_flutter"
  grep -r "package:spine_flutter" packages/features/
  exit 1
fi
echo "✅ No forbidden spine_flutter imports in feature packages"
exit 0
