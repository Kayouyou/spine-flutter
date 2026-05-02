# TextWithSuffix 组件使用指南

## 📖 概述

`TextWithSuffix` 是一个专门用于优先显示文本末尾内容的组件。当文本过长时，它会从开头截断文本，确保末尾内容和后缀（如时间标签）完整显示。

## 🎯 核心特性

- **末尾优先显示** - 文本过长时从开头截断，保留末尾重要信息
- **后缀保护** - 后缀内容（如时间标签）永远完整显示
- **像素级精确** - 使用二分查找算法精确计算截断位置
- **高度可配置** - 支持自定义样式、间距、对齐方式等
- **性能优化** - 智能缓存和最小化TextPainter调用

## 🚀 快速开始

### 基础用法

```dart
import 'package:component_library/component_library.dart';

// 基础文本带后缀
TextWithSuffix(
  text: '这是一段很长的文本内容，当空间不足时会从开头截断',
  suffix: ' (重要)',
  textStyle: TextStyle(fontSize: 14, color: Colors.black),
  suffixStyle: TextStyle(fontSize: 12, color: Colors.grey),
)
```

### 地址显示（推荐）

```dart
// 使用便捷构造函数显示地址和时间
AddressWithTime(
  address: '北京市朝阳区建国门外大街1号国贸大厦A座2008室',
  time: '16:20',
  textStyle: TextStyle(
    fontSize: 14.sp,
    color: Colors.black87,
  ),
  suffixStyle: TextStyle(
    fontSize: 12.sp,
    color: Colors.grey,
  ),
)
```

### 时间标签显示

```dart
// 专门用于时间标签的便捷构造函数
TextWithTime(
  text: '会议室预约：产品讨论会议',
  time: '14:30',
  textStyle: TextStyle(fontSize: 14),
  suffixStyle: TextStyle(fontSize: 12, color: Colors.blue),
)
```

## 📋 API 参考

### TextWithSuffix

| 参数 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `text` | `String` | 必需 | 主要文本内容 |
| `suffix` | `String?` | `null` | 后缀文本（如时间标签） |
| `textStyle` | `TextStyle` | 必需 | 主要文本样式 |
| `suffixStyle` | `TextStyle?` | `null` | 后缀文本样式，默认使用textStyle |
| `maxLines` | `int` | `1` | 最大行数 |
| `overflow` | `TextOverflow` | `TextOverflow.clip` | 溢出处理方式 |
| `ellipsis` | `String` | `'...'` | 省略号文本 |
| `spacing` | `double` | `0` | 文本和后缀之间的间距 |
| `bufferPixels` | `double` | `8` | 布局计算的缓冲像素 |
| `mainAxisAlignment` | `MainAxisAlignment` | `MainAxisAlignment.start` | 主轴对齐方式 |

### AddressWithTime

| 参数 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `address` | `String` | 必需 | 地址文本 |
| `time` | `String?` | `null` | 时间文本 |
| `textStyle` | `TextStyle` | 必需 | 地址文本样式 |
| `suffixStyle` | `TextStyle?` | `null` | 时间文本样式 |
| 其他参数 | - | - | 继承自TextWithSuffix |

### TextWithTime

| 参数 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `text` | `String` | 必需 | 主要文本内容 |
| `time` | `String` | 必需 | 时间文本 |
| `textStyle` | `TextStyle` | 必需 | 主要文本样式 |
| `suffixStyle` | `TextStyle?` | `null` | 时间文本样式 |
| `spacing` | `double` | `4` | 文本和时间之间的间距 |
| 其他参数 | - | - | 继承自TextWithSuffix |

## 🎨 使用场景

### 1. 行程信息显示

```dart
// 起始地址
AddressWithTime(
  address: startAddress,
  time: startTime,
  textStyle: TextStyle(
    color: theme.mainTitleColor,
    fontSize: 12.sp,
  ),
  suffixStyle: TextStyle(
    color: theme.subTitleColor,
    fontSize: 9.sp,
  ),
)

// 结束地址
AddressWithTime(
  address: endAddress,
  time: endTime.isNotEmpty ? endTime : null,
  textStyle: TextStyle(
    color: theme.mainTitleColor,
    fontSize: 12.sp,
  ),
  suffixStyle: TextStyle(
    color: theme.subTitleColor,
    fontSize: 9.sp,
  ),
)
```

