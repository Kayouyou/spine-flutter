# Runtime Infrastructure — .env + Sentry + Upgrader

**日期**: 2026-05-07  
**状态**: 设计确认  
**范围**: 环境密钥管理、崩溃监控、强制更新

---

## 背景

当前项目：
- 环境配置通过 `--dart-define=ENV=xxx`，密钥在命令行裸传
- ErrorReporter 接口已预留，但只有 `ConsoleReporter`（debugPrint），无线上监控
- 无版本更新检查机制

---

## 方案

### 1. .env 环境密钥

#### 1.1 从 `--dart-define` 迁移到 `--dart-define-from-file`

创建 3 个环境文件：

```
env/
├── .env.dev        # 开发环境
├── .env.staging    # 预发布环境
└── .env.prod       # 生产环境
```

示例 `.env.dev`：
```env
ENV=dev
API_BASE_URL=https://dev-api.example.com
SENTRY_DSN=
APP_STORE_ID=
```

#### 1.2 config.dart 改动

```dart
class EnvironmentConfig {
  static const String env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String appStoreId = String.fromEnvironment('APP_STORE_ID');
}
```

#### 1.3 Makefile 与 CI 改动

```makefile
dev:  get && fvm flutter run --dart-define-from-file=env/.env.dev --debug
staging: get && fvm flutter run --dart-define-from-file=env/.env.staging --debug
prod: get && fvm flutter run --dart-define-from-file=env/.env.prod --debug
```

CI 中用 GitHub Secrets 注入生产环境变量。

#### 1.4 .gitignore

```
env/.env.prod      # 生产密钥不入库
env/.env.staging   # 可选：预发布密钥也不入库
```

`.env.dev` 可以入库（无敏感信息，方便新成员上手）。

---

### 2. Sentry 崩溃监控

#### 2.1 安装

```yaml
# pubspec.yaml dependencies
dependencies:
  sentry_flutter: ^8.0.0
```

#### 2.2 SentryReporter 实现

```dart
// packages/services/error/lib/src/sentry_reporter.dart
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
        if (context != null) scope.setContexts('extra', context);
      },
    );
  }
}
```

#### 2.3 初始化

```dart
// main.dart
void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = EnvironmentConfig.sentryDsn;
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(const SpineFlutter()),
  );
}
```

DSN 为空 → Sentry 自动禁用，不报错。

#### 2.4 ErrorReporter 注册

```dart
if (EnvironmentConfig.sentryDsn.isNotEmpty) {
  AppErrorHandler.instance.setReporter(SentryReporter());
}
```

---

### 3. Upgrader 强制更新

#### 3.1 安装

```yaml
# pubspec.yaml dependencies
dependencies:
  upgrader: ^10.0.0
```

#### 3.2 使用

```dart
// 在 HomePage 或任意页面：
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        appStoreId: EnvironmentConfig.appStoreId.isNotEmpty
            ? EnvironmentConfig.appStoreId
            : null,
      ),
      child: AppScaffold(title: '首页', body: ...),
    );
  }
}
```

或创建独立服务：

```dart
class ForceUpdateChecker {
  static final _upgrader = Upgrader(
    appStoreId: EnvironmentConfig.appStoreId.isNotEmpty
        ? EnvironmentConfig.appStoreId
        : null,
  );

  static Future<void> check() async {
    await _upgrader.initialize();
  }
}
```

---

## 验收标准

### .env
- [ ] `env/` 目录存在 `.env.dev`、`.env.staging`、`.env.prod`
- [ ] `config.dart` 从 `--dart-define-from-file` 读取
- [ ] `make dev/staging/prod` 正确传递环境文件
- [ ] `.env.prod` 在 `.gitignore` 中

### Sentry
- [ ] `sentry_flutter` 安装
- [ ] `SentryReporter` 实现 `ErrorReporter` 接口
- [ ] `main.dart` 初始化 Sentry（DSN 为空时自动禁用）
- [ ] `flutter analyze` 零 error
- [ ] `flutter test` 全部通过

### Upgrader
- [ ] `upgrader` 安装
- [ ] 首页集成 `UpgradeAlert`
- [ ] `ForceUpdateChecker` 服务可独立调用
- [ ] `flutter analyze` 零 error
- [ ] `flutter test` 全部通过

---

## 不涉及

- 不提供真实的 Sentry DSN、App Store ID
- 不修改现有 ErrorReporter 接口
- 不修改业务逻辑
