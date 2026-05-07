# Asset Bootstrapping — flutter_gen 预备 + launcher_icons + native_splash

**日期**: 2026-05-07  
**状态**: 设计确认  
**范围**: 建立 assets 目录结构 + 集成图标/启动页自动生成工具

---

## 背景

当前项目：
- 无 `assets/` 目录，无任何资源文件
- 无 `flutter_launcher_icons` 或 `flutter_native_splash` 配置
- 换图标需要手动切图 → iOS + Android 多尺寸手工操作

---

## 方案

### 1. Assets 目录结构

```
assets/
├── images/          # 图片资源（空目录，预留）
├── fonts/           # 字体资源（空目录，预留）
├── icon.png         # 1024x1024 图标源图（占位）
└── splash.png       # 启动页源图（占位）
```

`pubspec.yaml` 添加资产声明：
```yaml
flutter:
  assets:
    - assets/images/
    - assets/fonts/
```

### 2. flutter_gen — 将来再加

当前不安装 `flutter_gen` 包（项目尚无资源文件）。待项目有实际资源需求时再引入。但 `assets/` 目录和 `pubspec.yaml` assets 声明预先建好，为 launcher_icons 和 native_splash 提供基础。

### 3. flutter_launcher_icons

#### 3.1 安装

```yaml
# pubspec.yaml dev_dependencies
dev_dependencies:
  flutter_launcher_icons: ^0.14.0
```

#### 3.2 配置（pubspec.yaml 底部）

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon.png"
```

#### 3.3 使用

```bash
dart run flutter_launcher_icons
```

替换 `assets/icon.png` 后重新运行即可换图标。

### 4. flutter_native_splash

#### 4.1 安装

```yaml
# pubspec.yaml dev_dependencies
dev_dependencies:
  flutter_native_splash: ^2.4.0
```

#### 4.2 配置（pubspec.yaml 底部）

```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/splash.png
  android: true
  ios: true
```

#### 4.3 使用

```bash
dart run flutter_native_splash:create
```

---

## 验收标准

- [ ] `assets/` 目录结构存在（含占位 icon.png, splash.png）
- [ ] `pubspec.yaml` 包含 assets 声明
- [ ] `flutter_launcher_icons` 安装 + 配置，运行不报错
- [ ] `flutter_native_splash` 安装 + 配置，运行不报错
- [ ] `flutter analyze` 零 error
- [ ] 现有测试全部通过

---

## 不涉及

- 不安装 flutter_gen
- 不提供实际图标/启动页图片（仅占位）
- 不修改业务逻辑
