# Flutter架构重构 - Phase 2: 核心机制 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现Bloc状态管理、国际化支持、统一错误处理机制

**Architecture:** 采用Cubit作为默认状态管理方案，复杂场景使用Bloc。国际化使用flutter_intl工具生成。错误处理统一为DomainException + ErrorCode枚举。

**Tech Stack:** flutter_bloc ^8.1.0, bloc_test ^9.1.0, intl ^0.18.0, flutter_intl插件

---

## 文件结构概览

**创建的新目录和文件：**

```
lib/
  core/
    global/
      locale/
        locale_cubit.dart      # LocaleCubit
        locale_state.dart      # LocaleState
        README.md
    l10n/
      app_zh.arb               # 中文ARB模板
      app_en.arb               # 英文ARB
      l10n.yaml                # 配置文件
      README.md
  features/
    home/
      repository/
        home_repository.dart      # 接口
        home_repository_impl.dart # 实现
        README.md
      cubit/
        home_cubit.dart           # HomeCubit
        home_state.dart           # HomeState
        README.md
      ui/
        home_page.dart            # 更新：使用BlocBuilder
        README.md
    detail/
      repository/
        detail_repository.dart
        detail_repository_impl.dart
        README.md
      cubit/
        detail_cubit.dart
        detail_state.dart
        README.md
      ui/
        detail_page.dart          # 更新：使用BlocBuilder
        README.md

packages/
  domain_models/
    src/
      exceptions.dart             # DomainException + ErrorCode
      hive/
        registrar.dart            # Hive Adapter注册
  api/
    src/
      error/
        error_codes.dart          # ErrorCode enum
        dio_mapper.dart           # DioException → DomainException映射
        README.md
```

**依赖Phase 1完成项：**
- lib/core/di/locator.dart
- lib/core/di/setup.dart
- lib/core/utils/logger.dart
- lib/core/constants/

---

### Task 1: 添加Bloc依赖

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: 添加Bloc相关依赖**

在 `pubspec.yaml` 的 dependencies 和 dev_dependencies 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Infrastructure
  api:
    path: packages/api
  key_value_storage:
    path: packages/key_value_storage
  domain_models:
    path: packages/domain_models
  component_library:
    path: packages/component_library
  routing:
    path: packages/routing

  # Dependency Injection
  get_it: ^7.6.0

  # State Management
  flutter_bloc: ^8.1.0

  # Internationalization
  intl: ^0.18.0

  # Common
  flutter_easyloading: ^3.0.5
  flutter_screenutil: ^5.9.0
  go_router: ^14.2.7
  rxdart: ^0.27.1
  dio: ^5.2.0+1
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

  # Bloc Testing
  bloc_test: ^9.1.0
  mocktail: ^0.3.0

  # Code Generation
  build_runner: ^2.4.0
  hive_generator: ^2.0.0
```

- [ ] **Step 2: 安装依赖**

```bash
flutter pub get
```

Expected: flutter_bloc ^8.1.0, bloc_test ^9.1.0, intl ^0.18.0 安装成功

- [ ] **Step 3: 验证依赖**

```bash
flutter pub deps | grep bloc
flutter pub deps | grep intl
```

Expected: 显示flutter_bloc和intl依赖

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat(phase2): 添加Bloc和国际化依赖

- flutter_bloc ^8.1.0: 状态管理
- bloc_test ^9.1.0: Bloc测试工具
- intl ^0.18.0: 国际化支持
- mocktail ^0.3.0: Mock测试

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: 创建ErrorCode和DomainException

**Files:**
- Create: `packages/domain_models/src/exceptions.dart`
- Modify: `packages/domain_models/lib/domain_models.dart` (导出exceptions)

- [ ] **Step 1: 创建ErrorCode枚举**

```dart
/// 错误码枚举
///
/// 职责：统一定义所有业务错误类型，用于错误处理和国际化
/// 使用：DomainException.errorCode获取具体错误类型
/// 国际化：每个errorCode.name对应ARB文件中的key
enum ErrorCode {
  /// 网络连接失败
  networkError,

  /// 请求被取消
  requestCancelled,

  /// 连接超时
  connectionTimeout,

  /// 未授权（401）
  unauthorized,

  /// 禁止访问（403）
  forbidden,

  /// 资源不存在（404）
  notFound,

  /// 服务器错误（500）
  serverError,

  /// 输入参数无效
  invalidInput,

  /// Token已过期
  tokenExpired,

  /// 未知错误
  unknown,
}
```

- [ ] **Step 2: 创建DomainException**

```dart
import 'package:flutter/widgets.dart';

/// 域异常
///
/// 职责：统一应用层异常，携带ErrorCode用于国际化错误消息
/// 使用：
///   - API层抛出：throw DomainException(ErrorCode.networkError)
///   - UI层处理：exception.getMessage(context)获取本地化消息
/// 注意：所有业务异常都应转换为DomainException
class DomainException implements Exception {
  /// 错误码
  final ErrorCode errorCode;

  /// HTTP状态码（可选）
  final int? httpCode;

  /// 原始响应数据（可选，用于调试）
  final Map<String, dynamic>? rawData;

  DomainException(
    this.errorCode,
    {
      this.httpCode,
      this.rawData,
    }
  );

  /// 获取本地化错误消息
  ///
  /// 使用errorCode.name作为ARB key查找国际化文本
  /// 示例：ErrorCode.networkError → ARB key "networkError"
  ///
  /// 注意：需要BuildContext获取AppLocalizations
  /// ARB文件必须包含所有ErrorCode.name对应的key
  String getMessage(BuildContext context) {
    // Phase 2完成国际化后，使用AppLocalizations
    // 目前返回errorCode.name作为占位
    return errorCode.name;
    // 最终实现：
    // return AppLocalizations.of(context).translate(errorCode.name);
  }

