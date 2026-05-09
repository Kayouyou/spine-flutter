# lib/src/（主应用共享代码）

## 职责

存放主应用级别的共享代码，不属于任何 feature 包。

## 目录结构

```
lib/src/
├── theme/         # 主题系统（颜色、主题工厂）
│   ├── app_colors.dart         # ThemeExtension + context.colors 扩展
│   └── app_theme.dart          # 亮色/深色主题工厂
└── ui/            # 共享页面（临时示例）
    └── tab_b_page.dart
```

## 与 packages 的区别

| 维度 | `lib/src/` | `packages/` |
|------|------------|-------------|
| 可见性 | 仅主应用内部 | 可被多包引用 |
| 复用范围 | 不跨包引用 | 基础设施/服务/功能模块 |
| 示例 | theme、共享页面 | api、routing、feature_home |

## 主题系统

使用 `ThemeExtension` + `context.colors` 方案。详细文档：[lib/src/theme/README.md](theme/README.md)
