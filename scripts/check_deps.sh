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

# R2: domain must remain pure Dart (no framework / infrastructure deps)
# Domain is the innermost layer — should not import flutter, dio, retrofit,
# or any UI/IO/infra package. Allowed: dart:* and pure pub.dev packages.
#
# (L-7 扩展: 之前只检查 flutter, 现覆盖更多非纯 dart 包)
if grep -rqE "^import 'package:(flutter|dio|retrofit|alice|sentry_flutter|hive|hive_flutter|hydrated_bloc|shared_preferences|path_provider|get_it|flutter_bloc)" packages/domain/ --include="*.dart"; then
  echo "❌ [R2] Domain packages must not import framework / infrastructure"
  grep -rnE "^import 'package:(flutter|dio|retrofit|alice|sentry_flutter|hive|hive_flutter|hydrated_bloc|shared_preferences|path_provider|get_it|flutter_bloc)" packages/domain/ --include="*.dart"
  FAILED=1
else
  echo "✅ [R2] Domain packages have no framework / infrastructure imports"
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
