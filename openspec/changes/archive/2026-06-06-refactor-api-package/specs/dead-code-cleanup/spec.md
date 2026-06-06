## ADDED Requirements

### Requirement: All deleted artifacts have zero external references

The refactor SHALL only delete files, bricks, scripts, and build targets that are confirmed to have **zero** external references in the monorepo. A reference is defined as any import, instantiation, type annotation, configuration key, or command invocation originating from outside the artifact's own definition.

#### Scenario: Verified zero-import files in api package
- **WHEN** grepping the `packages/` tree for imports of `api_constants.dart`, `api_endpoints.dart`, `http_constant.dart`, `http_event_bus.dart`, `app_logger.dart`, or `token_supplier.dart`
- **THEN** the only matches are within the api package's own files or in `api.dart` barrel re-exports

#### Scenario: Verified zero-import files in component_library
- **WHEN** grepping the `packages/` tree for imports of `packages/infrastructure/component_library/lib/src/constants/api_constants.dart`
- **THEN** the only matches are the file itself and its barrel export

#### Scenario: Verified zero-call api classes
- **WHEN** grepping `\bAuthApi\b`, `\bSessionApi\b`, `\bVehicleApi\b` in `packages/**/*.dart` excluding the api package's own directory
- **THEN** the match count is 0

#### Scenario: Verified zero-call mason bricks
- **WHEN** grepping `bricks/api_gen` and `bricks/api_gen_spec` in `makefile`, `melos.yaml`, `pubspec.yaml`, `analysis_options.yaml`, and `.github/workflows/*.yml`
- **THEN** `mason.yaml` is the only place registering these bricks, and `scripts/gen_api.dart` is the only file invoking the gen_api logic

#### Scenario: Verified zero-call gen_api.dart
- **WHEN** grepping `gen_api.dart` in `melos.yaml`, `pubspec.yaml`, `analysis_options.yaml`, and `.github/workflows/*.yml`
- **THEN** only `makefile` matches (in `gen-api` / `gen-all-apis` / `refresh-api` targets, all of which are also deleted)

### Requirement: All deletion points are enumerated with their evidence

The refactor SHALL provide a concrete deletion list with file path, line count, and grep evidence for each item, before any deletion occurs.

#### Scenario: File-by-file deletion manifest
- **WHEN** executing the cleanup
- **THEN** exactly the following 19 items are removed (with their confirming grep evidence captured in `tasks.md`):
  - `packages/infrastructure/api/lib/src/constants/api_constants.dart` (10 lines, 0 external import)
  - `packages/infrastructure/api/lib/src/endpoints/api_endpoints.dart` (82 lines, 0 external import)
  - `packages/infrastructure/api/lib/src/http/http_constant.dart` (53 lines, 0 external import)
  - `packages/infrastructure/api/lib/src/http/http_event_bus.dart` (37 lines, 0 external import)
  - `packages/infrastructure/api/lib/src/http/app_logger.dart` (63 lines, 0 external import)
  - `packages/infrastructure/api/lib/src/http/token_supplier.dart` (15 lines, 0 external import)
  - `packages/infrastructure/api/lib/src/tracking/README.md` (describes nonexistent `RequestTracker`)
  - `packages/infrastructure/api/lib/src/error/README.md` (orphaned doc)
  - `packages/infrastructure/component_library/lib/src/constants/api_constants.dart` (16 lines, 0 external import)
  - `packages/infrastructure/api/lib/src/api/auth_api.dart` + `.g.dart` (26 + generated lines, 0 external call)
  - `packages/infrastructure/api/lib/src/api/session_api.dart` + `.g.dart` (19 + generated lines, 0 external call)
  - `packages/infrastructure/api/lib/src/api/vehicle_api.dart` + `.g.dart` (21 + generated lines, 0 external call)
  - `packages/infrastructure/api/spec/auth.json` (55 lines, no consumer)
  - `packages/infrastructure/api/spec/session.json` (32 lines, no consumer)
  - `packages/infrastructure/api/spec/vehicle.json` (33 lines, no consumer)
  - `bricks/api_gen/` (entire directory)
  - `bricks/api_gen_spec/` (entire directory)
  - `scripts/gen_api.dart` (232 lines)
  - `makefile` entries: `gen-api`, `gen-all-apis`, `refresh-api` targets + their `gen-api` reference comments

#### Scenario: mason.yaml + pubspec.yaml cleanup
- **WHEN** removing the 2 dead bricks
- **THEN** the 2 corresponding `bricks:` entries in `mason.yaml` are removed AND `mason:` dependency in `pubspec.yaml` (root) is removed if and only if it is exclusively used by these 2 bricks

### Requirement: No public API or DI assembly changes

The refactor SHALL NOT modify any class, function, type signature, or DI registration that is referenced by other packages. All `lib/api.dart` barrel exports for files that remain SHALL be preserved.

#### Scenario: Surviving barrel re-exports
- **WHEN** the 3 zero-call api files are deleted
- **THEN** the surviving `lib/api.dart` still exports `home_api.dart`, `detail_api.dart`, `user_api.dart`, and all 8 surviving DTOs

#### Scenario: Surviving brick registration
- **WHEN** `bricks/api_gen` and `bricks/api_gen_spec` are removed
- **THEN** the 4 surviving bricks (`feature`, `api`, `model`, `hive_model`) remain registered in `mason.yaml` and are unaffected

### Requirement: Verification commands pass after deletion

After all deletions, the refactor SHALL pass the project's standard verification commands without modification.

#### Scenario: flutter analyze
- **WHEN** running `melos analyze` post-deletion
- **THEN** zero errors and zero new warnings introduced by the deletion

#### Scenario: pre-commit hooks
- **WHEN** running `.githooks/pre-commit` post-deletion
- **THEN** all 4 steps (check_deps.sh, check_l10n.sh, flutter analyze, melos test:affected) pass

#### Scenario: melos test
- **WHEN** running `melos test:affected` post-deletion
- **THEN** all affected package tests pass with the same count as before deletion (no test regression)
