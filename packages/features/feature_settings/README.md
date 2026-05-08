# feature_settings 包

设置页面功能模块 — UI extraction from routing.

## 为什么独立包

- 遵循 feature-first 架构
- routing 包只负责路由导航，不应包含 UI
- Settings 可独立迭代（未来可添加持久化、国际化等）

## 内部结构

```
feature_settings/
├── pubspec.yaml
├── lib/
│   ├── feature_settings.dart       # 导出入口
│   └── src/
│       ├── ui/
│       │   └── settings_page.dart  # SettingsPage + _InfoTile
│       └── di/
│           └── setup.dart          # 空（纯 UI，无 DI）
└── test/
    └── settings_page_test.dart
```

## 使用

```dart
import 'package:feature_settings/feature_settings.dart';

// 在路由中使用
GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsPage(),
)
```

## 未来扩展

- SettingsCubit：持久化设置状态
- SettingsRepository：读写 SharedPreferences
- 多语言切换、主题切换等设置项