# locale 包

多语言/国际化服务 — 管理应用语言切换。

## 内部结构

```
locale/
├── lib/
│   ├── locale.dart               # 导出入口
│   └── src/
│       ├── locale_cubit.dart     # LocaleCubit（语言状态管理）
│       └── locale_state.dart     # LocaleState（当前语言）
└── pubspec.yaml
```

## 职责

- 管理应用当前语言（zh / en）
- 持久化语言选择到 `KeyValueStorage`
- 通过 `LocaleCubit` 通知 UI 刷新

## 使用

```dart
import 'package:locale/locale.dart';

// 在主 DI 设置中调用
setupLocale(sl);

// 切换语言
sl<LocaleCubit>().switchTo(Locale('en'));

// 监听语言变化
BlocBuilder<LocaleCubit, LocaleState>(
  builder: (context, state) {
    return MaterialApp.router(
      locale: state.locale,
      supportedLocales: const [Locale('zh'), Locale('en')],
      ...
    );
  },
);
```

## 注册方式

- LocaleCubit: **Singleton**（全局唯一，需要注入 `KeyValueStorage`）
