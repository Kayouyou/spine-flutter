# Asset Bootstrapping Implementation Plan

> **For agentic workers:** Use `task` to delegate each task to a subagent. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 assets 目录结构，集成 flutter_launcher_icons 和 flutter_native_splash 实现一键换图标/启动页

**Architecture:** `assets/` 目录存放源图，`flutter_launcher_icons` 和 `flutter_native_splash` 通过 pubspec.yaml 配置自动生成双端资源

**Tech Stack:** flutter_launcher_icons, flutter_native_splash

---

## 文件结构

| 文件 | 类型 | 职责 |
|------|------|------|
| `assets/` | 新增目录 | 资源根目录 |
| `assets/images/` | 新增目录 | 图片资源 |
| `assets/fonts/` | 新增目录 | 字体资源 |
| `assets/icon.png` | 新增 | 1024x1024 图标占位图 |
| `assets/splash.png` | 新增 | 启动页占位图 |
| `pubspec.yaml` | 修改 | 添加 assets 声明 + launcher_icons/native_splash 配置 + dev_dependencies |
| `lib/theme/` | 不修改 | 不涉及 |

---

### Task 1: 创建 Assets 目录 + 占位图

- [ ] **Step 1: 创建目录**

```bash
mkdir -p assets/images assets/fonts
```

- [ ] **Step 2: 生成占位图标（1024x1024 纯色 PNG）**

使用 Python 或 ImageMagick 生成占位图。如果没有这些工具，创建一个最小有效 PNG 文件。

```bash
# 如果安装了 ImageMagick:
convert -size 1024x1024 xc:'#4fc3f7' assets/icon.png
convert -size 1024x1024 xc:'#ffffff' assets/splash.png

# 如果未安装，用 Dart 生成:
dart run -e '
import "dart:io";
import "dart:typed_data";

// 最小 1x1 蓝色 PNG (valid PNG header)
final png = base64Decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==");
File("assets/icon.png").writeAsBytesSync(png);
File("assets/splash.png").writeAsBytesSync(png);
'
```

**备选方案**：手动放一张 1024x1024 的 PNG 到 `assets/icon.png` 和 `assets/splash.png`（任意内容，后续替换）。

- [ ] **Step 3: 验证目录结构**

```bash
tree assets/
# assets/
# ├── fonts/
# ├── icon.png
# ├── images/
# └── splash.png
```

---

### Task 2: 修改 pubspec.yaml — 添加 assets 声明

- [ ] **Step 1: 在 `pubspec.yaml` 的 `flutter:` 部分添加 assets**

找到 `flutter:` 区块，添加：

```yaml
flutter:
  assets:
    - assets/images/
    - assets/fonts/
```

注意：`icon.png` 和 `splash.png` 不进入 assets（这些是源文件，只在构建期被 launcher_icons/native_splash 读取）。

---

### Task 3: 集成 flutter_launcher_icons

- [ ] **Step 1: 添加 dev dependency**

在 `pubspec.yaml` 的 `dev_dependencies:` 末尾添加：

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.3
```

- [ ] **Step 2: 在 `pubspec.yaml` 末尾添加配置**

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon.png"
```

- [ ] **Step 3: 运行生成**

```bash
dart run flutter_launcher_icons
```

输出应显示 "Android minSdkVersion = 16" 和 "iOS icons generated"。

---

### Task 4: 集成 flutter_native_splash

- [ ] **Step 1: 添加 dev dependency**

在 `pubspec.yaml` 的 `dev_dependencies:` 末尾添加：

```yaml
dev_dependencies:
  flutter_native_splash: ^2.4.4
```

- [ ] **Step 2: 在 `pubspec.yaml` 末尾添加配置**

```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/splash.png
  android: true
  ios: true
```

- [ ] **Step 3: 运行生成**

```bash
dart run flutter_native_splash:create
```

输出应显示 splash screen 在 Android 和 iOS 上创建成功。

---

### Task 5: 全量验证

- [ ] **Step 1: 依赖安装**

```bash
flutter pub get
```

- [ ] **Step 2: 代码分析**

```bash
flutter analyze
```
零 error。

- [ ] **Step 3: 测试**

```bash
flutter test
```
全部通过。

---

### Task 6: 提交

```bash
git add assets/ pubspec.yaml
git commit -m "feat: add asset structure, launcher icons, and native splash

- assets/: directory structure with placeholder icon/splash images
- flutter_launcher_icons: one-command icon generation for iOS/Android
- flutter_native_splash: one-command splash screen generation
- pubspec.yaml: assets declaration for images/fonts"
```