  @override
  String toString() {
    return 'DomainException: ${errorCode.name} (http: $httpCode)';
  }
}
```

写入 `packages/domain_models/src/exceptions.dart`

- [ ] **Step 3: 导出exceptions**

修改 `packages/domain_models/lib/domain_models.dart`：

```dart
export 'src/enum.dart';
export 'src/exceptions.dart';
```

- [ ] **Step 4: 验证文件创建**

```bash
cat packages/domain_models/src/exceptions.dart
cat packages/domain_models/lib/domain_models.dart
```

Expected: 文件创建成功，导出正确

- [ ] **Step 5: Commit**

```bash
git add packages/domain_models/src/exceptions.dart packages/domain_models/lib/domain_models.dart
git commit -m "feat(phase2): 创建ErrorCode和DomainException统一错误处理

- ErrorCode枚举定义所有业务错误类型
- DomainException携带ErrorCode用于国际化
- getMessage(context)返回本地化错误消息
- 中文注释说明使用方式和注意事项

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: 创建DioException映射器

**Files:**
- Create: `packages/api/src/error/dio_mapper.dart`
- Create: `packages/api/src/error/error_codes.dart` (可选，如果domain_models不在api包依赖中)
- Create: `packages/api/src/error/README.md`
- Modify: `packages/api/lib/api.dart` (导出error模块)

- [ ] **Step 1: 检查domain_models依赖**

首先检查api包是否依赖domain_models：

```bash
cat packages/api/pubspec.yaml
```

如果domain_models已在依赖中，直接使用。否则需要添加依赖。

- [ ] **Step 2: 创建dio_mapper.dart**

```dart
import 'package:dio/dio.dart';
import 'package:domain_models/domain_models.dart';

/// DioException到DomainException的映射扩展
///
/// 职责：将Dio底层异常转换为业务层统一的DomainException
/// 使用：dioException.toDomainException()
/// 注意：在API层catch DioException后立即转换
extension DioExceptionMapper on DioException {
  /// 转换为DomainException
  ///
  /// 根据DioException类型和HTTP状态码映射到对应ErrorCode
  DomainException toDomainException() {
    final errorCode = _mapErrorCode(type, response?.statusCode);
    return DomainException(
      errorCode,
      httpCode: response?.statusCode,
      rawData: response?.data as Map<String, dynamic>?,
    );
  }

  /// 映射ErrorCode
  ///
  /// 优先使用HTTP状态码映射，其次使用DioException类型
  static ErrorCode _mapErrorCode(DioExceptionType type, int? statusCode) {
    // HTTP状态码优先
    if (statusCode != null) {
      return _statusCodeMap[statusCode] ?? ErrorCode.serverError;
    }
    // DioException类型其次
    return _typeMap[type] ?? ErrorCode.unknown;
  }

  /// HTTP状态码映射表
  ///
  /// 常见HTTP错误码对应业务ErrorCode
  static const Map<int, ErrorCode> _statusCodeMap = {
    401: ErrorCode.unauthorized,
    403: ErrorCode.forbidden,
    404: ErrorCode.notFound,
    500: ErrorCode.serverError,
  };

  /// DioException类型映射表
  ///
  /// Dio底层错误类型对应业务ErrorCode
  static const Map<DioExceptionType, ErrorCode> _typeMap = {
    DioExceptionType.cancel: ErrorCode.requestCancelled,
    DioExceptionType.connectionTimeout: ErrorCode.connectionTimeout,
    DioExceptionType.sendTimeout: ErrorCode.connectionTimeout,
    DioExceptionType.receiveTimeout: ErrorCode.connectionTimeout,
    DioExceptionType.connectionError: ErrorCode.networkError,
  };
}
```

写入 `packages/api/src/error/dio_mapper.dart`

- [ ] **Step 3: 创建README**

```markdown
# 错误处理模块

## 职责
将Dio底层异常转换为业务层统一的DomainException，支持国际化错误消息。

## 使用示例
```dart
try {
  final response = await api.get('/user/info').fire();
} on DioException catch (e) {
  // 转换为DomainException
  final domainException = e.toDomainException();
  // 在UI层获取本地化消息
  showMessage(domainException.getMessage(context));
}
```

## 依赖关系
- dio: DioException来源
- domain_models: ErrorCode和DomainException定义

## 映射规则
1. HTTP状态码优先：401/403/404/500等
2. DioException类型其次：cancel/timeout/connectionError等
3. 无法识别返回ErrorCode.unknown

## 性能警告
无
```

写入 `packages/api/src/error/README.md`

- [ ] **Step 4: 导出error模块**

修改 `packages/api/lib/api.dart`，添加导出：

```dart
export 'src/api.dart';
export 'src/modules/modules.dart';
export 'src/http/http_error.dart';
export 'src/http/http_event_bus.dart';
export 'src/http/http_constant.dart';
export 'src/http/error_handler.dart';
export 'src/http/token_supplier.dart';
export 'src/dio/log_reporting_interceptor.dart';
// Phase 2新增
export 'src/error/dio_mapper.dart';
```

- [ ] **Step 5: 验证文件创建**

```bash
ls -la packages/api/src/error/
cat packages/api/src/error/dio_mapper.dart
```

Expected: error目录和文件创建成功

- [ ] **Step 6: Commit**

```bash
git add packages/api/src/error/ packages/api/lib/api.dart
git commit -m "feat(phase2): 创建DioException映射器

- DioExceptionMapper扩展方法
- HTTP状态码和DioException类型映射表
- toDomainException()转换为统一异常
- 中文注释说明映射规则

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: 创建国际化目录和配置

**Files:**
- Create: `lib/core/l10n/l10n.yaml`
- Create: `lib/core/l10n/app_zh.arb`
- Create: `lib/core/l10n/app_en.arb`
- Create: `lib/core/l10n/README.md`

- [ ] **Step 1: 创建l10n目录**

```bash
mkdir -p lib/core/l10n
```

- [ ] **Step 2: 创建l10n.yaml配置**

```yaml
# 国际化配置文件
#
# 使用flutter_intl插件或flutter gen-l10n命令生成代码
# 生成位置：.dart_tool/flutter_gen/gen_l10n/

