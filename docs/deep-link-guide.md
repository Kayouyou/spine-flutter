# Deep Link 配置指南

## 概述

Deep Link 允许用户通过 URL 直接打开 App 内的特定页面。本项目使用 GoRouter 处理路由，支持：
- Custom scheme（`myapp://detail/abc123`）
- Universal Links / App Links（`https://example.com/detail/abc123`）

## 路由格式

```
/detail/:id
```

示例：`myapp://detail/abc123` → 打开详情页，id=abc123

## Android 配置

在 `android/app/src/main/AndroidManifest.xml` 的主 Activity 中添加：

```xml
<activity android:name=".MainActivity">
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="myapp" />
    </intent-filter>
    
    <!-- Universal Links (需要域名验证) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="example.com" />
    </intent-filter>
</activity>
```

## iOS 配置

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

Universal Links 需要在 `ios/Runner/Runner.entitlements` 添加 Associated Domains：
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:example.com</string>
</array>
```

## GoRouter 参数传递

在 `RouteModule.build()` 中从 `state.pathParameters` 或 `state.uri.queryParameters` 读取：

```dart
GoRoute(
  path: '/detail/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    final from = state.uri.queryParameters['from'];
    return DetailPage(id: id, from: from);
  },
);
```

## 测试 Deep Links

### Android
```bash
adb shell am start -a android.intent.action.VIEW \
    -d "myapp://detail/abc123" \
    com.example.myapp
```

### iOS Simulator
```bash
xcrun simctl openurl booted "myapp://detail/abc123"
```

### 浏览器测试（Universal Links）
1. 在 Notes app 输入 `https://example.com/detail/abc123`
2. 长按链接 → 选择 "Open in MyApp"

## 常见问题

**Q: Android 点击链接不跳转？**
A: 检查 `intent-filter` 的 `android:autoVerify="true"`，确保 App 已安装且域名 DNS 配置正确。

**Q: iOS Universal Links 不生效？**
A: 需要在域名根目录放置 `apple-app-site-association` 文件，内容包含 App ID。

**Q: 冷启动 vs 热启动？**
A: GoRouter 统一处理，`initialLocation` 只在冷启动时使用，热启动走 `redirect` 逻辑。
