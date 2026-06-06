#!/bin/bash
# Check 4 dependency direction rules (R1-R4)
set -euo pipefail

cd "$(dirname "$0")/.."

FAILED=0

# R1: feature packages must not import spine_flutter
if grep -rq "package:spine_flutter" packages/features/ --include="*.dart"; then
  echo "❌ [R1] Feature packages must not import spine_flutter"
  grep -rn "package:spine_flutter" packages/features/ --include="*.dart"
  FAILED=1
else
  echo "✅ [R1] No forbidden spine_flutter imports in feature packages"
fi

# R3: infrastructure must not depend on services
if grep -rE "^import 'package:[a-z_]+/services/" packages/infrastructure/ --include="*.dart" 2>/dev/null; then
  echo "❌ [R3] Infrastructure packages must not depend on services"
  grep -rnE "^import 'package:[a-z_]+/services/" packages/infrastructure/ --include="*.dart"
  FAILED=1
else
  echo "✅ [R3] Infrastructure packages have no services dependencies"
fi

# R4: services must not depend on features
if grep -rE "^import 'package:feature_[a-z_]+/" packages/services/ --include="*.dart" 2>/dev/null; then
  echo "❌ [R4] Services packages must not depend on features"
  grep -rnE "^import 'package:feature_[a-z_]+/" packages/services/ --include="*.dart"
  FAILED=1
else
  echo "✅ [R4] Services packages have no feature dependencies"
fi

exit $FAILED
