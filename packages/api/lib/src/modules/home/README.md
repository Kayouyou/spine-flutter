# 首页API模块

## 概述

本模块提供首页相关的API接口方法，通过Mixin模式混入到主Api类。

## 核心组件

### HomeApiMixin

首页API混合类，提供以下方法：

| 方法 | 说明 | 需要登录 |
|------|------|---------|
| getHomeData | 获取首页聚合数据 | 否 |
| getRecommendList | 获取推荐列表（分页） | 否 |

## 使用方法

```dart
// 在Api类中混入
class Api extends ApiBase with HomeApiMixin {
  // ...
}

// 调用API方法
final api = Api(userTokenSupplier: ...);

// 获取首页数据
final homeData = await api.getHomeData();

// 获取推荐列表（第1页，每页20条）
final recommendList = await api.getRecommendList(page: 1, size: 20);
```

## 设计原则

1. **Mixin模式**：灵活组合，按需混入
2. **统一错误处理**：fireInternal自动转换为DomainException
3. **默认参数**：提供合理的默认值

## 数据结构

首页数据通常包含：
- banner列表
- 推荐商品/内容
- 分类入口
- 活动信息