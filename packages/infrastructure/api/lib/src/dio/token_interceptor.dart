import 'dart:io';

import 'package:api/src/http/token_supplier.dart';
import 'package:dio/io.dart';
import 'package:dio/src/adapters/io_adapter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:queue/queue.dart';

import 'package:uuid/uuid.dart';
import '../../api.dart';
import '../http/http_constant.dart';
import 'header_interceptor.dart';

typedef UserTokenSupplier = Future<String?> Function();

class TokenInterceptor extends Interceptor {
  final Dio _dio;
  final TokenSupplier _tokenSupplier;
  bool isReLogin = false;
  Queue queue = Queue();

  int _refreshTimes = 0;
  TokenInterceptor(
    this._dio,
    this._tokenSupplier,
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    super.onRequest(options, handler);
  }

  @override
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    bool needRefreshToken = _checkIfNeedRefreshToken(response);
    if (!needRefreshToken) {
      return super.onResponse(response, handler);
    }
    bool success;
    // 异常退出机制，以防陷入死循环
    if (_refreshTimes < 10) {
      // 参考 https://github.com/flutterchina/dio/issues/590
      // Check for if the token were successfully refreshed
      success = await queue.add(() async {
        // refreshTokens returns true when it has successfully retrieved the new tokens.
        // When the Authorization header of the original request differs from the current Authorization header of the Dio instance,
        // it means the tokens where refreshed by the first request in the queue and the refreshTokens call does not have to be made.

        // var requestToken = response.headers['token'];
        // var globalToken = await _getToken();

        // token一致表示需要更新token，不一致则表示token已经在其它请求中更新了
        if (_refreshTimes == 0) {
          // if (kDebugMode) {
          //   await _refreshToken();
          //   return Future.delayed(const Duration(seconds: 3), () {
          //     return true;
          //   });
          // }
          return await _refreshToken();
        }
        return true;
      });
    } else {
      success = false;
      HttpEventBus.instance.commit(EventKeys.logout);
    }

    if (success) {
      _retry(response).then((value) {
        super.onResponse(value, handler);
      });
    } else {
      super.onResponse(response, handler);
    }
  }

  static const _appTokenEnvironmentVariableKey = 'ovsx-app-token';

  Future<bool> _refreshToken() async {
    try {
      final userName = await _tokenSupplier.getUsername();
      final params = <String, dynamic>{
        'Client': 10,
        'UserFlag': userName ?? '',
      };

      final headers = <String, dynamic>{
        'Content-type': 'application/json',
        'accessKeyId': const String.fromEnvironment(
          _appTokenEnvironmentVariableKey,
        ),
        'version': HttpConstant.Version,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'signType': HttpConstant.SignType.toString(),
        'nonce': Uuid().v4(),
        'token': '',
        'sign': '',
      };

      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers['token'] = token;
      }

      final url = (HttpConstant.IsRelease
          ? Uri.https(HttpConstant.Http_Host, '/User/Token/Renewal')
          : Uri.http(HttpConstant.Http_Host, '/User/Token/Renewal')).toString();
      var response;
      final options = Options(headers: headers);

      final tokenDio = Dio();
      if (HttpConstant.Proxy_Enable) {
        tokenDio.httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () {
            final client = HttpClient();
            client.findProxy = (uri) {
              // Proxy all request to localhost:8888.
              // Be aware, the proxy should went through you running device,
              // not the host platform.
              return 'PROXY ${HttpConstant.Proxy_Ip}:${HttpConstant.Proxy_Port}';
            };
            client.badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;
            return client;
          },
        );
      }
      tokenDio.interceptors
          .add(HeaderInterceptor()); // 添加Header拦截器，如 token之类，需要全局使用的参数

      response = await tokenDio.post(url,
          data: params,
          options: options,
          cancelToken: CancelToken());

      final result = response.data;
      final status = response.statusCode;

      if (status == 200) {
        // 需要处理
        final Map<String, dynamic> mapData = jsonDecode(result!);

        final code = mapData['code'];
        // token无法续期必须退出登录
        if (code == HttpConstant.reLoginCode) {
          HttpEventBus.instance.commit(EventKeys.logout);
          return false;
        } else if (code == 0) {
          final data = mapData['data'];
          if (data != null && data is Map) {
            if (data['token'] != null) {
              _refreshTimes++;
              await _tokenSupplier.setToken(data['token']);
              _refreshTimes = 0;
              debugPrint('token续期成功');
            }
          }

          return true;
        }
        HttpEventBus.instance.commit(EventKeys.logout);
        return false;
      } else {
        HttpEventBus.instance.commit(EventKeys.logout);
        return false;
      }
    } catch (_) {
      HttpEventBus.instance.commit(EventKeys.logout);
      return false;
    }
  }

  /// 判断是否需要刷新Token
  bool _checkIfNeedRefreshToken(Response<dynamic> response) {
    var mapData =
        response.data is String ? jsonDecode(response.data) : response.data;
    if (mapData['code'] == HttpConstant.renewalTokenCode) {
      return true;
    }
    return false;
  }

  /// 重发请求
  Future<Response<dynamic>> _retry(Response<dynamic> response) async {
    // Headers headers = response.headers;

    final _token = await _getToken();
    // headers.set('token', _token);
    // response.headers = headers;
    RequestOptions requestOptions = response.requestOptions;
    final headers = requestOptions.headers;
    headers['token'] = _token;
    final options = Options(
        method: requestOptions.method,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.sendTimeout,
        extra: requestOptions.extra,
        headers: headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        validateStatus: requestOptions.validateStatus,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        followRedirects: requestOptions.followRedirects,
        maxRedirects: requestOptions.maxRedirects,
        requestEncoder: requestOptions.requestEncoder,
        responseDecoder: requestOptions.responseDecoder,
        listFormat: requestOptions.listFormat);

    // var options = Options(headers: headers.map);

    if (options.method == 'POST') {
      return _dio.post(
        requestOptions.path,
        options: options,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
      );
    } else if (options.method == 'GET') {
      return _dio.get(
        requestOptions.path,
        options: options,
        queryParameters: requestOptions.queryParameters,
      );
    } else if (options.method == 'DELETE') {
      return _dio.delete(
        requestOptions.path,
        options: options,
        queryParameters: requestOptions.queryParameters,
      );
    } else {
      return _dio.post(
        requestOptions.path,
        options: options,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
      );
    }
  }

  Future<String?> _getToken() {
    return _tokenSupplier.getToken();
  }
}
