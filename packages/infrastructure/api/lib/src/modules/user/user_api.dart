import 'package:api/src/modules/api_base.dart';
import 'package:api/src/http/http_method.dart';

/// 用户API Mixin
///
/// 职责：提供用户相关API接口方法
/// 使用：混入到Api类，提供login、getUserInfo、logout、updateUser等方法
/// 接口：
///   - login: 用户登录
///   - getUserInfo: 获取用户信息
///   - logout: 用户登出
///   - updateUser: 更新用户信息
mixin UserApiMixin on ApiBase {
  /// 用户登录
  ///
  /// 参数：
  /// - username: 用户名
  /// - password: 密码
  ///
  /// 返回：登录结果（包含token等）
  Future<dynamic> login({required String username, required String password}) {
    return httpManager.fireInternal(
      path: '/user/login',
      method: HttpMethod.POST,
      params: {
        'username': username,
        'password': password,
      },
      needLogin: false,
    );
  }

  /// 获取用户信息
  ///
  /// 返回：用户信息（包含用户名、头像等）
  Future<dynamic> getUserInfo() {
    return httpManager.fireInternal(
      path: '/user/info',
      method: HttpMethod.GET,
      needLogin: true,
    );
  }

  /// 用户登出
  ///
  /// 返回：登出结果
  Future<dynamic> logout() {
    return httpManager.fireInternal(
      path: '/user/logout',
      method: HttpMethod.POST,
      needLogin: true,
    );
  }

  /// 更新用户信息
  ///
  /// 参数：
  /// - data: 更新数据Map（包含需要更新的字段）
  ///
  /// 返回：更新结果
  Future<dynamic> updateUser(Map<String, dynamic> data) {
    return httpManager.fireInternal(
      path: '/user/info',
      method: HttpMethod.PUT,
      params: data,
      needLogin: true,
    );
  }
}