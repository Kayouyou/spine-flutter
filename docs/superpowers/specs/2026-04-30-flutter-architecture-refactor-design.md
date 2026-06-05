# Flutter架构重构设计文档

## 目标

建立开箱可用的Flutter骨架项目，团队统一起点，新项目快速启动。

---

## Phase 1: 基础设施

### 1.1 目录重构

**新结构：**

```
lib/
  main.dart              # 入口（保留）
  app.dart               # App配置（保留）
  config.dart            # 配置（保留）
  core/
    auth/
      manager.dart       # AuthManager
      README.md
    di/
      locator.dart       # ServiceLocator（GetIt）
      setup.dart         # DI配置
      README.md
    global/
      network/           # Phase 2: NetworkCubit
      locale/            # Phase 2: LocaleCubit
    startup/
      launcher.dart      # AppLauncher
      initializer.dart   # SDK初始化
      profiler.dart      # 启动性能
      README.md
    sync/
      manager.dart       # 数据同步
      README.md
    utils/
      logger.dart        # AppLogger
      README.md
    constants/
      app_constants.dart
      api_constants.dart
      cache_constants.dart
      error_codes.dart   # Phase 2
      README.md
    widgets/
      network/           # Phase 3: NetworkBanner
      README.md
    l10n/                # Phase 2: 国际化
  features/
    home/
      repository/
        home_repository.dart
        home_repository_impl.dart
        README.md
      cubit/
        home_cubit.dart
        home_state.dart
        README.md
      ui/
        home_page.dart
        README.md
    user/
    order/
```

**文件迁移映射：**

| 现有文件 | 新位置 |
|---------|--------|
| lib/src/ui/tab_a_page.dart | lib/features/home/ui/ |
| lib/src/ui/tab_b_page.dart | lib/features/home/ui/ |
| lib/src/ui/detail_c_page.dart | lib/features/detail/ui/ |
| lib/src/repository_factory.dart | lib/core/di/locator.dart |
| lib/src/app_configurator.dart | lib/core/di/setup.dart |
| lib/src/app_starter.dart | lib/core/startup/launcher.dart |
| lib/src/auth_manager.dart | lib/core/auth/manager.dart |
| lib/src/sdk_initializer.dart | lib/core/startup/initializer.dart |
| lib/src/startup_profiler.dart | lib/core/startup/profiler.dart |
| lib/src/data_sync_manager.dart | lib/core/sync/manager.dart |

---

### 1.2 Constants管理

**文件结构：**

```
lib/core/constants/
  app_constants.dart      # 应用配置
  api_constants.dart      # API配置
  cache_constants.dart    # 缓存配置
  README.md
```

**内容示例：**

```dart
// app_constants.dart
class AppConstants {
  static const String appName = 'SpineFlutter';
  static const String version = '1.0.0';
  static const Duration defaultTimeout = Duration(seconds: 30);
}

// api_constants.dart
class APIConstants {
  static const String baseUrl = 'https://api.example.com';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}

// cache_constants.dart
class CacheConstants {
  static const Duration defaultTTL = Duration(hours: 24);
  static const int maxListSize = 100;
}
```

---

### 1.3 AppLogger

**文件位置：** `lib/core/utils/logger.dart`

```dart
enum LogLevel { debug, info, warning, error }

class AppLogger {
  final bool enableInProduction;
  final LogLevel minLevel;

  AppLogger({
    this.enableInProduction = false,
    this.minLevel = LogLevel.info,
  });

  void debug(String message) => log(LogLevel.debug, message);
  void info(String message) => log(LogLevel.info, message);
  void warning(String message) => log(LogLevel.warning, message);
  void error(String message, [dynamic error]) => log(LogLevel.error, message, error);

  void log(LogLevel level, String message, [dynamic error]) {
    if (level.index < minLevel.index) return;
    if (!enableInProduction && !kDebugMode) return;

    final timestamp = DateTime.now().toString();
    final levelStr = level.name.toUpperCase();
    final output = '[$timestamp] [$levelStr] $message';

    if (kDebugMode) {
      debugPrint(output);
      if (error != null) debugPrint(error.toString());
    }
  }
}
```