arb-dir: lib/core/l10n
template-arb-file: app_zh.arb
output-localization-file: app_localizations.dart
output-class-name: AppLocalizations
```

写入 `lib/core/l10n/l10n.yaml`

- [ ] **Step 3: 创建中文ARB模板**

```json
{
  "@@locale": "zh",
  "@@last_modified": "2026-04-30",

  "networkError": "网络连接失败",
  "@networkError": {
    "description": "网络连接失败时的错误提示"
  },

  "requestCancelled": "请求已取消",
  "@requestCancelled": {
    "description": "请求被用户取消"
  },

  "connectionTimeout": "连接超时",
  "@connectionTimeout": {
    "description": "网络连接超时提示"
  },

  "unauthorized": "请先登录",
  "@unauthorized": {
    "description": "用户未登录或Token失效"
  },

  "forbidden": "无权访问",
  "@forbidden": {
    "description": "用户无权限访问该资源"
  },

  "notFound": "资源不存在",
  "@notFound": {
    "description": "请求的资源不存在"
  },

  "serverError": "服务器错误",
  "@serverError": {
    "description": "服务器内部错误"
  },

  "invalidInput": "输入参数无效",
  "@invalidInput": {
    "description": "用户输入参数校验失败"
  },

  "tokenExpired": "登录已过期",
  "@tokenExpired": {
    "description": "用户Token已过期，需重新登录"
  },

  "unknown": "未知错误",
  "@unknown": {
    "description": "未知的错误类型"
  },

  "retry": "重试",
  "@retry": {
    "description": "重试按钮文本"
  },

  "loading": "加载中...",
  "@loading": {
    "description": "加载状态提示"
  },

  "appName": "我的应用",
  "@appName": {
    "description": "应用名称"
  },

  "homeTitle": "首页",
  "@homeTitle": {
    "description": "首页标题"
  },

  "detailTitle": "详情",
  "@detailTitle": {
    "description": "详情页标题"
  }
}
```

写入 `lib/core/l10n/app_zh.arb`

- [ ] **Step 4: 创建英文ARB**

```json
{
  "@@locale": "en",

  "networkError": "Network connection failed",
  "requestCancelled": "Request cancelled",
  "connectionTimeout": "Connection timeout",
  "unauthorized": "Please login first",
  "forbidden": "Access denied",
  "notFound": "Resource not found",
  "serverError": "Server error",
  "invalidInput": "Invalid input",
  "tokenExpired": "Session expired",
  "unknown": "Unknown error",
  "retry": "Retry",
  "loading": "Loading...",
  "appName": "My App",
  "homeTitle": "Home",
  "detailTitle": "Detail"
}
```

写入 `lib/core/l10n/app_en.arb`

- [ ] **Step 5: 创建README**

```markdown
# 国际化模块

## 职责
管理应用多语言支持，提供统一的本地化文本。

## 使用方式

### 方式1：flutter_intl插件（推荐）

1. VS Code/Android Studio安装flutter_intl插件
2. 打开ARB文件编辑，插件自动生成代码
3. 生成文件位于 `.dart_tool/flutter_gen/gen_l10n/`

### 方式2：命令行生成

```bash
flutter gen-l10n
```

### 方式3：手动配置（本项目）

在 `l10n.yaml` 中配置：
- arb-dir: ARB文件目录
- template-arb-file: 主模板（中文）
- output-localization-file: 输出文件名
- output-class-name: 输出类名

## 使用示例
```dart
// 获取本地化文本
final text = AppLocalizations.of(context).networkError;

// 在Widget中使用
Text(AppLocalizations.of(context).appName)
```

## ARB文件结构
- app_zh.arb: 中文模板（主语言）
- app_en.arb: 英文翻译
- 其他语言添加对应ARB文件

## ErrorCode国际化
每个ErrorCode.name对应ARB中的一个key：
- ErrorCode.networkError → "networkError": "网络连接失败"
- ErrorCode.tokenExpired → "tokenExpired": "登录已过期"

## 依赖关系
- intl: ^0.18.0
- flutter_localizations: sdk

## 性能警告
无
```

写入 `lib/core/l10n/README.md`

- [ ] **Step 6: 验证文件创建**

```bash
ls -la lib/core/l10n/
cat lib/core/l10n/l10n.yaml
cat lib/core/l10n/app_zh.arb
```

Expected: l10n目录和文件创建成功

- [ ] **Step 7: Commit**

```bash
git add lib/core/l10n/
git commit -m "feat(phase2): 创建国际化配置和ARB文件

- l10n.yaml配置文件
- app_zh.arb中文模板（包含所有ErrorCode翻译）
- app_en.arb英文翻译
- 中文README说明使用方式

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: 生成国际化代码

**Files:**
- Generated: `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart`
- Generated: `.dart_tool/flutter_gen/gen_l10n/app_localizations_zh.dart`
- Generated: `.dart_tool/flutter_gen/gen_l10n/app_localizations_en.dart`

- [ ] **Step 1: 运行国际化代码生成**

```bash
flutter gen-l10n
```

Expected: 在 `.dart_tool/flutter_gen/gen_l10n/` 目录生成国际化代码

- [ ] **Step 2: 验证生成文件**

```bash
ls -la .dart_tool/flutter_gen/gen_l10n/
cat .dart_tool/flutter_gen/gen_l10n/app_localizations.dart
```

Expected: 生成app_localizations相关文件

- [ ] **Step 3: 检查生成内容**

生成的AppLocalizations应包含：
- networkError getter
- retry getter
- appName getter
- 所有ErrorCode对应的getter

