# 错误处理模块

## 职责
将Dio底层异常转换为业务层统一的DomainException，支持国际化错误消息。

## 使用示例
```dart
try {
  final response = await api.get('/user/info').fire();
} on DioException catch (e) {
  // 转换为DomainException
  final domainException = e.toDomainException();
  // 在UI层获取本地化消息
  showMessage(domainException.getMessage());
}
```

## 依赖关系
- dio: DioException来源
- domain_models: ErrorCode和DomainException定义

## 映射规则
1. HTTP状态码优先：401/403/404/500等
2. DioException类型其次：cancel/timeout/connectionError等
3. 无法识别返回ErrorCode.unknown

## 性能警告
无