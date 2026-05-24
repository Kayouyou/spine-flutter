#!/usr/bin/env python3
"""Insert a feature path dependency into root pubspec.yaml.

Usage:
    python3 scripts/add_feature_dependency.py <feature_name>
"""

from pathlib import Path
import sys

MARKER = "  # <<<< FEATURE_DEPENDENCIES >>>>"


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python3 scripts/add_feature_dependency.py <feature_name>", file=sys.stderr)
        return 1

    feature_name = sys.argv[1].strip()
    if not feature_name:
        print("Feature name cannot be empty", file=sys.stderr)
        return 1

    pubspec_path = Path("pubspec.yaml")
    content = pubspec_path.read_text(encoding="utf-8")

    if MARKER not in content:
        print(f"Error: marker '{MARKER}' not found in pubspec.yaml", file=sys.stderr)
        return 1

    insertion = f"  feature_{feature_name}:\n    path: packages/features/feature_{feature_name}"
    new_content = content.replace(MARKER, f"{insertion}\n{MARKER}")

    pubspec_path.write_text(new_content, encoding="utf-8")
    print(f"Added feature_{feature_name} dependency to pubspec.yaml")
    return 0


if __name__ == "__main__":
    sys.exit(main())
