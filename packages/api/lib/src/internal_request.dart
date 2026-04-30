import 'package:api/src/http/http_method.dart';
import 'package:api/src/request/base_request.dart';

/// 内部 Request 类 - 不对外暴露
/// 用于 HttpManager.fireInternal() 内部构建请求对象
/// 替代 240 个 Request 文件的通用实现
///
/// 设计说明：
/// - 继承 BaseRequest，保留原有 url()、header 等逻辑
/// - 通过构造函数传入 path、method、needLogin
/// - fireInternal() 内部使用，不暴露给 API mixin
class InternalRequest extends BaseRequest {
  final String _path;
  final HttpMethod _method;
  final bool _needLogin;

  InternalRequest({
    required String path,
    required HttpMethod method,
    required bool needLogin,
  })  : _path = path,
        _method = method,
        _needLogin = needLogin;

  @override
  String path() => _path;

  @override
  HttpMethod httpMethod() => _method;

  @override
  bool needLogin() => _needLogin;
}