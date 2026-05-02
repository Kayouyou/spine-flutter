# KeyValueStorage包

## 概述
基于Hive的本地存储解决方案，提供统一缓存管理。

## 模块结构

### BoxManager
Box实例统一管理，避免重复打开。

### BoxService<T>
泛型Box服务，封装CRUD操作。
- 基础CRUD：put/get/delete
- 批量操作：putAll/getAllValues
- 排序过滤：getSorted/where（性能警告：数据量>50慎用）
- 过期机制：putWithExpiry/getWithExpiry

### CacheData
缓存数据包装，支持TTL过期。

### HiveRegistrar
Hive Adapter统一注册。

## 使用示例

### DI注册
```dart
sl.registerFactory<BoxService<User>>(() => BoxService<User>('user_box'));
```

### 基础使用
```dart
final userBox = sl<BoxService<User>>();

await userBox.put('current_user', user);
final user = await userBox.get('current_user');

// 带过期时间存储（1小时）
await userBox.putWithExpiry('temp_data', data, ttl: Duration(hours: 1));

// 获取（自动检查过期）
final data = await userBox.getWithExpiry('temp_data');
```

## Hive Adapter注册

### 添加新模型
1. 创建模型类，添加Hive注解
2. 运行build_runner生成Adapter
3. 注册Adapter

### TypeId分配
- 0: CacheData（基础）
- 1+: 业务模型（User, Order, Product等）

## 性能警告
- 排序过滤操作数据量>50条慎用
- 大量数据建议分页加载
- Box实例内存占用，App退出时调用closeAll释放

## 依赖关系
- hive: 本地存储引擎
- hive_generator: Adapter代码生成
- build_runner: 代码生成工具
