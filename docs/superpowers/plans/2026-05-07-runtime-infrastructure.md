# Runtime Infrastructure Implementation Plan — .env + Sentry + Upgrader

> **For agentic workers:** Use `task` to delegate each task to a subagent. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 迁移到 `.env` 文件方式的环境配置，集成 Sentry 崩溃监控和 Upgrader 强制更新

**Architecture:** `--dart-define-from-file` 替代裸 `--dart-define`；Sentry 通过 `SentryReporter` 实现已有 `ErrorReporter` 接口；Upgrader 作为可选服务

**Tech Stack:** sentry_flutter, upgrader

---

## 文件结构

| 文件 | 类型 | 职责 |
|------|------|------|
| `env/.env.dev` | 新增 | 开发环境变量 |
| `env/.env.staging` | 新增 | 预发布环境变量 |
| `env/.env.prod` | 新增 | 生产环境变量（gitignore） |
| `lib/config.dart` | 修改 | 改为 `String.fromEnvironment` 读取 |
| `Makefile` | 修改 | dev/staging/prod 改为 `--dart-define-from-file` |
| `packages/services/error/lib/src/sentry_reporter.dart` | 新增 | SentryReporter 实现 |
| `packages/services/error/lib/error.dart` | 修改 | 导出 SentryReporter |
| `lib/main.dart` | 修改 | 初始化 Sentry + 注册 SentryReporter |
| `packages/features/feature_home/lib/ui/home_page.dart` | 修改 | 集成 UpgradeAlert |
| `.gitignore` | 修改 | 忽略 `.env.prod` |

---

### Task 1: 创建 .env 文件

- [ ] **Step 1: 创建 env/ 目录**

```bash
mkdir -p env
```

- [ ] **Step 2: 创建 `env/.env.dev`**

```env
ENV=dev
API_BASE_URL=https://dev-api.example.com
SENTRY_DSN=
APP_STORE_ID=
```

- [ ] **Step 3: 创建 `env/.env.staging`**

```env
ENV=staging
API_BASE_URL=https://staging-api.example.com
SENTRY_DSN=
APP_STORE_ID=
```

- [ ] **Step 4: 创建 `env/.env.prod`**

```env
ENV=prod
API_BASE_URL=https://api.example.com
SENTRY_DSN=
APP_STORE_ID=
```

- [ ] **Step 5: 更新 .gitignore**

在 `.gitignore` 末尾添加：

```
# Environment (production secrets excluded)
env/.env.prod
env/.env.staging
```

`.env.dev` 保留在版本控制中（无敏感信息）。

---

### Task 2: 修改 config.dart

- [ ] **Step 1: 读取当前 `lib/config.dart`**

确认当前代码结构（已知：`EnvironmentConfig` 类，`AppEnvironment` 枚举，`--dart-define=ENV`）。

- [ ] **Step 2: 改为从 `--dart-define-from-file` 读取**

将 `config.dart` 修改为：

```dart
class EnvironmentConfig {
  EnvironmentConfig._();

  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static AppEnvironment get current {
    switch (_env) {
      case 'staging':
        return AppEnvironment.staging;
      case 'prod':
        return AppEnvironment.prod;
      default:
        return AppEnvironment.dev;
    }
  }

  static bool get isDev => current == AppEnvironment.dev;
  static bool get isProd => current == AppEnvironment.prod;

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dev-api.example.com',
  );

  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static const String appStoreId = String.fromEnvironment('APP_STORE_ID');

  static bool get enableDebugLog => !isProd;

  static const int networkTimeout = 10;

  static const String _enableAuthGuardStr = String.fromEnvironment(
    'ENABLE_AUTH_GUARD',
    defaultValue: 'true',
  );
  static bool get enableAuthGuardOverride =>
      _enableAuthGuardStr.toLowerCase() == 'true';

  static bool get enableAuthGuard {
    if (isProd) return enableAuthGuardOverride;
    return true;
  }
}

class AppConfig {
  AppConfig._();
  static const String appName = 'Spine Flutter';
  static const String appVersion = '1.0.0';
  static const String appPackageName = 'com.example.myapp';
}
```

**关键变更**：所有 `fromEnvironment` 改为 `const`（编译时常量），因为 `--dart-define-from-file` 也是编译期注入。

---

### Task 3: 修改 Makefile

- [ ] **Step 1: 修改 dev/staging/prod 命令**

```makefile
dev:
	@melos bs && fvm flutter run --dart-define-from-file=env/.env.dev --debug

staging:
	@melos bs && fvm flutter run --dart-define-from-file=env/.env.staging --debug

prod:
	@melos bs && fvm flutter run --dart-define-from-file=env/.env.prod --debug

build-prod:
	@melos bs && fvm flutter build apk --dart-define-from-file=env/.env.prod --release
```

注意：此处假设 Melos 已安装（dev-tooling plan 完成后）。

---

### Task 4: 验证 .env 迁移

- [ ] **Step 1: 运行分析**

```bash
flutter analyze
```
零 error。

- [ ] **Step 2: 运行测试**

```bash
flutter test
```
全部通过。

- [ ] **Step 3: 构建验证**

```bash
make build-prod
```
构建成功。

---

### Task 5: 添加 sentry_flutter 依赖

- [ ] **Step 1: 添加到 pubspec.yaml**

```yaml
dependencies:
  sentry_flutter: ^8.13.0
```

- [ ] **Step 2: 安装**

```bash
flutter pub get
```

---

### Task 6: 实现 SentryReporter

