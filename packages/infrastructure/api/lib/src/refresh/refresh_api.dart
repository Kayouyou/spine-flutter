import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:key_value_storage/key_value_storage.dart';
import 'package:uuid/uuid.dart';

import '../../api.dart';
import '../dio/header_interceptor.dart';

/// 检查响应是否需要触发 token 续期
Future<bool> shouldRenewToken(Response response) async {
  try {
    final data = response.data is String ? jsonDecode(response.data) : response.data;
    return data['code'] == HttpConstant.reTokenCode;
  } catch (e) {
    return false;
  }
}

/// 重试单个请求, 失败时重试一次
Future<Response?> retryRequestWithRetry(
  Dio dio,
  TokenStorage? tokenStorage,
  RequestOptions requestOptions,
) async {
  try {
    return await _retryRequest(dio, tokenStorage, requestOptions);
  } catch (e) {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return await _retryRequest(dio, tokenStorage, requestOptions);
    } catch (e) {
      return null;
    }
  }
}

/// 重试单个请求 — 内部版，保留原 L629-631 行为：
/// 仅当原 headers 中 token 非空时覆写，避免对无 auth 请求意外注入 token。
Future<Response> _retryRequest(
  Dio dio,
  TokenStorage? tokenStorage,
  RequestOptions requestOptions,
) async {
  final token = tokenStorage != null ? await tokenStorage.getToken() : null;
  final headers = requestOptions.headers;
  final token0 = headers['token'];
  if (token0 != null && token0 is String && token0.isNotEmpty) {
    headers['token'] = token;
  }

  final options = Options(
    method: requestOptions.method,
    headers: {...requestOptions.headers, 'token': token},
    sendTimeout: requestOptions.sendTimeout,
    receiveTimeout: requestOptions.receiveTimeout,
    extra: requestOptions.extra,
    responseType: requestOptions.responseType,
    contentType: requestOptions.contentType,
    validateStatus: requestOptions.validateStatus,
    receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
    followRedirects: requestOptions.followRedirects,
    maxRedirects: requestOptions.maxRedirects,
    requestEncoder: requestOptions.requestEncoder,
    responseDecoder: requestOptions.responseDecoder,
    listFormat: requestOptions.listFormat,
  );

  return await dio.request(
    requestOptions.path,
    options: options,
    data: requestOptions.data,
    queryParameters: requestOptions.queryParameters,
  );
}

/// 执行 token 续期
Future<bool> performTokenRenewal(
  Dio dio,
  TokenStorage? tokenStorage,
  DateTime? lastRenewalTime, {
  AppLoggerInterface? logger,
}) async {
  try {
    if (lastRenewalTime != null) {
      final timeSinceLastRenewal = DateTime.now().difference(lastRenewalTime);
      if (timeSinceLastRenewal < const Duration(seconds: 5)) {
        return true;
      }
    }

    final username = tokenStorage != null ? await tokenStorage.getUserId() : null;
    final params = <String, dynamic>{
      'Client': 10,
      'UserFlag': username ?? '',
    };
    final headers = <String, dynamic>{
      'Content-type': 'application/json',
      'accessKeyId': const String.fromEnvironment(''),
      'version': HttpConstant.Version,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      'signType': HttpConstant.SignType.toString(),
      'nonce': const Uuid().v4(),
      'token': '',
      'sign': '',
    };
    final token = tokenStorage != null ? await tokenStorage.getToken() : null;
    if (token != null && token.isNotEmpty) {
      headers['token'] = token;
    }
    final url = (HttpConstant.IsRelease
            ? Uri.https(HttpConstant.Http_Host, ApiBase.tokenRenewal)
            : Uri.http(HttpConstant.Http_Host, ApiBase.tokenRenewal))
        .toString();

    final response = await _executeRenewalRequest(
      url: url,
      params: params,
      headers: headers,
      cancelToken: CancelToken(),
    );

    if (response.statusCode == 200) {
      return await processRenewalResponse(response.data, tokenStorage);
    }
    logger?.warning(
      '续期请求返回非 200: status=${response.statusCode}, body=${response.data}',
    );
    return false;
  } catch (e) {
    return false;
  }
}

/// 处理续期响应数据
Future<bool> processRenewalResponse(dynamic responseData, TokenStorage? tokenStorage) async {
  try {
    final data = responseData is String ? jsonDecode(responseData) : responseData;
    final code = data['code'];

    if (code == HttpConstant.reLoginCode) {
      HttpEventBus.instance.commit(EventKeys.logout);
      return false;
    }

    if (code == 0 && data['data']?['token'] != null) {
      final newToken = data['data']['token'];
      if (tokenStorage != null) {
        await tokenStorage.setToken(newToken);
      }
      return true;
    }

    return false;
  } catch (e) {
    return false;
  }
}

/// 执行续期请求
Future<Response> _executeRenewalRequest({
  required String url,
  required Map<String, dynamic> params,
  required Map<String, dynamic> headers,
  required CancelToken cancelToken,
}) async {
  final tokenDio = Dio()..interceptors.add(HeaderInterceptor());
  _configureProxy(tokenDio);

  final response = await tokenDio.post(
    url,
    data: params,
    options: Options(
      headers: headers,
      validateStatus: (status) => true,
      receiveTimeout: const Duration(seconds: HttpConstant.ReceiveTimeout),
      sendTimeout: const Duration(seconds: HttpConstant.SendTimeout),
    ),
  );

  return response;
}

/// 配置代理
void _configureProxy(Dio dio) {
  if (!HttpConstant.Proxy_Enable) return;

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (uri) {
        return 'PROXY ${HttpConstant.proxyIp}:${HttpConstant.Proxy_Port}';
      };
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    },
  );
}