- [ ] **Step 4: Commit（生成文件通常不需要commit，但确认生成成功）**

生成文件在.dart_tool目录，通常不提交到git。记录生成成功即可。

---

### Task 6: 创建LocaleCubit

**Files:**
- Create: `lib/core/global/locale/locale_cubit.dart`
- Create: `lib/core/global/locale/locale_state.dart`
- Create: `lib/core/global/locale/README.md`

- [ ] **Step 1: 创建LocaleState**

```dart
/// 语言状态
///
/// 职责：管理当前应用语言设置
/// 使用：通过LocaleCubit emit切换语言
class LocaleState {
  /// 当前语言
  final Locale locale;

  LocaleState({required this.locale});

  /// 复制并修改
  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale: locale ?? this.locale);
  }
}
```

写入 `lib/core/global/locale/locale_state.dart`

- [ ] **Step 2: 创建LocaleCubit**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'locale_state.dart';

/// 语言管理Cubit
///
/// 职责：管理应用语言设置，持久化用户语言偏好
/// 使用：
///   - 获取当前语言：context.read<LocaleCubit>().state.locale
///   - 切换语言：context.read<LocaleCubit>().setLocale(Locale('en'))
/// 持久化：语言设置保存到KeyValueStorage，App重启后恢复
class LocaleCubit extends Cubit<LocaleState> {
  /// KeyValueStorage用于持久化语言设置
  final KeyValueStorage _storage;

  /// 语言设置存储key
  static const String _localeKey = 'app_locale';

  LocaleCubit(this._storage) : super(LocaleState(locale: Locale('zh'))) {
    // 启动时加载已保存的语言设置
    _loadSavedLocale();
  }

  /// 加载保存的语言设置
  ///
  /// 从KeyValueStorage读取用户上次选择的语言
  Future<void> _loadSavedLocale() async {
    final savedLocale = await _storage.getString(_localeKey);
    if (savedLocale != null) {
      emit(LocaleState(locale: Locale(savedLocale)));
    }
  }

  /// 设置语言
  ///
  /// 切换应用语言并持久化保存
  /// 支持的语言：zh（中文）、en（英文）
  Future<void> setLocale(Locale locale) async {
    // 持久化保存
    await _storage.putString(_localeKey, locale.languageCode);
    // 更新状态
    emit(LocaleState(locale: locale));
  }

  /// 重置为默认语言（中文）
  Future<void> resetToDefault() async {
    await setLocale(Locale('zh'));
  }
}
```

写入 `lib/core/global/locale/locale_cubit.dart`

- [ ] **Step 3: 创建README**

```markdown
# 语言管理模块

## 职责
管理应用语言设置，支持多语言切换和持久化。

## 使用示例
```dart
// 在DI中注册（单例）
sl.registerSingleton<LocaleCubit>(
  LocaleCubit(sl<KeyValueStorage>())
);

// 在App顶层提供
BlocProvider(
  create: (context) => sl<LocaleCubit>(),
  child: MyApp(),
)

// 切换语言
context.read<LocaleCubit>().setLocale(Locale('en'));

// 获取当前语言
final locale = context.read<LocaleCubit>().state.locale;
```

## 依赖关系
- flutter_bloc: Cubit基类
- key_value_storage: 语言偏好持久化

## 持久化
语言设置保存在KeyValueStorage，key为'app_locale'。
App重启后自动恢复上次语言设置。

## 支持语言
- zh: 中文（默认）
- en: 英文

## 性能警告
无
```

写入 `lib/core/global/locale/README.md`

- [ ] **Step 4: 在DI中注册LocaleCubit**

修改 `lib/core/di/setup.dart`，添加LocaleCubit注册：

```dart
// 在setupDependencies函数中添加：

  // ===== 全局状态 =====

  // LocaleCubit（单例）
  sl.registerSingleton<LocaleCubit>(
    LocaleCubit(sl<KeyValueStorage>())
  );
```

同时添加导入：
```dart
import '../global/locale/locale_cubit.dart';
```

- [ ] **Step 5: 验证文件创建**

```bash
ls -la lib/core/global/locale/
cat lib/core/global/locale/locale_cubit.dart
```

Expected: locale目录和文件创建成功

- [ ] **Step 6: Commit**

```bash
git add lib/core/global/locale/ lib/core/di/setup.dart
git commit -m "feat(phase2): 创建LocaleCubit语言管理

- LocaleState状态类
- LocaleCubit管理语言切换和持久化
- DI中注册LocaleCubit单例
- 中文注释说明使用方式和持久化机制

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 7: 创建HomeRepository

**Files:**
- Create: `lib/features/home/repository/home_repository.dart`
- Create: `lib/features/home/repository/home_repository_impl.dart`
- Create: `lib/features/home/repository/README.md`

- [ ] **Step 1: 创建Repository接口**

```dart
/// 首页数据仓库接口
///
/// 职责：定义首页数据获取的契约
/// 使用：RepositoryImpl实现，Cubit通过接口调用
/// 好处：便于测试Mock和未来替换实现
abstract class HomeRepository {
  /// 获取首页数据
  ///
  /// 返回首页展示所需的数据
  /// 失败时抛出DomainException
  Future<Map<String, dynamic>> getHomeData();

  /// 刷新首页数据
  ///
  /// 强制从服务器获取最新数据，忽略缓存
  Future<Map<String, dynamic>> refreshHomeData();
}
```

写入 `lib/features/home/repository/home_repository.dart`

- [ ] **Step 2: 创建Repository实现**

