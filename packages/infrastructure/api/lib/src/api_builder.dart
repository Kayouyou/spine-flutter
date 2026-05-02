import 'package:api/src/http/http_manager.dart';
import 'package:api/src/http/http_method.dart';

/// API 请求构建器 - 函数式链式调用
/// 替代 240 个 Request 文件
///
/// 设计说明：
/// - 每个链式调用创建一个 ApiBuilder 实例
/// - addParam/addParams 自动过滤 null 和空字符串
/// - fire() 调用 HttpManager.fireInternal()，自动转换错误
/// - 保证：参数处理逻辑与原 request.add() 一致
class ApiBuilder {
  final HttpManager _httpManager;
  final String _path;
  final HttpMethod _method;
  final bool _needLogin;
  final Map<String, dynamic> _params = {};
  final Map<String, dynamic> _headers = {};

  ApiBuilder({
    required HttpManager httpManager,
    required String path,
    required HttpMethod method,
    bool needLogin = true,
  })  : _httpManager = httpManager,
        _path = path,
        _method = method,
        _needLogin = needLogin;

  /// 添加单个参数
  /// 自动过滤 null 和空字符串（与原 request.add() 逻辑一致）
  ApiBuilder addParam(String key, dynamic value) {
    if (value != null) {
      if (value is String && value.isEmpty) return this;
      _params[key] = value;
    }
    return this;
  }

  /// 批量添加参数
  /// 遍历 Map，逐个调用 addParam
  ApiBuilder addParams(Map<String, dynamic> params) {
    params.forEach((key, value) => addParam(key, value));
    return this;
  }

  /// 设置请求头
  ApiBuilder addHeader(String key, dynamic value) {
    if (value != null) _headers[key] = value.toString();
    return this;
  }

  /// 执行请求
  /// 返回 dynamic（与原 fire() 返回类型一致）
  /// fireInternal 内部处理 HttpsException → DomainException 转换
  Future<dynamic> fire() async {
    return _httpManager.fireInternal(
      path: _path,
      method: _method,
      params: _params,
      headers: _headers,
      needLogin: _needLogin,
    );
  }
}