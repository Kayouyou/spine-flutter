# 请求取消模块

## 职责
管理页面级请求取消，避免页面退出后请求继续执行。

## 使用示例

### 手动管理
```dart
// 创建CancelToken
final token = CancelToken();
CancelTokenManager.instance.register('home_page', token);

// 发起请求
await api.get('/data').cancelToken(token).fire();

// 页面退出时取消
CancelTokenManager.instance.cancelPage('home_page');
CancelTokenManager.instance.cleanup('home_page');
```

### RequestScope自动管理
```dart
RequestScope(
  tag: 'detail_page',
  child: DetailContent(),
)
// Widget销毁时自动取消请求
```

## 设计原理
1. 每个页面有唯一tag标识
2. 页面内所有请求共用tag
3. 页面退出时批量取消所有未完成请求

## 依赖关系
- dio: CancelToken来源

## 性能警告
- Token映射表内存占用，页面退出后需cleanup清理
- 大量请求时Token列表可能较长，建议分批管理