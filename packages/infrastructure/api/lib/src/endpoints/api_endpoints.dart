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

import '../http/api_config.dart';

abstract final class ApiBase {
  /// 基础 URL（依赖 ApiConfig 注入, 替代原 HttpConstant 硬编码）.
  ///
  /// 调用方必须通过 ApiConfig 注入 host, 否则抛 StateError.
  /// 推荐: 使用 [baseUrlFrom] 显式传入.
  static String get baseUrl => baseUrlFrom(_defaultConfig);

  /// 从指定 ApiConfig 构造基础 URL.
  static String baseUrlFrom(ApiConfig config) =>
      'http${config.isRelease ? 's' : ''}://${config.host}';

  /// Token 续期路径（基础设施共享端点，不属于任何业务域）
  @Deprecated('请使用 ApiEndpoints.tokenRenewal 替代')
  static const String tokenRenewal = '/User/Token/Renewal';

  // 内部 fallback: 调用方未注入 ApiConfig 时使用.
  // 仅作 fail-fast 占位 — 不应真用, 一旦访问 host 会抛错.
  static ApiConfig? _injectedConfig;
  static ApiConfig get _defaultConfig =>
      _injectedConfig ?? (_throwNoConfig());
  static ApiConfig _throwNoConfig() {
    throw StateError(
      'ApiBase.baseUrl 未注入 ApiConfig. '
      '请通过 createDio(apiConfig: ...) 或 ApiBase.baseUrlFrom(config) 传入. '
      '详见 SCAFFOLD_REVIEW_RETROSPECTIVE.md L-1.',
    );
  }

  /// 注入默认 ApiConfig (由 dio_factory.dart 启动期调用).
  /// 避免每个调用方重复传 config.
  // ignore: use_setters_to_change_properties
  static void injectConfig(ApiConfig config) {
    _injectedConfig = config;
  }
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
// ⚠️ 注意：此类已弃用，请使用 Retrofit API 接口（home_api、detail_api 等）替代。
// 迁移指南：
//   旧：ApiEndpoints.home.data
//   新：HomeApi(dio).getHomeData()
//
//   旧：ApiEndpoints.auth.login
//   新：AuthApi(dio).login(request)
//
//   旧：ApiEndpoints.detail.item(id)
//   新：DetailApi(dio).getDetail(id)

@Deprecated('请使用 Retrofit API 接口替代')
abstract final class ApiEndpoints {
  static const _Home home = _Home();
  static const _Detail detail = _Detail();
  static const _Auth auth = _Auth();
  static const _Session session = _Session();
  static const _Vehicle vehicle = _Vehicle();

  /// Token 续期（共享端点）
  static const String tokenRenewal = ApiBase.tokenRenewal;
}