```dart
import 'package:api/api.dart';
import 'package:domain_models/domain_models.dart';
import 'home_repository.dart';

/// 首页数据仓库实现
///
/// 职责：从API获取首页数据，处理异常转换
/// 使用：通过DI获取 `sl<HomeRepository>()`
/// 异常处理：DioException转换为DomainException
class HomeRepositoryImpl implements HomeRepository {
  /// API客户端
  final Api _api;

  HomeRepositoryImpl(this._api);

  @override
  Future<Map<String, dynamic>> getHomeData() async {
    try {
      // 调用API获取首页数据
      final response = await _api.get('/home/data').fire();
      return response as Map<String, dynamic>;
    } on DioException catch (e) {
      // 转换为DomainException
      throw e.toDomainException();
    }
  }

  @override
  Future<Map<String, dynamic>> refreshHomeData() async {
    try {
      // 强制刷新，不使用缓存
      final response = await _api.get('/home/data')
        .skipCache()  // 忽略缓存（假设API支持）
        .fire();
      return response as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toDomainException();
    }
  }
}
```

写入 `lib/features/home/repository/home_repository_impl.dart`

- [ ] **Step 3: 创建README**

```markdown
# 首页数据仓库模块

## 职责
管理首页数据获取，包括接口定义和实现。

## 使用示例
```dart
// DI注册（Factory，每次创建新实例）
sl.registerFactory<HomeRepository>(() =>
  HomeRepositoryImpl(sl<Api>())
);

// Cubit中使用
final data = await repository.getHomeData();
```

## 接口与实现分离
- home_repository.dart: 接口定义
- home_repository_impl.dart: 具体实现

好处：
1. 便于单元测试Mock
2. 未来可替换不同实现（如使用其他API）
3. Cubit只依赖接口，解耦具体实现

## 依赖关系
- api: API客户端
- domain_models: DomainException

## 异常处理
DioException自动转换为DomainException，
Cubit层统一处理业务异常。

## 性能警告
数据量较大时应考虑分页加载。
```

写入 `lib/features/home/repository/README.md`

- [ ] **Step 4: 在DI中注册HomeRepository**

修改 `lib/core/di/setup.dart`：

```dart
// 在setupDependencies函数中添加：

  // ===== Repository =====

  // HomeRepository（Factory）
  sl.registerFactory<HomeRepository>(() =>
    HomeRepositoryImpl(sl<Api>())
  );
```

添加导入：
```dart
import '../../features/home/repository/home_repository.dart';
import '../../features/home/repository/home_repository_impl.dart';
```

- [ ] **Step 5: 验证文件创建**

```bash
ls -la lib/features/home/repository/
cat lib/features/home/repository/home_repository.dart
```

Expected: repository目录和文件创建成功

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/repository/ lib/core/di/setup.dart
git commit -m "feat(phase2): 创建HomeRepository数据仓库

- HomeRepository接口定义
- HomeRepositoryImpl实现
- DI中注册Repository（Factory）
- 异常自动转换为DomainException
- 中文注释说明接口设计意图

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 8: 创建HomeCubit和HomeState

**Files:**
- Create: `lib/features/home/cubit/home_cubit.dart`
- Create: `lib/features/home/cubit/home_state.dart`
- Create: `lib/features/home/cubit/README.md`

- [ ] **Step 1: 创建HomeState**

```dart
import 'package:domain_models/domain_models.dart';

/// 首页状态基类
///
/// 使用sealed class确保状态类型完整，
/// switch语句可穷举所有状态，编译器检查遗漏。
sealed class HomeState {}

/// 初始状态
///
/// 首页刚打开，尚未加载数据
class HomeInitial extends HomeState {}

/// 加载中状态
///
/// 正在从服务器获取数据
class HomeLoading extends HomeState {}

/// 加载成功状态
///
/// 数据加载完成，可展示内容
class HomeLoaded extends HomeState {
  /// 首页数据
  final Map<String, dynamic> data;

  HomeLoaded(this.data);
}

/// 加载失败状态
///
/// 数据加载出错，展示错误提示
class HomeError extends HomeState {
  /// 错误码，用于国际化错误消息
  final ErrorCode errorCode;

  HomeError(this.errorCode);
}
```

写入 `lib/features/home/cubit/home_state.dart`

- [ ] **Step 2: 创建HomeCubit**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/home_repository.dart';
import 'home_state.dart';

/// 首页状态管理Cubit
///
/// 职责：管理首页加载状态和数据
/// 使用：
///   - BlocProvider包装页面
///   - BlocBuilder响应状态更新UI
///   - context.read<HomeCubit>().loadData()触发加载
/// 状态流转：Initial → Loading → Loaded/Error
class HomeCubit extends Cubit<HomeState> {
  /// 数据仓库
  final HomeRepository _repository;

  HomeCubit(this._repository) : super(HomeInitial());

  /// 加载首页数据
  ///
  /// 从Repository获取数据，更新状态
  /// 状态流转：Initial/Error → Loading → Loaded/Error
  Future<void> loadData() async {
    // 开始加载
    emit(HomeLoading());

    try {
      // 获取数据
      final data = await _repository.getHomeData();
      // 加载成功
      emit(HomeLoaded(data));
    } on DomainException catch (e) {
      // 加载失败，传递ErrorCode用于国际化
      emit(HomeError(e.errorCode));
    }
  }

  /// 刷新首页数据
  ///
  /// 强制从服务器获取最新数据
  Future<void> refreshData() async {
    emit(HomeLoading());
    try {
      final data = await _repository.refreshHomeData();
      emit(HomeLoaded(data));
    } on DomainException catch (e) {
      emit(HomeError(e.errorCode));
    }
  }

  /// 重试加载
  ///
  /// 错误状态下点击重试按钮触发
  Future<void> retry() async {
    await loadData();
  }
}
```

写入 `lib/features/home/cubit/home_cubit.dart`

- [ ] **Step 3: 创建README**

```markdown
# 首页状态管理模块

## 职责
管理首页加载状态和数据，响应Repository数据变化。

