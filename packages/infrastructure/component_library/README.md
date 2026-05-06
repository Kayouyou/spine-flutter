# component_library

共享 UI 组件库 — 主题系统、常量、国际化。

## 内部结构

```
component_library/
├── lib/
│   ├── component_library.dart             # 导出入口
│   └── src/
│       ├── theme/
│       │   ├── ovs_theme.dart             # OVSTheme Widget（InheritedWidget）
│       │   ├── ovs_theme_data.dart        # 主题数据（颜色、文本样式）
│       │   ├── font_size.dart             # 字体大小常量
│       │   └── spacing.dart               # 间距常量
│       ├── constants/
│       │   ├── api_constants.dart         # API 相关常量
│       │   ├── app_constants.dart         # 应用通用常量
│       │   └── cache_constants.dart       # 缓存相关常量
│       ├── l10n/
│       │   ├── component_library_localizations.dart        # 国际化生成文件
│       │   └── component_library_localizations_zh.dart     # 中文本地化
│       └── widgets/
│           ├── custom_app_bar.dart   # 统一导航栏 widget
│           └── app_scaffold.dart      # 统一页面结构 widget
├── l10n.yaml                              # 国际化配置
└── pubspec.yaml
```

## 依赖

| 依赖 | 用途 |
|------|------|
| `flutter_screenutil` | 屏幕适配（rpx 单位） |
| `flutter_localizations` | 国际化支持 |
| `intl` | 日期/数字格式化 |

## 主题系统

### OVSTheme

```dart
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final theme = OVSTheme.of(context);
    return Container(
      color: theme.colors.background,
      child: Text('Hello', style: theme.textStyles.body),
    );
  }
}
```

### OVSThemeData

主题数据类，通过 `OVSTheme.of(context)` 获取：
- `colors` — 颜色定义
- `textStyles` — 文本样式
- `spacing` — 间距值
- `fontSizes` — 字体大小

### 字体大小 & 间距

```dart
import 'package:component_library/component_library.dart';

// 间距
final padding = AppSpacing.md;  // 8, 12, 16, 24, 32

// 字体大小（适配 ScreenUtil）
final fontSize = AppFontSizes.body;  // s, m, body, title, subtitle
```

## 常量

```dart
// API 常量
ApiConstants.baseUrl;
ApiConstants.timeout;

// 应用常量
AppConstants.appName;
AppConstants.defaultPageSize;

// 缓存常量
CacheConstants.maxAge;
CacheConstants.cacheKey;
```

## 国际化

支持中文，通过 ARB 文件定义：

```
lib/src/l10n/
├── messages_zh.arb   # 中文模板
└── component_library_localizations*.dart  # 生成文件
```

**注意**：`l10n.yaml` 中 `synthetic-package: false`，生成文件在包内直接引用。修改 ARB 后运行 `fvm flutter pub get` 重新生成。

## 使用

```dart
import 'package:component_library/component_library.dart';

// 主题
final theme = OVSTheme.of(context);
Container(color: theme.colors.primary);

// 间距
SizedBox(height: AppSpacing.md);

// 字体
Text('标题', style: TextStyle(fontSize: AppFontSizes.title));
```

## Widgets

### CustomAppBar

统一导航栏 widget，所有页面复用。

```dart
import 'package:component_library/component_library.dart';

CustomAppBar(
  title: '首页',
  actions: [IconButton(icon: Icon(Icons.refresh), onPressed: () {})],
  showBackButton: true,
)
```

参数：
- `title` — 标题文本（必需）
- `actions` — AppBar 右侧按钮列表（可选）
- `showBackButton` — 是否显示返回按钮（默认 true）
- `leading` — 自定义 leading widget（可选，覆盖 showBackButton）
- `elevation` — 阴影高度（默认 0）
- `backgroundColor` — AppBar 背景色（可选）

---

### AppScaffold

统一页面结构 widget，封装 Scaffold + CustomAppBar。

```dart
// 简单模式（传 title）
AppScaffold(
  title: '首页',
  body: Center(child: Text('内容')),
  actions: [IconButton(...)],
)

// 高级模式（传自定义 appBar）
AppScaffold(
  appBar: CustomAppBar(title: '自定义标题', ...),
  body: Center(child: Text('内容')),
)
```

参数：
- `title` — 标题（简单模式，与 appBar 二选一）
- `appBar` — 自定义 AppBar widget（高级模式）
- `body` — 页面内容（必需）
- `actions` — AppBar 右侧按钮（仅在简单模式生效）
- `showBackButton` — 是否显示返回按钮（默认 true）
- `floatingActionButton` — FAB（可选）
- `backgroundColor` — Scaffold 背景色（可选）
- `bottomNavigationBar` — 底部导航栏（可选）
- `resizeToAvoidBottomInset` — 键盘弹出时是否调整布局（可选）

**使用场景**：
- 简单页面：传 title（80% 页面）
- 复杂页面：传 appBar + BlocBuilder（动态 AppBar）
- 需生命周期：叠加 LifecycleMixin（单独 mixin）
