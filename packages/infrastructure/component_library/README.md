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
│       └── l10n/
│           ├── component_library_localizations.dart        # 国际化生成文件
│           └── component_library_localizations_zh.dart     # 中文本地化
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