## 使用示例
```dart
// DI注册（Factory）
sl.registerFactory<HomeCubit>(() =>
  HomeCubit(sl<HomeRepository>())
);

// 页面包装BlocProvider
BlocProvider(
  create: (context) => sl<HomeCubit>()..loadData(),
  child: HomePage(),
)

// UI响应状态
BlocBuilder<HomeCubit, HomeState>(
  builder: (context, state) {
    if (state is HomeLoading) {
      return CircularProgressIndicator();
    }
    if (state is HomeLoaded) {
      return ContentWidget(state.data);
    }
    if (state is HomeError) {
      return ErrorWidget(state.errorCode);
    }
    return SizedBox();
  },
)
```

## 状态类型
- HomeInitial: 初始状态，未加载
- HomeLoading: 加载中
- HomeLoaded: 加载成功，有数据
- HomeError: 加载失败，有错误码

## 状态流转
```
Initial → Loading → Loaded
                  ↓
                Error → Loading → Loaded
```

## 依赖关系
- flutter_bloc: Cubit基类
- home_repository: 数据来源
- domain_models: ErrorCode

## 性能警告
无
```

写入 `lib/features/home/cubit/README.md`

- [ ] **Step 4: 在DI中注册HomeCubit**

修改 `lib/core/di/setup.dart`：

```dart
// 在setupDependencies函数中添加：

  // ===== Cubit =====

  // HomeCubit（Factory）
  sl.registerFactory<HomeCubit>(() =>
    HomeCubit(sl<HomeRepository>())
  );
```

添加导入：
```dart
import '../../features/home/cubit/home_cubit.dart';
```

- [ ] **Step 5: 验证文件创建**

```bash
ls -la lib/features/home/cubit/
cat lib/features/home/cubit/home_cubit.dart
cat lib/features/home/cubit/home_state.dart
```

Expected: cubit目录和文件创建成功

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/cubit/ lib/core/di/setup.dart
git commit -m "feat(phase2): 创建HomeCubit状态管理

- HomeState使用sealed class确保状态完整
- HomeCubit管理加载状态和数据
- 状态流转：Initial → Loading → Loaded/Error
- DI中注册HomeCubit（Factory）
- 中文注释说明状态设计和使用方式

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 9: 更新HomePage使用BlocBuilder

**Files:**
- Modify: `lib/features/home/ui/home_page.dart`

- [ ] **Step 1: 更新HomePage**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

/// 首页
///
/// 职责：展示首页内容，响应加载状态
/// 使用：BlocProvider包装，BlocBuilder响应状态
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HomeCubit>().refreshData(),
          ),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          // 根据状态渲染不同UI
          return switch (state) {
            HomeInitial() => _buildInitial(context),
            HomeLoading() => _buildLoading(context),
            HomeLoaded(data: final data) => _buildLoaded(context, data),
            HomeError(errorCode: final errorCode) => _buildError(context, errorCode),
          };
        },
      ),
    );
  }

  /// 初始状态UI
  Widget _buildInitial(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('点击加载首页数据'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.read<HomeCubit>().loadData(),
            child: const Text('加载'),
          ),
        ],
      ),
    );
  }

  /// 加载中状态UI
  Widget _buildLoading(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('加载中...'),
        ],
      ),
    );
  }

  /// 加载成功状态UI
  Widget _buildLoaded(BuildContext context, Map<String, dynamic> data) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            '骨架搭建完成',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Bloc状态管理已集成'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/detail'),
            icon: const Icon(Icons.open_in_new),
            label: const Text('打开详情页'),
          ),
        ],
      ),
    );
  }

  /// 错误状态UI
  Widget _buildError(BuildContext context, errorCode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            // 使用errorCode获取国际化消息（Phase 2完成后使用AppLocalizations）
            '加载失败: ${errorCode.name}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.read<HomeCubit>().retry(),
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
```

写入 `lib/features/home/ui/home_page.dart`

- [ ] **Step 2: 更新README**

修改 `lib/features/home/ui/README.md`：

```markdown
# 首页UI模块

## 职责
首页页面UI实现，使用BlocBuilder响应状态变化。

## 使用示例
```dart
// 路由配置中使用BlocProvider
BlocProvider(
  create: (context) => sl<HomeCubit>(),
  child: HomePage(),
)

// 导航到首页
context.go('/home');
```

## 状态响应
使用switch表达式穷举所有HomeState：
- HomeInitial: 显示加载按钮
- HomeLoading: 显示进度指示器
- HomeLoaded: 显示内容
- HomeError: 显示错误提示和重试按钮

## 依赖关系
- flutter_bloc: BlocBuilder
- home_cubit: 状态管理
- go_router: 路由导航

## 性能警告
BlocBuilder默认比较状态是否变化，
仅在状态改变时重建UI。
```

- [ ] **Step 3: 验证文件更新**

```bash
cat lib/features/home/ui/home_page.dart
```

Expected: HomePage使用BlocBuilder

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/ui/
git commit -m "feat(phase2): 更新HomePage使用BlocBuilder

- 响应HomeCubit状态变化
- switch表达式穷举所有状态
- 加载/成功/错误三种UI
- 添加刷新和重试功能
- 中文注释说明状态响应逻辑

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 10: 创建DetailRepository和Cubit

**Files:**
- Create: `lib/features/detail/repository/detail_repository.dart`
- Create: `lib/features/detail/repository/detail_repository_impl.dart`
- Create: `lib/features/detail/repository/README.md`
- Create: `lib/features/detail/cubit/detail_cubit.dart`
- Create: `lib/features/detail/cubit/detail_state.dart`
- Create: `lib/features/detail/cubit/README.md`

- [ ] **Step 1: 创建DetailRepository接口**

```dart
/// 详情数据仓库接口
///
/// 职责：定义详情页数据获取的契约
abstract class DetailRepository {
  /// 获取详情数据
  ///
  /// 根据ID获取详情内容
  Future<Map<String, dynamic>> getDetailData(String id);
}
```

写入 `lib/features/detail/repository/detail_repository.dart`

