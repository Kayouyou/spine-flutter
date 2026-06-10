# component_library

共享 UI 组件库 — 主题系统、常量、国际化。

## 内部结构

```
component_library/
├── lib/
│   ├── component_library.dart             # 导出入口
│   └── src/
│       ├── theme/
│       │   ├── app_colors.dart            # 颜色 Token（支持暗色主题）
│       │   ├── radius.dart                # 圆角 Token（6 级）
│       │   ├── shadows.dart               # 阴影 Token（4 级）
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
│           ├── app_button.dart            # 统一按钮（5 变体 × 4 尺寸 × 4 图标位置）
│           ├── app_card.dart              # 卡片容器
│           ├── app_dialog.dart            # 对话框
│           ├── app_scaffold.dart          # 统一页面结构
│           ├── app_section.dart           # 内容区块
│           ├── app_text_field.dart        # 统一输入框
│           ├── app_toast.dart             # Toast 提示（EasyLoading 封装）
│           ├── custom_app_bar.dart        # 统一导航栏
│           ├── empty_state.dart           # 空状态页面
│           ├── error_card.dart            # 错误卡片
│           └── loading_button.dart        # 加载按钮（legacy）
├── l10n.yaml                              # 国际化配置
└── pubspec.yaml
```

## 依赖

| 依赖 | 用途 |
|------|------|
| `flutter_screenutil` | 屏幕适配（rpx 单位） |
| `flutter_localizations` | 国际化支持 |
| `intl` | 日期/数字格式化 |
| `flutter_easyloading` | Toast/Loading 提示 |

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

---

## 按钮系统

### AppButton

统一按钮组件，支持多种变体、尺寸和自定义样式。

#### 基础用法

```dart
// 主按钮（填充色）
AppButton.primary(label: '提交', onPressed: _submit)

// 次要按钮（描边）
AppButton.secondary(label: '取消', onPressed: _cancel)

// 危险按钮（红色）
AppButton.danger(label: '删除', onPressed: _delete)

// 纯文本按钮
AppButton.text(label: '了解更多', onPressed: _learnMore)
```

#### 变体类型

| 变体 | 工厂方法 | 用途 |
|------|----------|------|
| 填充色 | `AppButton.primary()` | 主要操作（提交、确认） |
| 描边 | `AppButton.secondary()` | 次要操作（取消、返回） |
| 红色填充 | `AppButton.danger()` | 危险操作（删除、退出） |
| 纯文本 | `AppButton.text()` | 轻量操作（链接、更多） |
| 渐变 | `AppButton.gradient()` | 视觉强调（促销、VIP） |
| 自定义 | `AppButton.custom()` | 完全自定义样式 |

#### 尺寸

```dart
AppButton.primary(
  label: '紧凑',
  size: AppButtonSize.compact,  // 高度 32
  onPressed: _fn,
)

AppButton.primary(
  label: '中等',
  size: AppButtonSize.medium,  // 高度 44（默认）
  onPressed: _fn,
)

AppButton.primary(
  label: '大号',
  size: AppButtonSize.large,  // 高度 52
  onPressed: _fn,
)

AppButton.primary(
  label: '超大',
  size: AppButtonSize.expanded,  // 高度 56
  onPressed: _fn,
)
```

#### 图标位置

```dart
// 图标在左（默认）
AppButton.primary(
  label: '提交',
  icon: Icons.check,
  iconPosition: AppButtonIconPosition.left,
  onPressed: _submit,
)

// 图标在右
AppButton.primary(
  label: '下一步',
  icon: Icons.arrow_forward,
  iconPosition: AppButtonIconPosition.right,
  onPressed: _next,
)

// 图标在上
AppButton.primary(
  label: '上传',
  icon: Icons.upload,
  iconPosition: AppButtonIconPosition.top,
  onPressed: _upload,
)

// 图标在下
AppButton.primary(
  label: '下载',
  icon: Icons.download,
  iconPosition: AppButtonIconPosition.bottom,
  onPressed: _download,
)
```

#### 宽度模式

```dart
// 自适应内容（默认）
AppButton.primary(
  label: '自适应',
  width: AppButtonWidth.flexible,
  onPressed: _fn,
)

// 固定宽度
AppButton.primary(
  label: '固定 200',
  width: AppButtonWidth.fixed,
  widthValue: 200,
  onPressed: _fn,
)

// 撑满父容器
AppButton.primary(
  label: '撑满',
  width: AppButtonWidth.expanded,
  onPressed: _fn,
)

// 响应式（平板 400，手机撑满）
AppButton.primary(
  label: '响应式',
  width: AppButtonWidth.responsive,
  onPressed: _fn,
)
```

#### 渐变背景

```dart
AppButton.gradient(
  label: '立即购买',
  gradient: LinearGradient(
    colors: [Colors.blue, Colors.purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  onPressed: _buy,
)
```

#### 完全自定义

```dart
AppButton.custom(
  label: '自定义样式',
  backgroundColor: Colors.orange,
  foregroundColor: Colors.white,
  borderRadius: 20,
  fontSize: 18,
  fontWeight: FontWeight.bold,
  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  borderColor: Colors.deepOrange,
  borderWidth: 2,
  shadow: [
    BoxShadow(
      color: Colors.orange.withOpacity(0.3),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ],
  onPressed: _custom,
)
```

#### 交互增强

```dart
// 触觉反馈
AppButton.primary(
  label: '确认',
  enableHapticFeedback: true,
  onPressed: _confirm,
)

// 防重复点击（500ms 内只能点击一次）
AppButton.primary(
  label: '提交订单',
  debounceDuration: Duration(milliseconds: 500),
  onPressed: _submitOrder,
)

// 长按回调
AppButton.primary(
  label: '删除',
  onLongPress: () => _showDeleteConfirmation(),
  onPressed: _delete,
)
```

#### 加载状态

```dart
AppButton.primary(
  label: '提交',
  isLoading: isSubmitting,
  onPressed: isSubmitting ? null : _submit,
)
```

#### 完整参数列表

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `label` | `String?` | - | 按钮文本 |
| `onPressed` | `VoidCallback?` | - | 点击回调 |
| `isLoading` | `bool` | `false` | 加载状态 |
| `size` | `AppButtonSize` | `medium` | 尺寸 |
| `icon` | `IconData?` | - | 图标 |
| `iconPosition` | `AppButtonIconPosition` | `left` | 图标位置 |
| `iconSize` | `double?` | - | 图标大小 |
| `width` | `AppButtonWidth` | `flexible` | 宽度模式 |
| `widthValue` | `double?` | - | 固定宽度值 |
| `backgroundColor` | `Color?` | - | 背景色 |
| `foregroundColor` | `Color?` | - | 前景色（文字/图标） |
| `borderRadius` | `double?` | - | 圆角半径 |
| `fontSize` | `double?` | - | 字体大小 |
| `fontWeight` | `FontWeight?` | - | 字体粗细 |
| `padding` | `EdgeInsets?` | - | 内边距 |
| `gradient` | `Gradient?` | - | 渐变背景 |
| `borderColor` | `Color?` | - | 边框颜色 |
| `borderWidth` | `double?` | - | 边框宽度 |
| `shadow` | `List<BoxShadow>?` | - | 阴影效果 |
| `enableHapticFeedback` | `bool` | `false` | 触觉反馈 |
| `debounceDuration` | `Duration?` | - | 防抖时长 |
| `onLongPress` | `VoidCallback?` | - | 长按回调 |
