# Deep Link Configuration

## Route format

```
/detail/:id
```

Example: `myapp://detail/abc123`

## Android (AndroidManifest.xml)

```xml
<!-- Add inside the main <activity> -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="myapp" />
</intent-filter>
```

## iOS (Info.plist)

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

## Verify deep links

**Android:**
```bash
adb shell am start -d "myapp://detail/abc123"
```

**iOS Simulator:**
```bash
xcrun simctl openurl booted "myapp://detail/abc123"
```
