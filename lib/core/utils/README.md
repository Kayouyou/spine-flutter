# 工具模块 (Utils)

## 职责
提供通用工具类和辅助函数：
- 字符串处理
- 日期时间工具
- 文件操作
- 类型转换
- 日志工具

## 使用示例
```dart
// 字符串工具
final truncated = StringUtils.truncate('长文本...', maxLength: 10);

// 日期格式化
final formatted = DateTimeUtils.format(DateTime.now(), 'yyyy-MM-dd');

// 日志记录
LogUtils.info('操作成功');
LogUtils.error('发生错误', error: exception);
```

## 依赖关系
- 无外部模块依赖，作为基础工具模块

## 性能警告
- 字符串操作应注意内存使用
- 日志输出在生产环境应关闭debug级别
- 大文件操作应使用流式处理