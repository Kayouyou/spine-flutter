# 国际化模块

## 职责
管理应用多语言支持，提供统一的本地化文本。

## 使用方式

### 方式1：flutter_intl插件（推荐）

1. VS Code/Android Studio安装flutter_intl插件
2. 打开ARB文件编辑，插件自动生成代码
3. 生成文件位于 `.dart_tool/flutter_gen/gen_l10n/`

### 方式2：命令行生成

```bash
flutter gen-l10n
```

### 方式3：手动配置（本项目）

在 `l10n.yaml` 中配置：
- arb-dir: ARB文件目录
- template-arb-file: 主模板（中文）
- output-localization-file: 输出文件名
- output-class-name: 输出类名

## 使用示例
```dart
// 获取本地化文本
final text = AppLocalizations.of(context).networkError;

// 在Widget中使用
Text(AppLocalizations.of(context).appName)
```

## ARB文件结构
- app_zh.arb: 中文模板（主语言）
- app_en.arb: 英文翻译
- 其他语言添加对应ARB文件

## ErrorCode国际化
每个ErrorCode.name对应ARB中的一个key：
- ErrorCode.networkError → "networkError": "网络连接失败"
- ErrorCode.tokenExpired → "tokenExpired": "登录已过期"

## 依赖关系
- intl: ^0.19.0
- flutter_localizations: sdk

## 性能警告
无