---

### 1.4 GetIt依赖注入

**文件位置：** `lib/core/di/locator.dart`

```dart
final sl = GetIt.instance;

void setupDependencies() {
  // Core
  sl.registerSingleton<AppLogger>(AppLogger());
  sl.registerSingleton<HttpManager>(HttpManager.getInstance());

  // BoxService
  sl.registerSingleton<BoxService<User>>(BoxService<User>('user_box'));
  sl.registerSingleton<BoxService<Order>>(BoxService<Order>('order_box'));

  // Repository
  sl.registerFactory<UserRepository>(() =>
    UserRepositoryImpl(sl<HttpManager>(), sl<BoxService<User>>()));
  sl.registerFactory<HomeRepository>(() =>
    HomeRepositoryImpl(sl<HttpManager>(), sl<BoxService<HomeData>>()));

  // Cubit
  sl.registerFactory<UserCubit>(() => UserCubit(sl<UserRepository>()));
  sl.registerFactory<HomeCubit>(() => HomeCubit(sl<HomeRepository>()));
}
```

---

## Phase 2: 核心机制

### 2.1 Bloc状态管理

**依赖：** flutter_bloc, bloc_test

**Feature结构：**

```
features/home/
  repository/
    home_repository.dart       # 接口
    home_repository_impl.dart  # 实现
    README.md
  cubit/
    home_cubit.dart
    home_state.dart
    README.md
  ui/
    home_page.dart
    README.md
```

**Cubit示例：**

```dart
// home_cubit.dart
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository repository;

  HomeCubit(this.repository) : super(HomeInitial());

  Future<void> loadData() async {
    emit(HomeLoading());
    try {
      final data = await repository.getHomeData();
      emit(HomeLoaded(data));
    } on DomainException catch (e) {
      emit(HomeError(e.errorCode));
    }
  }
}

// home_state.dart
abstract class HomeState {}
class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final HomeData data;
  HomeLoaded(this.data);
}
class HomeError extends HomeState {
  final ErrorCode errorCode;
  HomeError(this.errorCode);
}
```

**策略：默认Cubit，复杂场景用Bloc。**

---

### 2.2 国际化

**依赖：** flutter_intl插件（IDE）

**文件结构：**

```
lib/core/l10n/
  app_zh.arb          # 中文（主模板）
  app_en.arb          # 英文
  l10n.yaml           # 配置
  README.md

generated/
  intl/               # 插件自动生成
```

**l10n.yaml配置：**

```yaml
arb-dir: lib/core/l10n
template-arb-file: app_zh.arb
output-localization-file: app_localizations.dart
output-class-name: AppLocalizations
```

**ARB示例：**

```json
// app_zh.arb
{
  "@@locale": "zh",
  "networkError": "网络连接失败",
  "tokenExpired": "登录已过期",
  "retry": "重试"
}

// app_en.arb
{
  "@@locale": "en",
  "networkError": "Network connection failed",
  "tokenExpired": "Session expired",
  "retry": "Retry"
}
```

**LocaleCubit：**

```dart
// lib/core/global/locale/locale_cubit.dart
class LocaleCubit extends Cubit<Locale> {
  final KeyValueStorage storage;

  LocaleCubit(this.storage) : super(Locale('zh')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final code = await storage.getString('locale');
    if (code != null) emit(Locale(code));
  }

  Future<void> setLocale(Locale locale) async {
    await storage.putString('locale', locale.languageCode);
    emit(locale);
  }
}
```

---

### 2.3 错误处理

**精简设计：API层直接返回DomainException**

**文件精简：**

| 原文件 | 处理 |
|--------|------|
| packages/api/src/models/exceptions.dart | 删除 |
| packages/api/src/http/error_handler.dart | 合并入 dio_mapper.dart |
| packages/api/src/http/http_error.dart | 精简 |

**新文件结构：**

```
packages/domain_models/src/
  exceptions.dart          # DomainException + ErrorCode
  hive/
    registrar.dart         # Hive Adapter注册

packages/api/src/error/
  error_codes.dart         # ErrorCode enum
  dio_mapper.dart          # DioException → DomainException
  README.md
```