- [ ] **Step 1: 创建 `packages/services/error/lib/src/sentry_reporter.dart`**

```dart
import 'package:sentry_flutter/sentry_flutter.dart';
import 'error_reporter.dart';

class SentryReporter implements ErrorReporter {
  @override
  Future<void> reportError(
    Object error,
    StackTrace? stack, {
    bool isFatal = false,
    Map<String, dynamic>? context,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stack,
      withScope: (scope) {
        scope.level = isFatal ? SentryLevel.fatal : SentryLevel.error;
        if (context != null) {
          scope.setContexts('extra', context);
        }
      },
    );
  }
}
```

- [ ] **Step 2: 更新 `packages/services/error/lib/error.dart` 导出**

在现有导出末尾添加：

```dart
export 'src/sentry_reporter.dart';
```

---

### Task 7: 初始化 Sentry（main.dart）

- [ ] **Step 1: 读取当前 `lib/main.dart`**

确认 runApp 入口和启动流程。

- [ ] **Step 2: 修改 main() 函数**

```dart
import 'package:sentry_flutter/sentry_flutter.dart';
import 'config.dart';
import 'package:services/error/error.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化依赖注入等启动流程
  await setupDependencies();

  // Sentry: DSN 为空时自动禁用
  await SentryFlutter.init(
    (options) {
      options.dsn = EnvironmentConfig.sentryDsn;
      options.tracesSampleRate = 0.1;
    },
    appRunner: () {
      // 注册 SentryReporter
      if (EnvironmentConfig.sentryDsn.isNotEmpty) {
        AppErrorHandler.instance.setReporter(SentryReporter());
      }
      runApp(const SpineFlutter());
    },
  );
}
```

关键点：
- `SentryFlutter.init` 包裹 `appRunner`，Sentry SDK 会自动捕获未处理异常
- `options.dsn` 空字符串 → Sentry 自动禁用，不报错
- `AppErrorHandler.setReporter(SentryReporter())` 处理业务层主动上报

---

### Task 8: 验证 Sentry 集成

- [ ] **Step 1: 代码分析**

```bash
flutter analyze
```
零 error。

- [ ] **Step 2: 测试**

```bash
flutter test
```
全部通过。

- [ ] **Step 3: 验证 DSN 为空时不崩溃**

```bash
make dev
```
App 应正常启动，无 Sentry 相关报错（DSN 为空时自动禁用）。

---

### Task 9: 添加 upgrader 依赖

- [ ] **Step 1: 添加到 pubspec.yaml**

```yaml
dependencies:
  upgrader: ^10.3.0
```

- [ ] **Step 2: 安装**

```bash
flutter pub get
```

---

### Task 10: 集成 Upgrader 到 HomePage

- [ ] **Step 1: 读取 `packages/features/feature_home/lib/ui/home_page.dart`**

确认当前页面结构（已知使用 AppScaffold）。

- [ ] **Step 2: 修改 HomePage**

```dart
import 'package:upgrader/upgrader.dart';
import 'package:spine_flutter/config.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        appStoreId: EnvironmentConfig.appStoreId.isNotEmpty
            ? EnvironmentConfig.appStoreId
            : null,
        debugLogging: EnvironmentConfig.isDev,
      ),
      child: AppScaffold(
        title: '首页',
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) { /* ... 现有代码不变 ... */ },
        ),
      ),
    );
  }
}
```

**仅包裹**：`UpgradeAlert` 包裹现有 `AppScaffold`，内部逻辑不变。

---

### Task 11: 创建 ForceUpdateChecker 服务（可选）

- [ ] **Step 1: 创建 `lib/core/services/force_update_checker.dart`**

```dart
import 'package:upgrader/upgrader.dart';
import 'package:spine_flutter/config.dart';

class ForceUpdateChecker {
  static final _upgrader = Upgrader(
    appStoreId: EnvironmentConfig.appStoreId.isNotEmpty
        ? EnvironmentConfig.appStoreId
        : null,
  );

  /// 在任意页面调用以手动触发更新检查
  static Future<UpgradeAlert?> check({required BuildContext context}) async {
    final messages = await _upgrader.getMessages();
    if (messages != null) {
      return UpgradeAlert(
        upgrader: _upgrader,
        child: const SizedBox.shrink(),
      );
    }
    return null;
  }
}
```

此服务让任意页面都能主动调用更新检查，不只是首页。

---

### Task 12: 全量验证

- [ ] **Step 1: 安装所有依赖**

```bash
flutter pub get
```

- [ ] **Step 2: 代码分析**

```bash
flutter analyze
```
零 error。

- [ ] **Step 3: 运行测试**

```bash
flutter test
```
全部通过。

- [ ] **Step 4: 环境切换测试**

```bash
make dev     # 开发环境
make staging # 预发布环境  
make build-prod # 生产构建
```
所有命令正常执行。

---

### Task 13: 提交

```bash
git add env/ lib/config.dart lib/main.dart Makefile .gitignore pubspec.yaml \
  packages/services/error/ packages/features/feature_home/lib/ui/home_page.dart \
  lib/core/services/force_update_checker.dart
git commit -m "feat: add .env configuration, Sentry monitoring, and version update checker

- env/: .env.dev/.staging/.prod with dart-define-from-file
- config.dart: migrated to String.fromEnvironment for all configs
- Sentry: SentryReporter implements ErrorReporter, auto-disabled when DSN empty
- Upgrader: UpgradeAlert on HomePage, ForceUpdateChecker service
- Makefile: dev/staging/prod use --dart-define-from-file"
```
