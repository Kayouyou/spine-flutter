# hydrated_bloc 迁移指南

## 适用场景判断

### 适用场景
- 用户偏好（语言、主题）
- 认证状态（Token 过期需额外处理）
- 简单配置

### 不适用场景
- 大数据列表（性能差）
- 需加密/TTL/迁移
- 跨 isolate 共享

## 迁移步骤

### 1. 加依赖

**pubspec.yaml:**
```yaml
dependencies:
  hydrated_bloc: ^9.1.0

dev_dependencies:
  freezed: ^2.4.0
  build_runner: ^2.4.0
```

### 2. 初始化 HydratedStorage

**lib/core/startup/launcher.dart:**

必须在 `setupDependencies()` 前初始化：

```dart
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

Future<void> launch(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();

  // HydratedBloc 存储（在任何 Cubit 创建前）
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

  setupDependencies();  // LocaleCubit 在这里创建
  runApp(app);
}
```

### 3. Cubit 改 HydratedCubit

**改前（普通 Cubit）:**
```dart
class LocaleCubit extends Cubit<LocaleState> {
  final KeyValueStorage _storage;

  LocaleCubit(this._storage) : super(LocaleState(locale: Locale('zh'))) {
    _loadSavedLocale();  // 异步加载，可能闪烁
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale = await _storage.getString('app_locale');
    if (savedLocale != null) {
      emit(LocaleState(locale: Locale(savedLocale)));
    }
  }

  Future<void> setLocale(Locale locale) async {
    await _storage.putString('app_locale', locale.languageCode);
    emit(LocaleState(locale: locale));
  }
}
```

**改后（HydratedCubit）:**
```dart
import 'package:hydrated_bloc/hydrated_bloc.dart';

class LocaleCubit extends HydratedCubit<LocaleState> {
  static const String _storagePrefix = 'LocaleCubit';

  LocaleCubit() : super(LocaleState(locale: Locale('zh')));

  @override
  String get storagePrefix => _storagePrefix;

  @override
  LocaleState? fromJson(Map<String, dynamic> json) {
    final localeCode = json['locale'] as String?;
    if (localeCode != null) {
      return LocaleState(locale: Locale(localeCode));
    }
    return null;
  }

  @override
  Map<String, dynamic>? toJson(LocaleState state) {
    return {'locale': state.locale.languageCode};
  }

  Future<void> setLocale(Locale locale) async {
    emit(LocaleState(locale: locale));  // 自动持久化
  }
}
```

### 4. State 改 freezed sealed

**改前（Equatable）:**
```dart
class LocaleState extends Equatable {
  final Locale locale;

  LocaleState({required this.locale});

  LocaleState copyWith({Locale? locale}) {
    return LocaleState(locale: locale ?? this.locale);
  }

  @override
  List<Object?> get props => [locale];
}
```

**改后（freezed）:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_state.freezed.dart';

@freezed
class LocaleState with _$LocaleState {
  const factory LocaleState({
    required Locale locale,
  }) = _LocaleState;
}
```

### 5. 加 storagePrefix 硬编码

```dart
class LocaleCubit extends HydratedCubit<LocaleState> {
  static const String _storagePrefix = 'LocaleCubit';

  @override
  String get storagePrefix => _storagePrefix;
}
```

**原因:** 代码混淆后 `runtimeType` 可能变化，硬编码保证键名稳定。

### 6. DI 注册改

**改前:**
```dart
sl.registerSingleton<LocaleCubit>(
  LocaleCubit(sl<KeyValueStorage>()),
);
```

**改后:**
```dart
sl.registerSingleton<LocaleCubit>(LocaleCubit());
```

不再注入 `KeyValueStorage`。

### 7. 代码生成

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 注意事项

### storagePrefix 混淆

**问题:** 代码压缩后 `runtimeType` 变化，导致缓存 key 不匹配。

**解决:** 硬编码 `storagePrefix` 字符串：

```dart
static const String _storagePrefix = 'LocaleCubit';
@override
String get storagePrefix => _storagePrefix;
```

### Web 部署缓存清空

**问题:** 浏览器缓存清空后状态丢失。

**解决:** 文档说明，勿依赖持久化。考虑 fallback 策略。

### schema 变更

**问题:** 无内置迁移 API。

**解决:** 在 `fromJson` 中手动处理版本兼容：

```dart
@override
LocaleState? fromJson(Map<String, dynamic> json) {
  // 版本 1: 仅 locale 字段
  // 版本 2: locale + fallbackLocale
  final version = json['version'] as int? ?? 1;

  if (version == 1) {
    final localeCode = json['locale'] as String?;
    if (localeCode != null) {
      return LocaleState(locale: Locale(localeCode));
    }
  }

  return null;
}

@override
Map<String, dynamic>? toJson(LocaleState state) {
  return {
    'version': 2,
    'locale': state.locale.languageCode,
  };
}
```

### 大状态性能

**问题:** 大状态 JSON 序列化阻塞主线程。

**解决:** LocaleState 仅 1 字段，无风险。大状态避免用 HydratedCubit。

## 常见问题排查

### 状态闪烁？

**症状:** App 启动瞬间显示默认语言，然后跳到上次选择。

**原因:** HydratedStorage 初始化在 Cubit 创建之后。

**解决:** 确保 HydratedStorage init 在 `setupDependencies()` 前：

```dart
HydratedBloc.storage = await HydratedStorage.build(...);
setupDependencies();  // LocaleCubit 创建
```

### 数据丢失？

**症状:** 重启后语言未恢复。

**原因:** storagePrefix 不一致。

**解决:** 检查 storagePrefix 是否硬编码且未改动。

### 状态未恢复？

**症状:** fromJson 返回正确值，但状态仍是默认。

**原因:** HydratedCubit 构造函数的 `super()` 状态覆盖了 fromJson 恢复。

**解决:** 构造函数传默认值，fromJson 会自动恢复：

```dart
LocaleCubit() : super(LocaleState(locale: Locale('zh')));  // 默认
// fromJson 自动恢复缓存值
```

## 参考资源

- [hydrated_bloc 官方文档](https://pub.dev/packages/hydrated_bloc)
- [freezed 官方文档](https://pub.dev/packages/freezed)
- [bloc 官方文档](https://bloclibrary.dev)
