import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HeaderInterceptor extends Interceptor {
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
    // 对请求参数进行签名
    final header = options.headers;

    // 使用大小写兼容读取
    final token = _getHeaderIgnoreCase(header, 'token');
    final accessKeyId = _getHeaderIgnoreCase(header, 'accessKeyId');
    final signType = _getHeaderIgnoreCase(header, 'signType');
    final timestamp = _getHeaderIgnoreCase(header, 'timestamp');
    final version = _getHeaderIgnoreCase(header, 'version');
    final nonce = _getHeaderIgnoreCase(header, 'nonce');

    var signBody = <String, dynamic>{};
    if (token == null || token.isEmpty) {
      signBody = {
        'accessKeyId': accessKeyId ?? '',
        'signType': signType ?? '',
        'timestamp': timestamp ?? '',
        'version': version ?? '',
        'nonce': nonce ?? '',
      };
    } else {
      signBody = {
        'accessKeyId': accessKeyId ?? '',
        'signType': signType ?? '',
        'timestamp': timestamp ?? '',
        'token': token,
        'version': version ?? '',
        'nonce': nonce ?? '',
      };
    }
    // if (options.method != 'DOWNLOAD') {
    //   signBody.addAll(options.data);
    // }

    debugPrint('options: $options.method');
    // add queryParameters
    // signBody.addAll(options.queryParameters);
    if (!options.path.contains('.gz')) {
      signBody.addAll(options.data);
    }

    // signBody sorted by key
    final sortedKeys = signBody.keys.toList()
      ..sort((a, b) {
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    final sortedSignBody = {};
    for (final element in sortedKeys) {
      debugPrint('m ${signBody[element]}');
      // final type = signBody[element].runtimeType.toString();
      // debugPrint(signBody[element].runtimeType.toString());
      // if (element == 'Answers') {
      //   sortedSignBody[element] = 'object';
      // } else {
      // 判断是否是对象
      if ((signBody[element] is Map) || (signBody[element] is List)) {
        sortedSignBody[element] = 'object';
      } else {
        final value = signBody[element].toString();
        if (value.isNotEmpty) {
          sortedSignBody[element] = value;
        }
      }
      // }
    }

    // body's value => string
    final sortedSignBodyValueStr =
        sortedSignBody.values.reduce((value, element) {
      if (value.length == 0) {
        return value + element;
      } else {
        return value + ',' + element;
      }
    });

    // string => bytes
    final bytes = utf8.encode(sortedSignBodyValueStr);
    final digest = sha1.convert(bytes);
    options.headers['sign'] = digest.toString();

    super.onRequest(options, handler);
  }
}