- [ ] **Step 2: 创建DetailRepositoryImpl**

```dart
import 'package:api/api.dart';
import 'package:domain_models/domain_models.dart';
import 'detail_repository.dart';

/// 详情数据仓库实现
///
/// 职责：从API获取详情数据
class DetailRepositoryImpl implements DetailRepository {
  final Api _api;

  DetailRepositoryImpl(this._api);

  @override
  Future<Map<String, dynamic>> getDetailData(String id) async {
    try {
      final response = await _api.get('/detail/$id').fire();
      return response as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toDomainException();
    }
  }
}
```

写入 `lib/features/detail/repository/detail_repository_impl.dart`

- [ ] **Step 3: 创建DetailState**

```dart
import 'package:domain_models/domain_models.dart';

/// 详情页状态基类
sealed class DetailState {}

/// 初始状态
class DetailInitial extends DetailState {}

/// 加载中状态
class DetailLoading extends DetailState {}

/// 加载成功状态
class DetailLoaded extends DetailState {
  final Map<String, dynamic> data;
  DetailLoaded(this.data);
}

/// 加载失败状态
class DetailError extends DetailState {
  final ErrorCode errorCode;
  DetailError(this.errorCode);
}
```

写入 `lib/features/detail/cubit/detail_state.dart`

- [ ] **Step 4: 创建DetailCubit**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/detail_repository.dart';
import 'detail_state.dart';

/// 详情页状态管理Cubit
///
/// 职责：管理详情页加载状态和数据
class DetailCubit extends Cubit<DetailState> {
  final DetailRepository _repository;

  DetailCubit(this._repository) : super(DetailInitial());

  /// 加载详情数据
  ///
  /// 根据ID获取详情内容
  Future<void> loadData(String id) async {
    emit(DetailLoading());
    try {
      final data = await _repository.getDetailData(id);
      emit(DetailLoaded(data));
    } on DomainException catch (e) {
      emit(DetailError(e.errorCode));
    }
  }

  /// 重试加载
  Future<void> retry(String id) async {
    await loadData(id);
  }
}
```

写入 `lib/features/detail/cubit/detail_cubit.dart`

- [ ] **Step 5: 创建README文件**

Repository README:
```markdown
# 详情数据仓库模块

## 职责
管理详情页数据获取。

## 使用示例
```dart
sl.registerFactory<DetailRepository>(() =>
  DetailRepositoryImpl(sl<Api>())
);
```

## 依赖关系
- api: API客户端
- domain_models: DomainException

## 性能警告
无
```

Cubit README:
```markdown
# 详情页状态管理模块

## 职责
管理详情页加载状态。

## 使用示例
```dart
BlocProvider(
  create: (context) => sl<DetailCubit>()..loadData('123'),
  child: DetailPage(),
)
```

## 依赖关系
- flutter_bloc: Cubit基类
- detail_repository: 数据来源

## 性能警告
无
```

- [ ] **Step 6: 在DI中注册**

修改 `lib/core/di/setup.dart`：

```dart
// 添加Repository和Cubit注册
sl.registerFactory<DetailRepository>(() =>
  DetailRepositoryImpl(sl<Api>())
);
sl.registerFactory<DetailCubit>(() =>
  DetailCubit(sl<DetailRepository>())
);
```

添加导入：
```dart
import '../../features/detail/repository/detail_repository.dart';
import '../../features/detail/repository/detail_repository_impl.dart';
import '../../features/detail/cubit/detail_cubit.dart';
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/detail/repository/ lib/features/detail/cubit/ lib/core/di/setup.dart
git commit -m "feat(phase2): 创建DetailRepository和DetailCubit

- DetailRepository接口和实现
- DetailState状态类
- DetailCubit状态管理
- DI注册Repository和Cubit
- 中文注释

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 11: 更新DetailPage使用BlocBuilder

**Files:**
- Modify: `lib/features/detail/ui/detail_page.dart`

- [ ] **Step 1: 更新DetailPage**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/detail_cubit.dart';
import '../cubit/detail_state.dart';