**ErrorCode定义：**

```dart
// domain_models/src/exceptions.dart
enum ErrorCode {
  networkError,
  requestCancelled,
  connectionTimeout,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  invalidInput,
  tokenExpired,
  unknown,
}

class DomainException implements Exception {
  final ErrorCode errorCode;
  final int? httpCode;
  final Map<String, dynamic>? rawData;

  DomainException(this.errorCode, {this.httpCode, this.rawData});

  String getMessage(BuildContext context) {
    final key = errorCode.name; // networkError, tokenExpired...
    return AppLocalizations.of(context).translate(key);
  }
}

// 国际化ARB需包含所有ErrorCode key
// app_zh.arb: "networkError": "网络连接失败"
// app_en.arb: "networkError": "Network connection failed"
```

**DioException映射：**

```dart
// packages/api/src/error/dio_mapper.dart
extension DioExceptionMapper on DioException {
  DomainException toDomainException() {
    return DomainException(
      _mapErrorCode(type, response?.statusCode),
      httpCode: response?.statusCode,
      rawData: response?.data,
    );
  }

  static ErrorCode _mapErrorCode(DioExceptionType type, int? statusCode) {
    if (statusCode != null) {
      return _statusCodeMap[statusCode] ?? ErrorCode.serverError;
    }
    return _typeMap[type] ?? ErrorCode.unknown;
  }

  static const _statusCodeMap = {
    401: ErrorCode.unauthorized,
    403: ErrorCode.forbidden,
    404: ErrorCode.notFound,
    500: ErrorCode.serverError,
  };

  static const _typeMap = {
    DioExceptionType.cancel: ErrorCode.requestCancelled,
    DioExceptionType.connectionTimeout: ErrorCode.connectionTimeout,
  };
}
```

---

## Phase 3: 扩展功能

### 3.1 API增强

#### CancelTokenManager

**文件位置：** `packages/api/src/cancel/cancel_manager.dart`

```dart
class CancelTokenManager {
  static final instance = CancelTokenManager._();
  CancelTokenManager._();

  final Map<String, List<CancelToken>> _pageTokens = {};

  void register(String pageTag, CancelToken token) {
    _pageTokens.putIfAbsent(pageTag, () => []).add(token);
  }

  void cancelPage(String pageTag) {
    final tokens = _pageTokens[pageTag];
    if (tokens != null) {
      for (final token in tokens) {
        token.cancel('Page disposed: $pageTag');
      }
      tokens.clear();
    }
  }

  void cleanup(String pageTag) {
    _pageTokens.remove(pageTag);
  }
}
```

#### RequestScope Widget

**文件位置：** `lib/core/widgets/request_scope.dart`

```dart
class RequestScope extends StatefulWidget {
  final String tag;
  final Widget child;

  const RequestScope({required this.tag, required this.child});

  @override
  State<RequestScope> createState() => _RequestScopeState();
}

class _RequestScopeState extends State<RequestScope> {
  @override
  void dispose() {
    CancelTokenManager.instance.cancelPage(widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

#### RequestTracker

**文件位置：** `packages/api/src/tracking/request_tracker.dart`

```dart
class RequestTracker {
  static final instance = RequestTracker._();
  RequestTracker._();

  final Map<String, _RequestInfo> _requests = {};

  void track(String requestId, String path, DateTime startTime) {
    _requests[requestId] = _RequestInfo(path, startTime);
  }

  void complete(String requestId) {
    final info = _requests[requestId];
    if (info != null) {
      final duration = DateTime.now().difference(info.startTime);
      AppLogger.instance.debug('Request $requestId: ${info.path} - ${duration.inMs}ms');
      _requests.remove(requestId);
    }
  }

  List<_RequestInfo> get pendingRequests => _requests.values.toList();
}

