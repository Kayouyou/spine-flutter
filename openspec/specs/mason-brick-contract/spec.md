# mason-brick-contract Specification

## Purpose
TBD - created by archiving change refactor-api-package. Update Purpose after archive.
## Requirements
### Requirement: Generated Repository implementation must implement a domain interface

The brick SHALL generate `{{name}}_repository_impl.dart` such that the class declaration includes `implements I{{name.pascalCase()}}Repository`. The domain interface SHALL be declared in `package:domain/domain.dart` (or imported via the user's `I{{name.pascalCase()}}Repository` import), and the brick SHALL require the user to provide the interface name as a new brick variable.

#### Scenario: Brick variable addition
- **WHEN** the brick.yaml is updated
- **THEN** a new required variable `domainInterface` is added:
  ```yaml
  domainInterface:
    type: string
    description: 完整的 domain 接口名（含 I 前缀，如 IOrderRepository）
    prompt: 对应的 domain 接口名是什么？
  ```
- **AND** no default value is provided (the variable is required, and the brick will fail fast if the user leaves it blank)

#### Scenario: Generated class declaration
- **WHEN** the user runs `mason make api --name orders --domainInterface IOrderRepository` (or the equivalent `make create-api` invocation)
- **THEN** `__brick__/lib/src/repository/{{name}}_repository_impl.dart` line 5 produces:
  ```dart
  class {{name.pascalCase()}}RepositoryImpl implements I{{name.pascalCase()}}Repository {
  ```
  (using `{{name}}` = `orders` → class is `OrdersRepositoryImpl implements IOrdersRepository`)

#### Scenario: Method signatures match the interface
- **WHEN** the generated class is compiled
- **THEN** every method declared in `I{{name.pascalCase()}}Repository` is implemented in `{{name.pascalCase()}}RepositoryImpl` with identical signature (name, parameters, return type). If the interface defines 5 methods, the impl defines exactly those 5 (no extra `getList` / `getById` / `create` / `update` / `delete` defaults).

#### Scenario: Compile-time enforcement
- **WHEN** the generated package's `pubspec.yaml` declares `domain: path: ../../domain` (line 15-16 of current `__brick__/pubspec.yaml`)
- **THEN** the `package:domain/domain.dart` import resolves to the user's domain interface, and the compiler rejects any `implements` mismatch (e.g., missing methods, wrong signatures)

### Requirement: Generated Repository must use the standard error mapping helper

The brick SHALL replace the 4 occurrences of `NetworkException(e.toString())` (currently at lines 16, 25, 35, 44 of `{{name}}_repository_impl.dart`) with calls to the existing `toDomainException(e)` helper from `package:api/api.dart`.

#### Scenario: Error mapping replacement
- **WHEN** the brick template is updated
- **THEN** the 4 catch blocks produce code equivalent to:
  ```dart
  } on DioException catch (e) {
    return Result.failure(toDomainException(e));
  } catch (e) {
    return Result.failure(UnknownException(e.toString()));
  }
  ```
- **AND** `toDomainException` is imported from `package:api/api.dart` at the top of the file (the existing `import 'package:domain/domain.dart';` on line 1 is preserved)

#### Scenario: Catch block scoping
- **WHEN** the catch block is split into `on DioException catch (e)` + `catch (e)`
- **THEN** Dio errors are mapped via the project's standard `toDomainException` (which preserves status code, request path, and original error type), and non-Dio errors fall through to `UnknownException` with the toString message

#### Scenario: Consistency with hand-written repositories
- **WHEN** comparing the generated `{{name}}_repository_impl.dart` to the existing `packages/features/feature_home/lib/src/repository/home_repository_impl.dart`
- **THEN** both files use the same error-mapping pattern (no `e.toString()` shortcut in the generated file)

### Requirement: Generated DI setup must register the domain interface as the registered key

The brick SHALL change `__brick__/lib/src/di/setup.dart` line 12-14 from registering `{{name.pascalCase()}}RepositoryImpl` directly to registering `I{{name.pascalCase()}}Repository` with the impl as the factory.

#### Scenario: DI registration update
- **WHEN** the brick template is updated
- **THEN** `setup.dart` produces code equivalent to:
  ```dart
  sl.registerFactory<I{{name.pascalCase()}}Repository>(
    () => {{name.pascalCase()}}RepositoryImpl(sl<{{name.pascalCase()}}Api>()),
  );
  ```
- **AND** the old line `sl.registerFactory<{{name.pascalCase()}}RepositoryImpl>(...)` is removed

#### Scenario: Consumers resolve the interface, not the impl
- **WHEN** a feature package calls `sl<I{{name.pascalCase()}}Repository>()` after running `setupApi{{name.pascalCase()}}(sl, baseUrl)`
- **THEN** the call resolves to the same `{{name.pascalCase()}}RepositoryImpl` instance, satisfying the AGENTS.md R3 (infrastructure can depend on services, services depend on domain interfaces, not impls)

### Requirement: Brick variable validation rejects empty `domainInterface`

The brick SHALL validate the new `domainInterface` variable at generation time. If the user provides an empty string, mason SHALL abort the generation with a clear error message.

#### Scenario: Empty domainInterface rejection
- **WHEN** the user runs the brick with `--domainInterface ""` (or omits it in interactive mode and presses enter)
- **THEN** mason aborts with: `"domainInterface is required (e.g. IOrderRepository)"` and no files are written to disk

#### Scenario: Valid domainInterface acceptance
- **WHEN** the user provides `--domainInterface IOrderRepository` matching an existing interface in `package:domain`
- **THEN** generation succeeds and the `implements` clause compiles

### Requirement: Existing successful brick runs still work after template update

The refactor SHALL NOT break previously generated packages. Specifically, the `feature_home`, `feature_detail`, and `feature_auth` packages in the scaffold SHALL continue to compile and function after the brick is updated.

#### Scenario: Backward compatibility for already-generated repos
- **WHEN** the brick is updated to require `implements` and force `toDomainException`
- **THEN** the 3 existing feature packages (`feature_home`, `feature_detail`, `feature_auth`) still compile, because they are regenerated by `make scaffold-check` only if needed, not automatically

#### Scenario: Documentation note
- **WHEN** the brick README is updated (new file `bricks/api/README.md` to be created if absent)
- **THEN** it documents the new `domainInterface` variable and warns that running the brick against an existing module will require adding the `implements` clause to the existing impl file (because mason overwrites, not merges)

### Requirement: Brick template's pubspec.yaml gets a domain import if needed

The brick SHALL ensure that the generated package's `pubspec.yaml` continues to depend on `package:domain` (already present at line 15-16 of current `__brick__/pubspec.yaml`), so the new `implements` clause resolves.

#### Scenario: pubspec dependency preserved
- **WHEN** the brick template is updated
- **THEN** the generated `pubspec.yaml` retains:
  ```yaml
  dependencies:
    domain:
      path: ../../domain
  ```
  (unchanged from current line 15-16)

