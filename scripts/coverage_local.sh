#!/bin/bash
set -e

echo "Running tests with coverage..."
fvm flutter test --coverage

echo "Generating HTML report..."
if ! command -v lcov &> /dev/null; then
    echo "lcov not found. Install with:"
    echo "  macOS: brew install lcov"
    echo "  Linux: sudo apt-get install lcov"
    exit 1
fi

# Filter to relevant files only
lcov --remove coverage/lcov.info \
  '*/test/*' \
  '*/.pub-cache/*' \
  '*/build/*' \
  -o coverage/lcov_filtered.info

# Generate HTML
genhtml coverage/lcov_filtered.info -o coverage/html --title "My App Coverage"

echo "Opening coverage report..."
open coverage/html/index.html || xdg-open coverage/html/index.html

echo "Done! Report at coverage/html/index.html"