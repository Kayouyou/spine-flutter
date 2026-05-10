# T0.3 Learnings

## Task: Include root app in melos.yaml packages

### What worked
- Adding `.` to melos.yaml `packages:` list is the standard way to include the root package
- After the change, `melos list` shows `my_app` (the root package) alongside sub-packages
- CI analyze job already had `flutter analyze` at root level (independent of melos), so no CI change needed
- CI test job uses `melos test` which automatically picks up the root app now

### Pre-existing issues found
- `melos exec --since=origin/main` (used in `test:affected` script) is an invalid option for current melos version
- Should be `--diff=origin/main` instead
- This is a pre-existing bug that blocks pre-commit hook but is unrelated to this task

### Files changed
- `melos.yaml`: Added `- .` as first entry in packages list
