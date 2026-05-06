/// API 端点注册表
///
/// 集中管理所有 API 端点路径。单一 baseUrl 来源。
/// 分组标准：按后端路径前缀分第一层，基础设施共享端点独立放 ApiBase。
///
/// 使用：
/// ```dart
/// _dio.get(ApiEndpoints.home.data);
/// _dio.post(ApiEndpoints.auth.login, data: {...});
/// ```
library;

import 'package:api/src/http/http_constant.dart';

abstract final class ApiBase {
  /// 基础 URL（引用 HttpConstant 的环境感知逻辑）
  static String get baseUrl =>
      'http${HttpConstant.IsRelease ? 's' : ''}://${HttpConstant.Http_Host}';

  /// Token 续期路径（基础设施共享端点，不属于任何业务域）
  static const String tokenRenewal = '/User/Token/Renewal';
}

// ─── 按后端路径前缀分组的业务域 ───
// 使用实例成员（而非 static）使得 ApiEndpoints 能通过实例访问。
// 这样 _dio.get(ApiEndpoints.home.data) 可以正确解析。

final class _Home {
  const _Home();
  String get data => '/home/data';
}

final class _Detail {
  const _Detail();
  String item(String id) => '/detail/$id';
}

final class _Auth {
  const _Auth();
  String get login => '/User/Login/Password';
  String get register => '/User/Register';
  String profile(String username) => '/User/$username';
  String get forgotPassword => '/User/forgot_password';
}

final class _Session {
  const _Session();
  String get signIn => '/session';
  String get signOut => '/session';
}

final class _Vehicle {
  const _Vehicle();
  String get list => '/Vehicle/List';
  String get detail => '/Vehicle/Detail/Info';
  String get ranking => '/Vehicle/Ranking/Query/Top/Info';
}

// ─── 统一入口 ───

abstract final class ApiEndpoints {
  static const _Home home = _Home();
  static const _Detail detail = _Detail();
  static const _Auth auth = _Auth();
  static const _Session session = _Session();
  static const _Vehicle vehicle = _Vehicle();

  /// Token 续期（共享端点）
  static const String tokenRenewal = ApiBase.tokenRenewal;
}
