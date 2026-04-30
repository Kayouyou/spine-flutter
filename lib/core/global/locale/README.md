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
