import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../http/app_logger.dart';

/// 请求签名拦截器。
///
/// 对请求参数（accessKeyId / token / signType / timestamp / version / nonce + body）
/// 做 sha1 签名，写入 `sign` header，供后端校验请求完整性。
///
/// 注意：必须放在「注入 token header 的拦截器」之后，才能读到 token 参与签名
/// （主链在 Auth 拦截器中已注入 `token`；刷新请求透传原始请求 headers）。
class HeaderInterceptor extends Interceptor {
  AppLoggerInterface _logger = DefaultLogger();

  /// 注入日志实现（默认 [DefaultLogger]，仅 Debug 打印）。
  set logger(AppLoggerInterface? value) => _logger = value ?? DefaultLogger();

  /// 大小写兼容获取 header 值
  /// 后端要求驼峰形式（accessKeyId, signType），但 Dio Map 是 case-sensitive
  String? _getHeaderIgnoreCase(Map<String, dynamic> headers, String key) {
    final lowerKey = key.toLowerCase();
    for (final k in headers.keys) {
      if (k.toLowerCase() == lowerKey) {
        final v = headers[k];
        return v?.toString();
      }
    }
    return null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final header = options.headers;

    // 使用大小写兼容读取
    final token = _getHeaderIgnoreCase(header, 'token');
    final accessKeyId = _getHeaderIgnoreCase(header, 'accessKeyId');
    final signType = _getHeaderIgnoreCase(header, 'signType');
    final timestamp = _getHeaderIgnoreCase(header, 'timestamp');
    final version = _getHeaderIgnoreCase(header, 'version');
    final nonce = _getHeaderIgnoreCase(header, 'nonce');

    final signBody = <String, dynamic>{};
    if (token == null || token.isEmpty) {
      signBody.addAll({
        'accessKeyId': accessKeyId ?? '',
        'signType': signType ?? '',
        'timestamp': timestamp ?? '',
        'version': version ?? '',
        'nonce': nonce ?? '',
      });
    } else {
      signBody.addAll({
        'accessKeyId': accessKeyId ?? '',
        'signType': signType ?? '',
        'timestamp': timestamp ?? '',
        'token': token,
        'version': version ?? '',
        'nonce': nonce ?? '',
      });
    }

    // 仅对 JSON body（Map）参与签名；GET/下载等无 body 或非 Map 时跳过，避免空指针。
    // 原实现直接 addAll(options.data)，主链 GET 请求 data 为 null 会崩溃，此处加保护。
    if (!options.path.contains('.gz') &&
        options.data != null &&
        options.data is Map) {
      signBody.addAll(options.data as Map<String, dynamic>);
    }

    // signBody sorted by key
    final sortedKeys = signBody.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final sortedSignBody = <String, String>{};
    for (final element in sortedKeys) {
      final value = signBody[element];
      // 判断是否是对象
      if (value is Map || value is List) {
        sortedSignBody[element] = 'object';
      } else {
        final str = value?.toString() ?? '';
        if (str.isNotEmpty) {
          sortedSignBody[element] = str;
        }
      }
    }

    // body's value => string
    // 用 fold 而非 reduce：当所有签名参数均为空（例如未登录且未配置
    // accessKeyId/signType/timestamp/version/nonce 时），sortedSignBody 为空 Map，
    // reduce 会在空集合上抛 `Bad state: No element` 导致整个请求崩溃。
    // fold 提供初始值，空集合时安全返回空字符串；非空时行为与 reduce 一致。
    final sortedSignBodyValueStr = sortedSignBody.values.fold<String>(
      '',
      (value, element) {
        if (value.isEmpty) return element;
        return '$value,$element';
      },
    );

    // string => bytes
    final bytes = utf8.encode(sortedSignBodyValueStr);
    final digest = sha1.convert(bytes);
    options.headers['sign'] = digest.toString();

    _logger.debug('HeaderInterceptor: 已完成请求签名 path=${options.path}');
    super.onRequest(options, handler);
  }
}
