#!/bin/bash
set -euo pipefail

echo "▸ scaffold contract tests"
flutter test test/unit/scaffold/feature_template_contract_test.dart
flutter test test/unit/scaffold/root_contract_test.dart

echo "▸ workspace validate"
melos run validate

echo "✅ scaffold health check passed"
