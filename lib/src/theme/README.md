# 主题系统（Theme）

## 目录结构

```
lib/src/theme/
├── app_colors.dart    # 颜色主题扩展（ThemeExtension）
└── app_theme.dart     # 主题工厂（亮色/深色）
```

## 架构设计

本项目使用 Flutter 内置的 **ThemeExtension** 方案管理主题颜色，替代旧的 InheritedWidget 方案。

```
┌─────────────────────────────────────┐
│  app_theme.dart                     │
│  appLightTheme / appDarkTheme       │
│  .copyWith(extensions: [AppColors]) │
└──────────────┬──────────────────────┘
               │ 注册到 MaterialApp
               ▼
┌─────────────────────────────────────┐
│  app_colors.dart                    │
│  class AppColors extends            │
│    ThemeExtension<AppColors>         │
│  ┌─────────────┬─────────────────┐  │
│  │ light (浅色)│ dark (深色)     │  │
│  └─────────────┴─────────────────┘  │
└──────────────┬──────────────────────┘
               ▼
┌─────────────────────────────────────┐
│  extension AppColorsExtension       │
│  on BuildContext                    │
│  context.colors.primary             │
└─────────────────────────────────────┘
```

## 使用方式

### 在 Widget 中访问颜色

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 推荐：通过 BuildContext 扩展访问
    final colors = context.colors;
    
    return Container(
      color: colors.primary,
      child: Text(
        '标题',
        style: TextStyle(color: colors.textPrimaryLight),
      ),
    );
  }
}
```

### 可用颜色属性

| 属性 | 亮光模式 | 深色模式 | 用途 |
|------|---------|---------|------|
| `primary` | `#1976D2` | `#42A5F5` | 主色调，按钮/链接 |
| `secondary` | `#26A69A` | `#4DB6AC` | 次色调 |
| `success` | `#4CAF50` | `#81C784` | 成功提示 |
| `warning` | `#FF9800` | `#FFB74D` | 警告提示 |
| `error` | `#F44336` | `#E57373` | 错误/删除 |
| `info` | `#2196F3` | `#64B5F6` | 信息提示 |
| `backgroundLight` | `#F5F5F5` | `#1E1E1E` | 亮色背景 |
| `backgroundDark` | `#121212` | `#000000` | 暗色背景 |
| `textPrimaryLight` | `#212121` | `#E0E0E0` | 亮色主体文字 |
| `textPrimaryDark` | `#E0E0E0` | `#FFFFFF` | 暗色主体文字 |
| `border` | `#E0E0E0` | `#424242` | 边框颜色 |
| `divider` | `#EEEEEE` | `#303030` | 分割线颜色 |

## 如何新增或修改颜色

### 步骤 1：在 AppColors 类中添加属性

```dart
// lib/src/theme/app_colors.dart

class AppColors extends ThemeExtension<AppColors> {
  // 新增属性
  final Color customColor;
  
  const AppColors({
    required this.customColor,  // 新增
    // ... 其他现有属性
  });
  
  // 在 light/dark 静态常量中添加对应值
  static const AppColors light = AppColors(
    customColor: Color(0xFFABCDEF),  // 亮色模式颜色
    // ...
  );
  
  static const AppColors dark = AppColors(
    customColor: Color(0xFF123456),  // 暗色模式颜色
    // ...
  );
}
```

### 步骤 2：更新 copyWith 和 lerp 方法

```dart
@override
ThemeExtension<AppColors> copyWith({
  Color? customColor,  // 新增
  // ... 其他属性
}) {
  return AppColors(
    customColor: customColor ?? this.customColor,  // 新增
    // ...
  );
}

@override
ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
  if (other is! AppColors) return this;
  return AppColors(
    customColor: Color.lerp(customColor, other.customColor, t)!,  // 新增
    // ...
  );
}
```

### 步骤 3：使用新颜色

```dart
Container(color: context.colors.customColor)
```

## 暗黑模式适配

系统自动适配暗黑模式，无需手动监听。

```dart
// app.dart 中的配置（已存在，无需修改）
MaterialApp(
  theme: appLightTheme,      // 亮色主题
  darkTheme: appDarkTheme,   // 暗色主题
  themeMode: ThemeMode.system, // 跟随系统切换
)
```

业务页面通过 `context.colors` 访问的颜色会**自动跟随系统主题切换**。

## 设计原则

1. **所有颜色集中在 AppColors 类中管理**，不在业务页面硬编码颜色
2. **亮色/暗色成对设计**，每个颜色都有两个模式的值
3. **通过 context.colors 访问**，不直接引用 AppColors.light/dark
4. **语义化命名**：使用 primary/success/error 等用途命名，而非 blue/red/green

## 历史说明

- 旧的 `OVSTheme`（InheritedWidget方案）已于 2026-05-09 删除
- `spacing.dart` 和 `font_size.dart` 常量保留在 `component_library/theme/`
