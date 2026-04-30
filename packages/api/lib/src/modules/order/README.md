# 订单API模块

## 概述

本模块提供订单相关的API接口方法，通过Mixin模式混入到主Api类。

## 核心组件

### OrderApiMixin

订单API混合类，提供以下方法：

| 方法 | 说明 | 需要登录 |
|------|------|---------|
| getOrderList | 获取订单列表（分页、筛选） | 是 |
| getOrderDetail | 获取订单详情 | 是 |
| createOrder | 创建订单 | 是 |
| cancelOrder | 取消订单 | 是 |

## 使用方法

```dart
// 在Api类中混入
class Api extends ApiBase with OrderApiMixin {
  // ...
}

// 调用API方法
final api = Api(userTokenSupplier: ...);

// 获取订单列表（全部状态）
final orders = await api.getOrderList();

// 获取待支付订单
final pendingOrders = await api.getOrderList(status: 'pending');

// 获取订单详情
final detail = await api.getOrderDetail('order-123');

// 创建订单
final result = await api.createOrder({
  'productId': 'product-1',
  'addressId': 'address-1',
  'quantity': 2,
});

// 取消订单
await api.cancelOrder('order-123', reason: '不想买了');
```

## 设计原则

1. **Mixin模式**：灵活组合，按需混入
2. **统一错误处理**：fireInternal自动转换为DomainException
3. **可选参数**：支持灵活筛选
4. **RESTful路径**：orderId直接嵌入路径

## 订单状态

常见订单状态：
- pending: 待支付
- paid: 已支付
- shipping: 配送中
- completed: 已完成
- cancelled: 已取消
