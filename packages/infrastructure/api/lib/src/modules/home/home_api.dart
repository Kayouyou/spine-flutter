import 'package:api/src/modules/api_base.dart';
import 'package:api/src/http/http_method.dart';

/// 首页API Mixin
///
/// 职责：提供首页相关API接口方法
/// 使用：混入到Api类，提供getHomeData、getRecommendList等方法
/// 接口：
///   - getHomeData: 获取首页数据
///   - getRecommendList: 获取推荐列表（分页）
mixin HomeApiMixin on ApiBase {
  /// 获取首页数据
  ///
  /// 返回：首页聚合数据（包含banner、推荐、分类等）
  Future<dynamic> getHomeData() {
    return httpManager.fireInternal(
      path: '/home/data',
      method: HttpMethod.GET,
      needLogin: false,
    );
  }

  /// 获取推荐列表
  ///
  /// 参数：
  /// - page: 页码（默认1）
  /// - size: 每页数量（默认20）
  ///
  /// 返回：推荐列表数据（分页）
  Future<dynamic> getRecommendList({int page = 1, int size = 20}) {
    return httpManager.fireInternal(
      path: '/home/recommend',
      method: HttpMethod.GET,
      params: {
        'page': page,
        'size': size,
      },
      needLogin: false,
    );
  }
}