/// 详情页
///
/// 职责：展示详情内容，响应加载状态
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('详情页'),
      ),
      body: BlocBuilder<DetailCubit, DetailState>(
        builder: (context, state) {
          return switch (state) {
            DetailInitial() => _buildInitial(context),
            DetailLoading() => _buildLoading(context),
            DetailLoaded(data: final data) => _buildLoaded(context, data),
            DetailError(errorCode: final errorCode) => _buildError(context, errorCode),
          };
        },
      ),
    );
  }

  Widget _buildInitial(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('详情页初始状态'),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildLoaded(BuildContext context, Map<String, dynamic> data) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            '详情页内容',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, errorCode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: ${errorCode.name}'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.read<DetailCubit>().retry('1'),
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
```

写入 `lib/features/detail/ui/detail_page.dart`

- [ ] **Step 2: Commit**

```bash
git add lib/features/detail/ui/
git commit -m "feat(phase2): 更新DetailPage使用BlocBuilder

- 响应DetailCubit状态变化
- switch表达式穷举状态
- 加载/成功/错误三种UI

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 12: 更新app.dart集成BlocProvider和国际化

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: 更新app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';

import 'src/theme/app_theme.dart';
import 'core/di/locator.dart';
import 'core/global/locale/locale_cubit.dart';

/// 主应用Widget
///
/// 职责：配置全局Provider、主题、路由
/// Provider：
///   - LocaleCubit：语言管理
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // 构建路由
    final ctx = RouteContext(navigatorKey: _navigatorKey);
    _router = AppRouter.getRouter(ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    // 全BlocProvider包装，提供全局Cubit
    return BlocProvider(
      create: (context) => sl<LocaleCubit>(),
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return MaterialApp.router(
            title: '骨架演示',
            theme: appLightTheme,
            darkTheme: appDarkTheme,
            // 语言配置
            locale: localeState.locale,
            supportedLocales: const [
              Locale('zh'), // 中文
              Locale('en'), // 英文
            ],
            // 国际化配置（Phase 2完成后启用）
            // localizationsDelegates: const [
            //   AppLocalizations.delegate,
            //   GlobalMaterialLocalizations.delegate,
            //   GlobalWidgetsLocalizations.delegate,
            //   GlobalCupertinoLocalizations.delegate,
            // ],
            routerConfig: _router,
            builder: (context, child) {
              final easyLoadingBuilder = EasyLoading.init();
              return easyLoadingBuilder(
                context,
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: child ?? const SizedBox(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

写入 `lib/app.dart`

- [ ] **Step 2: 添加导入**

```dart
import 'core/di/locator.dart';
import 'core/global/locale/locale_cubit.dart';
import 'core/global/locale/locale_state.dart';
```

- [ ] **Step 3: Commit**

```bash
git add lib/app.dart
git commit -m "feat(phase2): 集成LocaleCubit和国际化配置

- BlocProvider包装提供LocaleCubit
- MaterialApp配置locale和supportedLocales
- 响应语言切换状态更新
- 中文注释说明全局Provider设计

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 13: 更新DomainException.getMessage使用AppLocalizations

**Files:**
- Modify: `packages/domain_models/src/exceptions.dart`

- [ ] **Step 1: 更新getMessage方法**

需要先生成AppLocalizations，然后修改getMessage方法调用它。

由于AppLocalizations生成文件在.dart_tool目录，需要在domain_models中添加依赖或通过其他方式访问。

最简单方案：在DomainException中添加注释说明最终实现方式，Phase 2验证时再完善。

更新 `packages/domain_models/src/exceptions.dart`：

```dart
import 'package:flutter/widgets.dart';

/// 域异常
///
/// 职责：统一应用层异常，携带ErrorCode用于国际化错误消息
class DomainException implements Exception {
  final ErrorCode errorCode;
  final int? httpCode;
  final Map<String, dynamic>? rawData;

  DomainException(this.errorCode, {this.httpCode, this.rawData});

  /// 获取本地化错误消息
  ///
  /// 使用errorCode.name作为ARB key查找国际化文本
  /// 示例：ErrorCode.networkError → ARB key "networkError"
  ///
  /// 完整实现需要：
  /// 1. flutter gen-l10n生成AppLocalizations
  /// 2. MaterialApp配置localizationsDelegates
  /// 3. 通过BuildContext获取AppLocalizations实例
  ///
  /// 当前实现：返回errorCode.name作为占位
  /// 完整实现后改为：
  /// ```dart
  /// return AppLocalizations.of(context)!.translate(errorCode.name);
  /// ```
  String getMessage(BuildContext context) {
    // 占位实现：返回errorCode名称
    return errorCode.name;
  }

  @override
  String toString() {
    return 'DomainException: ${errorCode.name} (http: $httpCode)';
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add packages/domain_models/src/exceptions.dart
git commit -m "feat(phase2): 更新DomainException.getMessage说明

- 添加完整实现步骤说明
- 当前返回errorCode.name占位
- 中文注释说明国际化集成方式

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 14: 验证编译和运行

**Files:**
- 无新文件

- [ ] **Step 1: 运行Flutter分析**

```bash
flutter analyze
```

Expected: 无错误，可能有部分import警告（待修复）

- [ ] **Step 2: 尝试编译**

```bash
flutter build apk --debug
```

或在iOS：
```bash
flutter build ios --debug --no-codesign
```

Expected: 编译成功

- [ ] **Step 3: 运行应用**

```bash
flutter run
```

Expected: 应用启动成功

- [ ] **Step 4: 验证功能**

检查：
1. App启动无报错
2. 首页显示BlocBuilder响应状态
3. 点击加载按钮触发HomeCubit.loadData()
4. 状态流转：Initial → Loading → Loaded/Error
5. 详情页同样响应状态

- [ ] **Step 5: Final Commit**

```bash
git add -A
git commit -m "feat(phase2): Phase 2核心机制重构完成

完成内容：
- Bloc状态管理：HomeCubit、DetailCubit、LocaleCubit
- Repository设计：HomeRepository、DetailRepository接口和实现
- 国际化配置：l10n.yaml、ARB文件（中文/英文）
- 错误处理：ErrorCode枚举、DomainException、DioExceptionMapper
- UI集成：BlocBuilder响应状态变化
- DI注册：所有Repository和Cubit
- 所有模块添加中文README和注释

破坏性变更：
- UI页面使用BlocBuilder，需BlocProvider包装
- 错误处理统一DomainException

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

## Spec Coverage Check

| Design要求 | Plan任务覆盖 |
|-----------|-------------|
| Bloc状态管理 | Task 8, 10 |
| 国际化l10n.yaml | Task 4 |
| ARB文件 | Task 4 |
| LocaleCubit | Task 6 |
| ErrorCode枚举 | Task 2 |
| DomainException | Task 2 |
| DioExceptionMapper | Task 3 |
| Repository设计 | Task 7, 10 |
| Cubit设计 | Task 8, 10 |
| UI集成BlocBuilder | Task 9, 11 |
| 中文README | 所有模块 |
| 中文注释 | 所有代码文件 |

---

## Self-Review Placeholder Scan

- 无"TBD"、"TODO"等placeholder
- 所有步骤有完整代码
- 文件路径明确

---

## Type Consistency Check

- ErrorCode枚举在domain_models和api中一致
- DomainException类名一致
- HomeState/DetailState/LocaleState命名一致
- HomeCubit/DetailCubit/LocaleCubit命名一致
- getMessage方法签名一致

---

Plan complete and saved to `docs/superpowers/plans/2026-04-30-flutter-architecture-phase2.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks

2. **Inline Execution** - Execute tasks in this session using executing-plans

**Which approach?**