# 数据同步模块 (Sync)

## 职责
负责应用数据的同步和管理：
- 离线/在线数据同步
- 冲突解决策略
- 增量同步
- 数据版本控制

## 使用示例
```dart
// 同步数据
final syncResult = await syncService.sync();

// 检查同步状态
if (syncService.hasPendingChanges) {
  await syncService.syncPendingChanges();
}

// 监听同步事件
syncService.syncStream.listen((event) {
  print('同步状态: ${event.status}');
});
```

## 依赖关系
- `lib/core/di` - 服务注入
- `lib/core/utils` - 工具函数
- `lib/core/auth` - 用户认证

## 性能警告
- 大数据量同步应分批进行
- 使用增量同步减少网络传输
- 后台同步不应影响前台性能
