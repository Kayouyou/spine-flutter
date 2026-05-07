# 国际化模块 (l10n)

管理应用多语言支持。主语言中文 (zh)，英文 (en) 为第二语言。

## 快速操作

### 新增字符串

1. 在 `app_zh.arb` 添加 key：
```json
"authLoginButton": "登录",
"@authLoginButton": { "description": "登录按钮文本" }
```
2. 在 `app_en.arb` 添加对应翻译：
```json
"authLoginButton": "Login"
```
3. 生成代码：`flutter gen-l10n`
4. 使用：`Text(context.l10n.authLoginButton)`

### 修改字符串

直接改 `.arb` 中的值，然后 `flutter gen-l10n`。

### 删除字符串

在 `app_zh.arb` 和 `app_en.arb` 中同时删除 key 及其 `@key` 元数据。`flutter gen-l10n`。

### 检查翻译完整性

```bash
./scripts/check_l10n.sh
```
输出 `✅ 所有 ARB 文件 key 与模板一致` 即通过。

## Widget 中使用

### 推荐：context.l10n 扩展

```dart
import 'package:my_app/core/l10n/l10n_ext.dart';

Text(context.l10n.retry)
Text(context.l10n.homeTitle)
```

对比 `AppLocalizations.of(context)!.retry`（41 字符）→ `context.l10n.retry`（24 字符），短 40%。

## 命名规范

格式：`模块_元素`，如 `networkError`、`authLoginButton`。

## 文件结构
```
lib/core/l10n/
├── app_zh.arb           # 主模板（中文）
├── app_en.arb           # 英文
├── l10n_ext.dart        # context.l10n 扩展
├── generated/           # 自动生成，勿手动编辑
└── README.md
```

## 添加新语言

1. 创建 `app_ja.arb`，复制 `app_en.arb` 全部 key
2. 逐条翻译，`flutter gen-l10n`
3. `app.dart` 的 `supportedLocales` 加 `Locale('ja')`

## CI 集成

pre-commit hook 或 CI 中加入 `./scripts/check_l10n.sh`。
