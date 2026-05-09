# Scaffold Enhancement - Consolidated Plan

> Generated at 2026-05-09 by Atlas
> Combines 5 plans: result-pattern, retrofit-api, cli-mason-bricks, hive-database, di-polish

## Dependency Groups

**Group A (Foundation)** - result-pattern (P1-1)
- Must run first: provides Result<T> used by cli-mason-bricks

**Group B (Infrastructure)** - retrofit-api (P0-2) + hive-database + di-polish
- Independent of each other, can run after Group A starts

**Group C (Templates)** - cli-mason-bricks
- Depends on Group A (result-pattern must complete first)
- Safe to run parallel with Group B

## Execution Order (sequential per subagent-driven-development skill)

**Phase 1:** result-pattern Tasks 1-2 (Result core + Future extension)
**Phase 2:** result-pattern Tasks 3-6 (repo interfaces, repos, cubits, bricks)
**Phase 3:** retrofit-api Tasks 1-13 (Retrofit setup + API interfaces + migration)
**Phase 4:** hive-database Tasks 1-4 (Hive init + migration + typeId + verify)
**Phase 5:** cli-mason-bricks Tasks 1-20 (feature brick + new bricks + makefile)
**Phase 6:** di-polish Tasks 1-9 (injectable + Alice + ThemeExtension + Test Shell + verify)

## TODOs

### Phase 1: Result Pattern Foundation

#### Plan 1.1: Create Result<T, E> Core Pattern
- [ ] **Plan 1.1**: Create Result<T, E> sealed class in `packages/domain/lib/src/result.dart`, tests in `packages/domain/test/result_test.dart`, export in `packages/domain/lib/domain.dart`. Result<T, E> with Success/Failure subclasses, when(), map(), mapError(), getOrElse(), dataOrThrow. Tests for all methods. Run flutter test. Commit.

#### Plan 1.2: Create Future.toResult() Extension
- [ ] **Plan 1.2**: Create `packages/infrastructure/api/lib/src/error/future_result.dart` with FutureResult<T> extension (toResult(), toResultWith()) and ResponseResult extension (toJsonResult()). Catches DioException → DomainException. Verify analyze. Commit.

#### Plan 1.3: Update Repository Interfaces
- [ ] **Plan 1.3**: Update 4 domain repository interfaces to return Result: home_repository.dart (getHomeData, refreshHomeData → Result<Map, DomainException>), detail_repository.dart (getDetailData → Result), auth_repository.dart (login/register/logout → Result), user_repository.dart (getCurrentUser/updateProfile → Result with ProfileData). Verify analyze. Commit.

#### Plan 1.4: Update Repository Implementations
- [ ] **Plan 1.4**: Update HomeRepositoryImpl, DetailRepositoryImpl, AuthRepositoryImpl to return Result with try-catch pattern → Success/Failure. Check files exist, create if needed. Verify analyze. Commit.

#### Plan 1.5: Update Cubits to Use Result.when()
- [ ] **Plan 1.5**: Update HomeCubit, DetailCubit, LoginCubit, AuthCubit, TestMasonCubit to use result.when(success:, failure:) instead of try-catch. Verify analyze. Commit.

#### Plan 1.6: Update Mason Brick Templates for Result
- [ ] **Plan 1.6**: Update all feature brick templates (cubit, repository, repository_impl, test) to use Result pattern. Run melos analyze. Commit.

### Phase 2: Retrofit API Integration (P0-2)

#### Plan 2.1: Add Retrofit Dependencies
- [ ] **Plan 2.1**: Add retrofit ^4.1.0, retrofit_generator ^8.1.0, build_runner, json_serializable to `packages/infrastructure/api/pubspec.yaml`. Run `make get` to install. Commit.

#### Plan 2.2: Create API Constants
- [ ] **Plan 2.2**: Create `packages/infrastructure/api/lib/src/constants/api_constants.dart` with ApiConstants.tokenRenewal = '/User/Token/Renewal'. Commit.

#### Plan 2.3: Create Home API Interface
- [ ] **Plan 2.3**: Create `packages/infrastructure/api/lib/src/api/home_api.dart` with @RestApi(baseUrl: '') and factory HomeApi(Dio dio) = _HomeApi, getHomeData() @GET('/home/data'). Commit.

