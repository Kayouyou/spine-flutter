import 'package:api/src/modules/api_base.dart';
import 'package:api/src/http/http_method.dart';

/// 订单API Mixin
///
/// 职责：提供订单相关API接口方法
/// 使用：混入到Api类，提供订单列表、详情、创建、取消等方法
/// 接口：
///   - getOrderList: 获取订单列表（分页、筛选）
///   - getOrderDetail: 获取订单详情
///   - createOrder: 创建订单
///   - cancelOrder: 取消订单
mixin OrderApiMixin on ApiBase {
  /// 获取订单列表
  ///
  /// 参数：
  /// - status: 订单状态筛选（可选）
  /// - page: 页码（默认1）
  /// - size: 每页数量（默认20）
  ///
  /// 返回：订单列表数据（分页）
  Future<dynamic> getOrderList({String? status, int page = 1, int size = 20}) {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
    };
    // 状态筛选（可选）
    if (status != null) {
      params['status'] = status;
    }

    return httpManager.fireInternal(
      path: '/order/list',
      method: HttpMethod.GET,
      params: params,
      needLogin: true,
    );
  }

  /// 获取订单详情
  ///
  /// 参数：
  /// - orderId: 订单ID
  ///
  /// 返回：订单详情数据
  Future<dynamic> getOrderDetail(String orderId) {
    return httpManager.fireInternal(
      path: '/order/$orderId',
      method: HttpMethod.GET,
      needLogin: true,
    );
  }

  /// 创建订单
  ///
  /// 参数：
  /// - data: 订单数据Map（包含商品信息、地址等）
  ///
  /// 返回：创建结果（包含订单ID）
  Future<dynamic> createOrder(Map<String, dynamic> data) {
    return httpManager.fireInternal(
      path: '/order/create',
      method: HttpMethod.POST,
      params: data,
      needLogin: true,
    );
  }

  /// 取消订单
  ///
  /// 参数：
  /// - orderId: 订单ID
  /// - reason: 取消原因（可选）
  ///
  /// 返回：取消结果
  Future<dynamic> cancelOrder(String orderId, {String? reason}) {
    final params = <String, dynamic>{};
    if (reason != null) {
      params['reason'] = reason;
    }

    return httpManager.fireInternal(
      path: '/order/$orderId/cancel',
      method: HttpMethod.POST,
      params: params,
      needLogin: true,
    );
  }
}