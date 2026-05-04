## 1. Infrastructure Setup

- [ ] 1.1 Create performance package structure at `packages/services/performance/`
- [ ] 1.2 Create feature_settings package structure at `packages/features/feature_settings/`
- [ ] 1.3 Add performance and feature_settings dependencies to root pubspec.yaml
- [ ] 1.4 Run `make get` to install new package dependencies

## 2. Auth Route Guard

- [ ] 2.1 Create `AuthGuard` class in `routing/lib/src/guards/auth_guard.dart`
- [ ] 2.2 Implement `AuthGuard.check(state, auth)` redirect logic
- [ ] 2.3 Add `enableAuthGuard` parameter to `getRouter()` function
- [ ] 2.4 Register AuthGuard in `AppRouter` with DI `sl<AuthManager>()`
- [ ] 2.5 Add `/login?redirect=...` route handling
- [ ] 2.6 Test guard with mock AuthManager states

## 3. Domain Test Suite

- [ ] 3.1 Create test directory structure `test/unit/domain/models/`, `test/unit/domain/exceptions/`, `test/unit/domain/usecases/`
- [ ] 3.2 Implement `user_test.dart` — fromJson/toJson, boundary values, equality
- [ ] 3.3 Implement `domain_exception_test.dart` — sealed class exhaustive matching
- [ ] 3.4 Implement `network_exception_test.dart` — construction, statusCode
- [ ] 3.5 Implement `validation_exception_test.dart` — fieldErrors map
- [ ] 3.6 Implement `get_user_usecase_test.dart` — mock UserRepository, execute
- [ ] 3.7 Verify domain coverage reaches 100% with `flutter test --coverage`

## 4. Theme Switching

- [ ] 4.1 Create `ThemeCubit` in `packages/services/locale/lib/src/cubit/theme_cubit.dart`
- [ ] 4.2 Implement `ThemeState` with ThemeMode enum
- [ ] 4.3 Add `setTheme(ThemeMode)` method with KeyValueStorage persistence
- [ ] 4.4 Register ThemeCubit as Singleton in `lib/core/di/setup.dart`
- [ ] 4.5 Wrap MyApp with BlocProvider for ThemeCubit
- [ ] 4.6 Update MaterialApp to use dynamic `theme` from ThemeState
- [ ] 4.7 Test theme persistence across app restart

## 5. Settings Page

- [ ] 5.1 Create SettingsCubit with theme and language state
- [ ] 5.2 Implement SettingsRepository for preference persistence
- [ ] 5.3 Build SettingsPage UI with theme toggle switch
- [ ] 5.4 Add language dropdown selector
- [ ] 5.5 Implement DI setup `setupFeatureSettings(sl)`
- [ ] 5.6 Register `/settings` route in routing package
- [ ] 5.7 Add settings icon to home page app bar

## 6. Storage Migration Framework

- [ ] 6.1 Create `MigrationFramework` class in `key_value_storage/lib/src/migration/`
- [ ] 6.2 Implement `registerMigration(version, fn)` registry
- [ ] 6.3 Implement `runMigrations()` with version detection
- [ ] 6.4 Add `_version` tracking to Hive box
- [ ] 6.5 Create backup mechanism before migration
- [ ] 6.6 Register migrations in `launcher.dart` before SDK init
- [ ] 6.7 Write migration unit tests with mock Hive box

## 7. FPS Monitoring

- [ ] 7.1 Create `FpsMonitor` class in `performance/lib/src/monitor/fps_monitor.dart`
- [ ] 7.2 Implement `start()` with `addTimingsCallback`
- [ ] 7.3 Implement frame time tracking and FPS calculation
- [ ] 7.4 Add `onFpsDrop` callback with threshold detection
- [ ] 7.5 Implement `report()` with avgFps, minFps, dropCount
- [ ] 7.6 Register FpsMonitor as optional Singleton
- [ ] 7.7 Add environment-based activation in launcher (debug/staging only)
- [ ] 7.8 Write FpsMonitor unit tests

## 8. CI Coverage Report

- [ ] 8.1 Create `.github/workflows/coverage.yml` workflow file
- [ ] 8.2 Configure `flutter test --coverage` step
- [ ] 8.3 Add codecov/codecov-action for upload
- [ ] 8.4 Set workflow triggers on PR and push to main
- [ ] 8.5 Add codecov badge to README.md
- [ ] 8.6 Test workflow on sample PR

## 9. Integration & Verification

- [ ] 9.1 Update `launcher.dart` to register all new services
- [ ] 9.2 Update `setup.dart` DI registration order
- [ ] 9.3 Run full test suite: `flutter test`
- [ ] 9.4 Run lint: `flutter analyze`
- [ ] 9.5 Verify app builds: `flutter build apk --debug`
- [ ] 9.6 Manual QA: theme switch, settings page, route guard
- [ ] 9.7 Update README with new feature documentation