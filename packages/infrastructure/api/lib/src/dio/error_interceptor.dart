import 'package:dio/dio.dart';

/// Dio 错误拦截器
///
/// 把 Dio 异常上报给上层(典型为 AppErrorHandler.instance.reportError)。
/// 过滤规则：
///   - 4xx (400/401/403/404/422) **不上报**(业务期望错误,刷屏无意义)
///   - 5xx + 网络错误(connectionError / timeout / unknown / ...) **上报**
///
/// 使用 callback 注入是为了遵守 R3 规则：
/// infrastructure 包不依赖 services,所以这里不知道 AppErrorHandler 存在。
/// call-site(如 lib/core/di/setup.dart)负责把 onError 接到 AppErrorHandler。
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({
    required void Function(
      Object error,
      StackTrace? stack, {
      Map<String, dynamic> context,
    }) onError,
  }) : _onError = onError;

  final void Function(
    Object error,
    StackTrace? stack, {
    Map<String, dynamic> context,
  }) _onError;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final is4xx = status != null && status >= 400 && status < 500;

    if (!is4xx) {
      _onError(
        err,
        err.stackTrace,
        context: {
          'source': 'dio',
          'method': err.requestOptions.method,
          'url': err.requestOptions.uri.toString(),
          'status': status,
          'type': err.type.name,
        },
      );
    }

    // 必须继续 next,否则链路断在 ErrorInterceptor,后续拦截器(包括 LogInterceptor)看不到这个错误
    handler.next(err);
  }
}