class _RequestInfo {
  final String path;
  final DateTime startTime;
  _RequestInfo(this.path, this.startTime);
}
```

#### Retry配置

**文件位置：** `packages/api/src/http/retry_policy.dart`

```dart
class RetryPolicy {
  final int maxRetries;
  final Duration retryDelay;
  final List<DioExceptionType> retryableTypes;
  final List<int> retryableStatusCodes;

  const RetryPolicy({
    this.maxRetries = 0,  // 默认不重试
    this.retryDelay = const Duration(seconds: 1),
    this.retryableTypes = const [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ],
    this.retryableStatusCodes = const [502, 503, 504],
  });

  static const RetryPolicy none = RetryPolicy();
  static const RetryPolicy standard = RetryPolicy(maxRetries: 3);
  static const RetryPolicy aggressive = RetryPolicy(
    maxRetries: 5,
    retryDelay: Duration(milliseconds: 500),
    retryableStatusCodes: [500, 502, 503, 504],
  );
}
```

**ApiBuilder集成：**

```dart
class ApiBuilder {
  RetryPolicy _retryPolicy = RetryPolicy.none;  // 默认不重试

  ApiBuilder retry() => withRetry(RetryPolicy.standard);
  ApiBuilder retryAggressive() => withRetry(RetryPolicy.aggressive);
  ApiBuilder withRetry(RetryPolicy policy) {
    _retryPolicy = policy;
    return this;
  }
}
```

#### API分组Mixin

**文件结构：**

```
packages/api/src/modules/
  user/
    user_api.dart
    README.md
  home/
    home_api.dart
    README.md
  order/
    order_api.dart
    README.md
```

**Mixin示例：**

```dart
// user_api.dart
mixin UserApi {
  HttpManager get api;

  Future<dynamic> login({required String username, required String password}) =>
    api.post('/user/login')
      .addParam('username', username)
      .addParam('password', password)
      .fire();

  Future<dynamic> getUserInfo() => api.get('/user/info').fire();

  Future<dynamic> logout() => api.post('/user/logout').fire();
}

// Repository使用
class UserRepositoryImpl implements UserRepository with UserApi {
  @override
  final HttpManager api;
  final BoxService<User> _userBox;

  UserRepositoryImpl(this.api, this._userBox);

  Future<User> getUserInfo({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _userBox.get('current_user');
      if (cached != null) return cached;
    }
    final response = await super.getUserInfo();
    final user = User.fromJson(response);
    await _userBox.put('current_user', user);
    return user;
  }
}
```

#### ConcurrentLimiter

**文件位置：** `packages/api/src/http/concurrent_limiter.dart`

```dart
class ConcurrentLimiter {
  final int maxConcurrent;
  final Queue<_PendingRequest> _queue = Queue();
  int _currentRunning = 0;

  ConcurrentLimiter({this.maxConcurrent = 5});

  Future<T> execute<T>(
    Future<T> Function() request,
    {int priority = 0, String? tag}
  ) async {
    if (_currentRunning < maxConcurrent) {
      return _runRequest<T>(request);
    }
    final pending = _PendingRequest<T>(request: request, priority: priority, tag: tag);
    _queue.add(pending);
    _sortQueue();
    return pending.completer.future;
  }

  void cancelTag(String tag) {
    _queue.where((p) => p.tag == tag).forEach((p) {
      p.completer.completeError(DomainException(ErrorCode.requestCancelled));
    });
    _queue.removeWhere((p) => p.tag == tag);
  }
}

class ConcurrentLimiters {
  static final upload = ConcurrentLimiter(maxConcurrent: 3);
  static final standard = ConcurrentLimiter(maxConcurrent: 5);
  static final sync = ConcurrentLimiter(maxConcurrent: 2);
}
```

---

### 3.2 Hive缓存扩展

#### BoxManager

**文件位置：** `packages/key_value_storage/src/box_manager.dart`

```dart
class BoxManager {
  static final instance = BoxManager._();
  BoxManager._();

  final Map<String, Box> _openedBoxes = {};

  Future<Box<T>> getBox<T>(String boxName) async {
    if (_openedBoxes.containsKey(boxName)) {
      return _openedBoxes[boxName] as Box<T>;
    }
    final box = await Hive.openBox<T>(boxName);
    _openedBoxes[boxName] = box;
    return box;
  }