### 2. 消息列表

```dart
TextWithTime(
  text: messageContent,
  time: messageTime,
  textStyle: TextStyle(fontSize: 14),
  suffixStyle: TextStyle(
    fontSize: 12,
    color: Colors.grey[600],
  ),
  spacing: 8,
)
```

### 3. 文件列表

```dart
TextWithSuffix(
  text: fileName,
  suffix: ' (${fileSize})',
  textStyle: TextStyle(fontSize: 14),
  suffixStyle: TextStyle(
    fontSize: 12,
    color: Colors.blue,
  ),
)
```

### 4. 自定义配置

```dart
TextWithSuffix(
  text: '这是一个需要特殊处理的长文本内容',
  suffix: ' [重要]',
  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  suffixStyle: TextStyle(fontSize: 14, color: Colors.red),
  ellipsis: '···',  // 自定义省略号
  spacing: 6,       // 自定义间距
  bufferPixels: 12, // 增加缓冲空间
  mainAxisAlignment: MainAxisAlignment.center, // 居中对齐
)
```

## 🔧 高级用法

### 动态样式

```dart
Widget buildDynamicText(String text, String? time, bool isImportant) {
  return AddressWithTime(
    address: text,
    time: time,
    textStyle: TextStyle(
      fontSize: isImportant ? 16.sp : 14.sp,
      fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
      color: isImportant ? Colors.red : Colors.black87,
    ),
    suffixStyle: TextStyle(
      fontSize: 12.sp,
      color: isImportant ? Colors.red[300] : Colors.grey,
    ),
  );
}
```

### 响应式布局

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isNarrow = constraints.maxWidth < 300;
    
    return TextWithSuffix(
      text: longText,
      suffix: suffix,
      textStyle: TextStyle(
        fontSize: isNarrow ? 12.sp : 14.sp,
      ),
      suffixStyle: TextStyle(
        fontSize: isNarrow ? 10.sp : 12.sp,
      ),
      bufferPixels: isNarrow ? 4 : 8,
    );
  },
)
```

## 🎯 最佳实践

### 1. 样式一致性

```dart
// 定义统一的样式
class AppTextStyles {
  static const addressStyle = TextStyle(
    fontSize: 14,
    color: Colors.black87,
    fontWeight: FontWeight.w500,
  );
  
  static const timeStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );
}

// 使用统一样式
AddressWithTime(
  address: address,
  time: time,
  textStyle: AppTextStyles.addressStyle,
  suffixStyle: AppTextStyles.timeStyle,
)
```

### 2. 性能优化

```dart
// 对于静态样式，使用const构造函数
const textStyle = TextStyle(fontSize: 14, color: Colors.black);
const suffixStyle = TextStyle(fontSize: 12, color: Colors.grey);

AddressWithTime(
  address: address,
  time: time,
  textStyle: textStyle,
  suffixStyle: suffixStyle,
)
```

### 3. 空值处理

```dart
// 优雅处理空时间
AddressWithTime(
  address: address,
  time: time?.isNotEmpty == true ? time : null,
  textStyle: textStyle,
  suffixStyle: suffixStyle,
)
```

## 🧪 测试用例

```dart
// 测试不同长度的文本
final testCases = [
  ('短文本', '16:20'),
  ('中等长度的文本内容', '16:20'),
  ('这是一个很长的文本内容，用来测试截断效果是否正常工作', '16:20'),
  ('超级长的文本内容，包含很多详细信息，用来测试极限情况下的显示效果', null),
];

for (final (text, time) in testCases) {
  AddressWithTime(
    address: text,
    time: time,
    textStyle: textStyle,
    suffixStyle: suffixStyle,
  );
}
```

## 🔍 故障排除

### 常见问题

1. **文本没有截断**
   - 检查是否设置了正确的约束
   - 确认bufferPixels设置合理

2. **后缀显示不完整**
   - 增加bufferPixels值
   - 检查suffixStyle的字体大小

3. **性能问题**
   - 避免在build方法中创建新的TextStyle对象
   - 使用const构造函数

4. **布局溢出**
   - 确保父容器有明确的宽度约束
   - 适当增加bufferPixels

---

**版本**: v1.0.0  
**更新日期**: 2025-02-07  
**作者**: AI Assistant