#### Plan 2.4: Create Detail API Interface
- [ ] **Plan 2.4**: Create `packages/infrastructure/api/lib/src/api/detail_api.dart` with getDetailData(@Path id). Commit.

#### Plan 2.5: Create Auth API Interface
- [ ] **Plan 2.5**: Create `packages/infrastructure/api/lib/src/api/auth_api.dart` with login, register, getProfile, forgotPassword. Commit.

#### Plan 2.6: Create Session API Interface
- [ ] **Plan 2.6**: Create `packages/infrastructure/api/lib/src/api/session_api.dart` with signIn, signOut. Commit.

#### Plan 2.7: Create Vehicle API Interface
- [ ] **Plan 2.7**: Create `packages/infrastructure/api/lib/src/api/vehicle_api.dart` with getVehicleList, getVehicleDetail, getVehicleRanking. Commit.

#### Plan 2.8: Run Retrofit Code Generation
- [ ] **Plan 2.8**: Run build_runner in api package. Verify .g.dart files generated. Commit.

#### Plan 2.9: Update API Export File
- [ ] **Plan 2.9**: Add exports for new API interfaces and constants to `packages/infrastructure/api/lib/api.dart`. Commit.

#### Plan 2.10: Deprecate ApiEndpoints Class
- [ ] **Plan 2.10**: Add @Deprecated to ApiEndpoints class in api_endpoints.dart, keep ApiBase.tokenRenewal with @Deprecated pointing to ApiConstants. Commit.

#### Plan 2.11: Migrate HomeRepositoryImpl
- [ ] **Plan 2.11**: Update HomeRepositoryImpl to use HomeApi(_dio) instead of direct Dio.get(ApiEndpoints...). Commit.

#### Plan 2.12: Migrate DetailRepositoryImpl
- [ ] **Plan 2.12**: Update DetailRepositoryImpl to use DetailApi(_dio). Commit.

#### Plan 2.13: Migrate AuthRepositoryImpl
- [ ] **Plan 2.13**: Update AuthRepositoryImpl to use AuthApi(_dio), preserve hardcoded paths with TODO comments. Run make lint + make test. Commit.

### Phase 3: Hive Database Enhancement

#### Plan 3.1: Unify Hive.init in SDKInitializer
- [ ] **Plan 3.1**: Modify SDKInitializer.initPlugins() to call Hive.initFlutter(). Remove Hive.init() from KeyValueStorage._openBox(). Remove unused imports. Verify analyze. Commit.

#### Plan 3.2: Create Migration Framework
- [ ] **Plan 3.2**: Create Migration abstract class, MigrationRunner, SchemaVersionBox, export module, migration_test.dart with chain and clearOnMismatch strategy tests. Tests must pass. Commit.

#### Plan 3.3: Create TypeId Registry
- [ ] **Plan 3.3**: Create `register.yaml` at project root with nextTypeId: 1 and typeIds history. Commit.

#### Plan 3.4: Verify Full Integration
- [ ] **Plan 3.4**: Verify SDKInitializer startup order, run flutter analyze, run key_value_storage tests. Commit.

### Phase 4: CLI Tools + Mason Bricks Enhancement

#### Plan 4.1-4.6: Modify Feature Brick for Result Pattern
- [ ] **Plan 4.1**: Modify Feature Brick repository interface to return Result<Map>. Commit.
- [ ] **Plan 4.2**: Modify Feature Brick repository impl to use .toResult() pattern. Commit.
- [ ] **Plan 4.3**: Modify Feature Brick cubit to use Result.when(). Commit.
- [ ] **Plan 4.4**: Confirm Feature Brick state compatible with Result (no changes needed).
- [ ] **Plan 4.5**: Add route registration hint comments to Feature Brick page template. Commit.
- [ ] **Plan 4.6**: Update Feature Brick test for Result pattern (Success/Failure mock). Commit.

