import 'package:dio/dio.dart';
import 'package:domain/domain.dart';

import '../http/app_logger.dart';

/// 统一业务响应信封拦截器（P1）
///
/// 后端约定响应结构：`{ "code": int, "message": String, "data": <payload> }`。
/// - code == 0：成功，解包 `data` 为 `response.data`，下游 Retrofit/调用方直接拿到业务 payload。
/// - code == 1000102：续期码，原样放行给 [TokenRenewalInterceptor] 处理（不可在此拦截）。
/// - code != 0 且非续期码：业务错误，以 [BusinessException] 拒绝本次请求。
///
/// **安全策略（不破坏既有逻辑）**：仅当响应体是 Map 且同时含 `code` 与 `data` 键时才按信封处理；
/// 若后端返回裸 payload（无 `code`/`data` 包装），则原样放行，不影响现有 Retrofit 解析。
///
/// 放在拦截器链末尾（响应方向上最先执行），使解包后的干净 payload 优先于日志/监控被记录。
class ResponseEnvelopeInterceptor extends Interceptor {
  /// 是否启用信封解包（默认开启；可整体关闭以完全退化为原行为）
  final bool enabled;

  final AppLoggerInterface _logger;

  ResponseEnvelopeInterceptor({
    this.enabled = true,
    AppLoggerInterface? logger,
  }) : _logger = logger ?? DefaultLogger();

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (!enabled) return handler.next(response);

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return handler.next(response); // 非 Map（如 List/String），非信封，原样放行
    }
    if (!data.containsKey('code') || !data.containsKey('data')) {
      return handler.next(response); // 非信封结构，原样放行（保护裸 payload 的 Retrofit 解析）
    }

    final code = data['code'];
    if (code is! int) return handler.next(response);

    // 续期码：必须放行给 TokenRenewalInterceptor 处理，不可在此拦截
    if (code == 1000102) return handler.next(response);

    if (code == 0) {
      // 成功：解包内层业务数据
      response.data = data['data'];
      return handler.next(response);
    }

    // 业务错误：转为 BusinessException 拒绝，由 toResult 收口为 Result.failure
    final message =
        data['message'] is String ? data['message'] as String : '业务错误(code=$code)';
    _logger.warning(
      '[Envelope] 业务错误 code=$code message=$message path=${response.requestOptions.path}',
    );
    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: BusinessException(code, message),
      ),
      false,
    );
  }
}
