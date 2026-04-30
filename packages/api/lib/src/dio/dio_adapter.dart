import 'dart:async';
import 'dart:io';

import 'package:api/src/dio/renewal_token_intercaptor.dart';
import 'package:api/src/http/token_supplier.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio/src/adapters/io_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../api.dart';
import '../http/http_adapter.dart';
import '../http/http_method.dart';
import '../request/base_request.dart';
import '../request/download.dart';

import 'header_interceptor.dart';

typedef UserTokenSupplier = Future<String?> Function();
typedef NetworkDisconnectedCallback = void Function();

const _appTokenEnvironmentVariableKey = 'ovsx-app-token';

///Dio适配器
class DioAdapter extends HttpAdapter {
  static Dio? _dio;
  static Dio? get dio => _dio;
  //定义一个共用的取消令牌，可用于用户操作时token校验失败取消其他请求操作
  // CancelToken cancelToken = CancelToken();
  final Map<String, CancelToken> _cancelTokens = {};

  UserTokenSupplier? _userTokenSupplier;
  set userTokenSupplier(UserTokenSupplier? _supplier) {
    _userTokenSupplier = _supplier;
  }

  TokenSupplier? _tokenSupplier;
  set tokenSupplier(TokenSupplier? supplier) {
    _tokenSupplier = supplier;
    // 更新拦截器的TokenSupplier
    _updateInterceptorTokenSupplier();
  }

  NetworkDisconnectedCallback? _onNetworkDisconnected;
  set onNetworkDisconnected(NetworkDisconnectedCallback? _callback) {
    _onNetworkDisconnected = _callback;
  }

  void _updateInterceptorTokenSupplier() {
    if (_dio != null && _tokenSupplier != null) {
      for (final interceptor in _dio!.interceptors) {
        if (interceptor is TokenRenewalInterceptor) {
          interceptor.tokenSupplier = _tokenSupplier!;
        }
      }
    }
  }

  @override
  Future<HttpResponse<T>> send<T>(BaseRequest request,
      {String? cancelTag}) async {
    CancelToken? token;
    if (cancelTag != null) {
      token = CancelToken();
      _cancelTokens[cancelTag] = token;
    }

    // 这里是通过运行时的环境变量存储api的accessKeyId，在main configuration中
    final accessKeyId = const String.fromEnvironment(
      _appTokenEnvironmentVariableKey,
    );
    request.addHeader('accessKeyId', accessKeyId);
    if (request.needLogin()) {
      if (_userTokenSupplier != null) {
        final token = await _userTokenSupplier!();
        if (token != null) {
          if (token.length != 0) {
            request.addHeader('token', token);
          }
        }
      }
    } else {
      request.addHeader('token', '');
    }
    var response, options = Options(headers: request.header);
    var error = null;
    try {
      if (request.httpMethod() == HttpMethod.GET) {
        response = await getDio()
            .get(request.url(), options: options, cancelToken: token);
      } else if (request.httpMethod() == HttpMethod.POST) {
        response = await getDio().post(request.url(),
            data: request.params, //request.params,
            options: options,
            cancelToken: token);
      } else if (request.httpMethod() == HttpMethod.DELETE) {
        response = await getDio().delete(request.url(),
            data: request.params, options: options, cancelToken: token);
      } else if (request.httpMethod() == HttpMethod.DOWNLOAD) {
        final downlaod_request = request as DownLoadRequest;
        response = await getDio().download(
            request.url(), downlaod_request.savePath.path,
            options: options, cancelToken: token);
      }
    } on DioException catch (e) {
      error = e;
      response = e.response;
    } catch (e) {
      // 捕获非DioException的异常
      error = e;
    }

    if (error != null) {
      // 使用统一的错误处理器
      throw ErrorHandler.handleError(error,
          response: response, data: await buildRes(response, request));
    }

    return buildRes(response, request);
  }

  Dio getDio() {
    if (_dio == null) {
      final dio = Dio();
      dio.options = BaseOptions(
          sendTimeout: Duration(milliseconds: HttpConstant.SendTimeout),
          receiveTimeout: Duration(milliseconds: HttpConstant.ReceiveTimeout),
          connectTimeout: Duration(
              milliseconds: HttpConstant.ConnectTimeout)); // 设置超时时间等 ...
      if (HttpConstant.Proxy_Enable) {
        dio.httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () {
            final client = HttpClient();
            client.findProxy = (uri) {
              // Proxy all request to localhost:8888.
              // Be aware, the proxy should went through you running device,
              // not the host platform.
              // return 'PROXY localhost:8888';
              return 'PROXY ${HttpConstant.Proxy_Ip}:${HttpConstant.Proxy_Port}';
            };
            client.badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;
            return client;
          },
        );
      }
      dio.interceptors
          .add(HeaderInterceptor()); // 添加Header拦截器，如 token之类，需要全局使用的参数
      // dio.interceptors.add(
      //   LogInterceptor(responseBody: false),
      // );
      if (kDebugMode) {
        dio.interceptors.add(
          PrettyDioLogger(
            // 添加日志格式化工具类
            requestHeader: true,
            requestBody: true,
            responseBody: true,
            responseHeader: false,
            error: true,
            compact: true,
            maxWidth: 90,
          ),
        );
      }

      // 添加日志上报拦截器
      dio.interceptors.add(LogReportingInterceptor());

      // dio.interceptors.add(BetterRetryInterceptor(apiClient: dio));
      dio.interceptors.add(
        TokenRenewalInterceptor(dio),
      );

      _dio = dio;
      // 创建 Dio 后，立即注入已设置的 tokenSupplier
      if (_tokenSupplier != null) {
        _updateInterceptorTokenSupplier();
      }
      return _dio!;
    } else {
      return _dio!;
    }
  }

  ///构建HiNetResponse
  Future<HttpResponse<T>> buildRes<T>(Response? response, BaseRequest request) {
    return Future.value(HttpResponse(
        //?.防止response为空
        data: response?.data,
        request: request,
        statusCode: response?.statusCode,
        statusMessage: response?.statusMessage,
        extra: response));
  }

  @override
  void cancelRequests() {
    _cancelTokens.forEach((_, token) => token.cancel('用户取消请求'));
    _cancelTokens.clear();
  }

  @override
  void cancelRequest(String tag) {
    if (_cancelTokens.containsKey(tag)) {
      _cancelTokens[tag]?.cancel('取消特定请求');
      _cancelTokens.remove(tag);
    }
  }
}
