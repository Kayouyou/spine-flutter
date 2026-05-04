## ADDED Requirements

### Requirement: CI generates coverage report
GitHub Actions SHALL run tests with coverage flag and generate lcov.info file.

#### Scenario: Coverage generation in CI
- **WHEN** CI workflow runs `flutter test --coverage`
- **THEN** coverage/lcov.info is generated

### Requirement: Coverage uploaded to codecov
Coverage report SHALL be uploaded to codecov.io for visualization.

#### Scenario: Codecov upload
- **WHEN** coverage workflow completes
- **THEN** codecov/codecov-action uploads lcov.info

#### Scenario: Coverage badge visible
- **WHEN** codecov processes report
- **THEN** README can display coverage percentage badge

### Requirement: Coverage workflow separate from main CI
Coverage report SHALL run in dedicated workflow to avoid slowing main pipeline.

#### Scenario: Separate workflow file
- **WHEN** coverage is configured
- **THEN** `.github/workflows/coverage.yml` exists independently from `ci.yml`

#### Scenario: Coverage runs on PR
- **WHEN** PR is created or updated
- **THEN** coverage workflow runs and reports to codecov

### Requirement: Coverage report includes all test layers
Coverage SHALL include unit, bloc, and widget tests.

#### Scenario: Full coverage scope
- **WHEN** coverage runs
- **THEN** test/unit/, test/bloc/, test/widget/ are all executed