  Future<void> closeAll() async {
    for (final box in _openedBoxes.values) {
      await box.close();
    }
    _openedBoxes.clear();
  }
}
```

#### BoxService

**文件位置：** `packages/key_value_storage/src/box_service.dart`

```dart
class BoxService<T> {
  final String boxName;
  final BoxManager _manager = BoxManager.instance;

  BoxService(this.boxName);

  Future<Box<T>> _box() => _manager.getBox<T>(boxName);

  // 基础CRUD
  Future<void> put(String key, T value) async {
    final box = await _box();
    await box.put(key, value);
  }

  Future<T?> get(String key) async {
    final box = await _box();
    return box.get(key);
  }

  Future<void> delete(String key) async {
    final box = await _box();
    await box.delete(key);
  }

  // 批量操作
  Future<void> putAll(Map<String, T> items) async {
    final box = await _box();
    await box.putAll(items);
  }

  Future<List<T>> getAllValues() async {
    final box = await _box();
    return box.values.toList();
  }

  // 排序/过滤（性能警告：数据量 < 50条）
  Future<List<T>> getSorted(Comparator<T> comparator) async {
    final values = await getAllValues();
    values.sort(comparator);
    return values;
  }

  // 过期机制
  Future<void> putWithExpiry(String key, T value, {Duration? ttl}) async {
    final data = CacheData<T>(value, ttl: ttl);
    final box = await _manager.getBox<CacheData<T>>('${boxName}_cache');
    await box.put(key, data);
  }

  Future<T?> getWithExpiry(String key) async {
    final box = await _manager.getBox<CacheData<T>>('${boxName}_cache');
    final data = box.get(key);
    if (data == null || data.isExpired) {
      await box.delete(key);
      return null;
    }
    return data.value;
  }
}
```

#### CacheData

**文件位置：** `packages/key_value_storage/src/cache_data.dart`

```dart
@HiveType(typeId: 0)
class CacheData {
  @HiveField(0)
  final dynamic value;

  @HiveField(1)
  final DateTime expireAt;

  CacheData(this.value, {Duration? ttl})
    : expireAt = DateTime.now().add(ttl ?? Duration(hours: 24));

  bool get isExpired => DateTime.now().isAfter(expireAt);
}
```

#### Hive Adapter注册

**文件位置：**

```
packages/key_value_storage/src/
  hive_registrar.dart

packages/domain_models/src/hive/
  registrar.dart
  user_adapter.dart
```

```dart
// key_value_storage/src/hive_registrar.dart
class HiveRegistrar {
  static bool _registered = false;

  static Future<void> registerAll() async {
    if (_registered) return;
    Hive.registerAdapter(CacheDataAdapter());  // typeId: 0
    DomainHiveRegistrar.registerAll();
    _registered = true;
  }
}

// domain_models/src/hive/registrar.dart
class DomainHiveRegistrar {
  static bool _registered = false;

  static void registerAll() {
    if (_registered) return;
    Hive.registerAdapter(DemoUserAdapter());  // typeId: 1
    _registered = true;
  }
}
```

---

### 3.3 NetworkCubit

**文件位置：** `lib/core/global/network/`

```dart
// network_state.dart
enum NetworkStatus { connected, disconnected }
enum NetworkUIStyle { banner, toast, snackbar, dialog, none }

class NetworkState {
  final NetworkStatus status;
  final DateTime? lastDisconnectedAt;
  final NetworkUIStyle uiStyle;

  NetworkState({
    required this.status,
    this.lastDisconnectedAt,
    this.uiStyle = NetworkUIStyle.banner,
  });

  bool get isConnected => status == NetworkStatus.connected;
}

// network_cubit.dart
class NetworkCubit extends Cubit<NetworkState> {
  final Connectivity _connectivity;
  StreamSubscription? _subscription;

  NetworkCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(NetworkState(status: NetworkStatus.connected));

  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      emit(NetworkState(
        status: isConnected ? NetworkStatus.connected : NetworkStatus.disconnected,
        lastDisconnectedAt: isConnected ? null : DateTime.now(),
      ));
    });
  }

  void setUIStyle(NetworkUIStyle style) {
    emit(state.copyWith(uiStyle: style));
  }

  Future<void> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    emit(NetworkState(
      status: result != ConnectivityResult.none ? NetworkStatus.connected : NetworkStatus.disconnected,
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

**UI组件：**

```dart
// lib/core/widgets/network/network_banner.dart
class NetworkBanner extends StatelessWidget {
  final Widget child;

  const NetworkBanner({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        return Stack(
          children: [
            child,
            if (!state.isConnected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.red.shade400,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).networkError,
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// lib/core/widgets/network/network_ui_handler.dart
class NetworkUIHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkCubit, NetworkState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.isConnected) return;
        switch (state.uiStyle) {
          case NetworkUIStyle.toast:
            EasyLoading.showToast(AppLocalizations.of(context).networkError);
            break;
          case NetworkUIStyle.snackbar:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).networkError),
                action: SnackBarAction(
                  label: AppLocalizations.of(context).retry,
                  onPressed: () => context.read<NetworkCubit>().checkNow(),
                ),
              ),
            );
            break;
          case NetworkUIStyle.dialog:
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context).networkError),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<NetworkCubit>().checkNow();
                    },
                    child: Text(AppLocalizations.of(context).retry),
                  ),
                ],
              ),
            );
            break;
          default:
            break;
        }
      },
      child: const SizedBox.shrink(),
    );
  }
}
```

---

### 3.4 Token续期AppLogger改造

**原则：只改日志输出，不改续期逻辑。**

**改造点：**

```dart
// packages/api/src/dio/renewal_token_intercaptor.dart
class TokenRenewalInterceptor extends Interceptor {
  AppLogger? _logger;

  set logger(AppLogger logger) => _logger = logger;

  void _log(String message, {LogLevel level = LogLevel.info}) {
    if (_logger != null) {
      _logger.log(level, '[TokenRenewal] $message');
    } else if (kDebugMode) {
      debugPrint('[TokenRenewal] $message');
    }
  }

  // 所有原 debugPrint('...') 替换为 _log('...')
  // 续期逻辑完全不变
}
```

**日志级别映射：**

| 原日志内容 | LogLevel |
|-----------|----------|
| 续期成功/获取token | info |
| 队列操作/重试请求 | debug |
| 续期失败/超时 | warning |
| 出错/异常 | error |

---

## Phase 4: 测试模板（跳过）

用户要求放到最后。

---

## 依赖变更

**新增依赖：**

```yaml
dependencies:
  flutter_bloc: ^8.1.0
  get_it: ^7.6.0
  intl: ^0.18.0

dev_dependencies:
  bloc_test: ^9.1.0
  mocktail: ^0.3.0
  build_runner: ^2.4.0
  hive_generator: ^2.0.0
```

**现有依赖保持：** dio, hive, connectivity_plus, go_router

---

## 破坏性变更

| 变更 | 影响 |
|------|------|
| lib/src/* 迁移至 features/*/ | 所有页面路径变更 |
| RepositoryFactory → GetIt | DI调用方式变更 |
| 错误消息 → ErrorCode | 需国际化支持 |

---

## 实施顺序

| Phase | 内容 | 破坏性 |
|-------|------|--------|
| **P1** | 目录重构 + Constants + Logger + GetIt | 高 |
| **P2** | Bloc → 国际化 → 错误处理 | 中 |
| **P3** | API增强 + Hive扩展 + NetworkCubit | 低 |
| **P4** | 测试模板 | 无 |

---

## 文件统计

| 类型 | 新增 | 改造 |
|------|------|------|
| 核心架构 | ~25个 | ~10个 |
| API增强 | ~8个 | ~3个 |
| Hive扩展 | ~4个 | ~2个 |
| NetworkCubit | ~4个 | 0 |

---

## 各模块README要求

每个模块目录必须有README.md，包含：

1. 模块职责说明
2. 使用示例
3. 依赖关系
4. 性能警告（如有）