#### Plan 4.7-4.11: Create API Brick
- [ ] **Plan 4.7**: Create API brick directory + brick.yaml with name/baseUrl vars. Commit.
- [ ] **Plan 4.8**: Create API brick pubspec.yaml with retrofit/freezed. Commit.
- [ ] **Plan 4.9**: Create API brick Retrofit interface template. Commit.
- [ ] **Plan 4.10**: Create API brick RepositoryImpl template with Result pattern. Commit.
- [ ] **Plan 4.11**: Create API brick DI setup template. Commit.

#### Plan 4.12-4.13: Create Model Brick
- [ ] **Plan 4.12**: Create Model brick directory + brick.yaml. Commit.
- [ ] **Plan 4.13**: Create Model brick @freezed model template. Commit.

#### Plan 4.14-4.16: Create HiveModel Brick
- [ ] **Plan 4.14**: Create HiveModel brick directory + brick.yaml with name/typeId vars. Commit.
- [ ] **Plan 4.15**: Create HiveModel brick @HiveType model template. Commit.
- [ ] **Plan 4.16**: Create HiveModel brick Migration skeleton template. Commit.

#### Plan 4.17-4.19: Register Bricks + Make Commands + Verify
- [ ] **Plan 4.17**: Update mason.yaml to register all 4 bricks. Run mason get. Commit.
- [ ] **Plan 4.18**: Update makefile with create-api, create-model, create-hive-model commands. Verify syntax. Commit.
- [ ] **Plan 4.19**: Full validation - mason list, test generate all bricks, melos analyze. Commit.

### Phase 5: DI Polish + ThemeExtension + Test Shell

#### Plan 5.1: Add injectable + alice Dependencies
- [ ] **Plan 5.1**: Add injectable ^2.5.0, injectable_generator ^2.6.3, alice ^3.9.0 to pubspec.yaml. Run flutter pub get. Commit.

#### Plan 5.2: Create Injectable Configuration
- [ ] **Plan 5.2**: Create lib/core/di/injectable.dart with @InjectableInit and GetIt instance. Create injectable.config.dart placeholder. Commit.

#### Plan 5.3: Update Existing DI Files
- [ ] **Plan 5.3**: Update locator.dart with documentation, update setup.dart to call getIt.init() before manual registrations. Commit.

#### Plan 5.4: Add @injectable Annotations
- [ ] **Plan 5.4**: Add @injectable/@lazySingleton annotations to service and feature setup.dart files and cubit/repository classes. Run build_runner to generate config files. Commit.

#### Plan 5.5: Integrate Alice HTTP Inspector
- [ ] **Plan 5.5**: Create Alice instance in setup.dart (debug only), add Alice interceptor to DioFactory, register Alice navigatorKey in app.dart. Verify analyze. Commit.

#### Plan 5.6: Add ThemeExtension + UI Components
- [ ] **Plan 5.6**: Create AppColors ThemeExtension (lib/src/theme/app_colors.dart), update AppTheme to use extensions, add SearchBar/FilterChip/BottomSheet components to component_library, export in barrel. Commit.

#### Plan 5.7: Create Widget Test Shell
- [ ] **Plan 5.7**: Create test/helpers/test_app_wrapper.dart with TestAppWrapper, testWidget(), WidgetTesterExtension.pumpApp(). Create mock_helpers.dart. Update brick test template. Commit.

#### Plan 5.8: Final Verification
- [ ] **Plan 5.8**: Run flutter analyze on all modified areas, run flutter test, verify injectable code generation, verify ThemeExtension, verify Test Shell. Commit.

## Final Verification Wave

### F1: Spec Compliance Review
- [ ] **F1**: Review ALL plan tasks against original specs. Verify every checkbox item was completed. No missing requirements, no extra work beyond spec.

### F2: Code Quality Review  
- [ ] **F2**: Full code quality review across all changes. Check for code smells, type safety, test coverage, naming consistency, no dead code, proper error handling.

### F3: Build + Test Verification
- [ ] **F3**: Run `melos run validate` (or equivalent), `flutter analyze`, `flutter test` across the entire monorepo. All must pass.

### F4: Integration Check
- [ ] **F4**: Verify cross-plan integration: Result pattern works with Retrofit APIs, Hive migration framework integrates with SDKInitializer, injectable DI works alongside manual registration, Alice only active in debug mode, ThemeExtension accessible via context.colors, Test Shell wraps widget tests correctly.
