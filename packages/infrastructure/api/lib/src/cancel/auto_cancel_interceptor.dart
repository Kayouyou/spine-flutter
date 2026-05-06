import 'package:dio/dio.dart';

/// 自动 CancelToken 绑定拦截器
///
/// 必须放在拦截器链 [0] 位置，确保 CancelToken 先生成。
/// 通过 closure 注入，避免对 RequestContext / CancelTokenManager 的硬依赖。
/// 无 tag → 放行（fail-safe，不影响无 RequestScope 的场景）
class AutoCancelInterceptor extends Interceptor {
  final String? Function() _tagProvider;
  final void Function(String tag, CancelToken token) _registerFn;

  AutoCancelInterceptor({
    required String? Function() tagProvider,
    required void Function(String tag, CancelToken token) registerFn,
  })  : _tagProvider = tagProvider,
        _registerFn = registerFn;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tag = _tagProvider();
    if (tag == null) return handler.next(options);

    final cancelToken = CancelToken();
    _registerFn(tag, cancelToken);
    options.cancelToken = cancelToken;
    handler.next(options);
  }
}
