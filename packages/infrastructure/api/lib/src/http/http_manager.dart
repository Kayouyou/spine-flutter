import 'dart:async';
import 'dart:convert';
import 'package:domain/domain.dart';
import 'package:rxdart/rxdart.dart';
import '../../api.dart';
import '../api_builder.dart';
import '../dio/dio_adapter.dart';
import '../internal_request.dart';
import '../request/base_request.dart';
import 'http_adapter.dart';
import 'http_connectivity.dart';
import 'http_method.dart';
import 'error_handler.dart';

typedef UserTokenSupplier = Future<String?> Function();
typedef NetworkDisconnectedCallback = void Function();

///1.支持网络库插拔设计，且不干扰业务层
///2.基于配置请求请求，简洁易用
///3.Adapter设计，扩展性强
///4.统一异常和返回处理
class HttpManager {
  HttpManager._() {
    init();
  }

  static HttpManager? _instance;
  late HttpAdapter http;

  static HttpManager getInstance() {
    if (_instance == null) {
      _instance = HttpManager._();
    }
    return _instance!;
  }

  void init() {
    http = DioAdapter();
    _setupNetworkConnectivityStream();
  }

  UserTokenSupplier? _userTokenSupplier;

  set userTokenSupplier(UserTokenSupplier? _supplier) {
    _userTokenSupplier = _supplier;
    (http as DioAdapter).userTokenSupplier = _supplier;
  }

  TokenSupplier? _tokenSupplier;
  set tokenSupplier(TokenSupplier? supplier) {
    _tokenSupplier = supplier;
    (http as DioAdapter).tokenSupplier = supplier;
  }

  NetworkDisconnectedCallback? _onNetworkDisconnected;
  set networkDisconnectedCallBack(NetworkDisconnectedCallback? _supplier) {
    _onNetworkDisconnected = _supplier;
    (http as DioAdapter).onNetworkDisconnected = _supplier;
  }

  final _networkConnectivitySubject = PublishSubject<void>();
  StreamSubscription<void>? _networkConnectivitySubscription;

  void _setupNetworkConnectivityStream() {
    _networkConnectivitySubscription = _networkConnectivitySubject
        .debounceTime(Duration(seconds: 1))
        .listen((_) {
      if (_onNetworkDisconnected != null) {
        _onNetworkDisconnected!();
      }
    });
  }

  void dispose() {
    _networkConnectivitySubscription?.cancel();
    _networkConnectivitySubject.close();
  }

  Future fire(BaseRequest request, {String? cancelTag}) async {
    if (!await NetworkConnectivity.connected) {
      _networkConnectivitySubject.add(null);
      throw HttpsException(HttpConstant.NetworkErrorCode, '网络未连接', data: null);
    }

    final token = await _userTokenSupplier!();
    if (request.needLogin() && token == null) {
      return;
    }

    HttpResponse? response;
    dynamic error;

    try {
      response = await send(request, cancelTag: cancelTag);
    } on HttpsException catch (e) {
      error = e;
      rethrow;
    } catch (e) {
      error = e;
      throw ErrorHandler.handleError(e, data: null);
    }

    final result = response.data;
    final status = response.statusCode;
    switch (status) {
      case 200:
        {
          if (request.httpMethod() == HttpMethod.DOWNLOAD) {
            return 'download is success';
          }

          try {
            final Map<String, dynamic> mapData = jsonDecode(result!);
            final code = mapData['code'];

            if (code == HttpConstant.reLoginCode) {
              HttpEventBus.instance.commit(EventKeys.logout);
              return;
            }

            if (code == 0 || code == 200) {
              if (mapData['data'] != null) {
                return mapData['data'];
              } else {
                return Map();
              }
            } else {
              throw HttpsException(mapData['code'] ?? -1,
                  mapData['message'] ?? mapData.toString(),
                  data: mapData);
            }
          } catch (e) {
            throw ErrorHandler.handleError(e, response: result, data: result);
          }
        }
      default:
        throw ErrorHandler.handleError(error ?? '状态码错误: $status',
            response: result, data: result);
    }
  }

  ///发送请求
  Future<HttpResponse<T>> send<T>(BaseRequest request,
      {String? cancelTag}) async {
    return http.send(request, cancelTag: cancelTag);
  }

  ///取消请求
  void cancelRequest(String tag) {
    http.cancelRequest(tag);
  }

  ///取消所有请求
  void cancelAllRequest() {
    http.cancelRequests();
  }

  /// 内部执行方法 - 对外只抛出 DomainException
  ///
  /// 设计说明：
  /// - 构建临时 InternalRequest 对象
  /// - 调用原有 fire() 方法（保留所有网络、解析逻辑）
  /// - 捕获 HttpsException 并转换为 DomainException
  /// - 保证：响应解析逻辑完全不变，只有错误类型变化
  Future<dynamic> fireInternal({
    required String path,
    required HttpMethod method,
    Map<String, dynamic>? params,
    Map<String, dynamic>? headers,
    bool needLogin = true,
  }) async {
    try {
      final request = InternalRequest(
        path: path,
        method: method,
        needLogin: needLogin,
      );
      if (params != null) {
        params.forEach((key, value) => request.add(key, value));
      }
      if (headers != null) {
        headers.forEach((key, value) => request.addHeader(key, value));
      }
      // 关键：调用原有 fire()，保留所有逻辑
      return await fire(request);
    } on HttpsException catch (e) {
      // 转换为 DomainException，Repository 层无需 try-catch
      throw e.toDomainException();
    } catch (e) {
      // 其他异常也转换为 DomainException（兜底）
      throw DomainException(ErrorCode.unknown);
    }
  }

  /// 快捷方法：创建 POST ApiBuilder
  ApiBuilder post(String path, {bool needLogin = true}) => ApiBuilder(
    httpManager: this,
    path: path,
    method: HttpMethod.POST,
    needLogin: needLogin,
  );

  /// 快捷方法：创建 GET ApiBuilder
  ApiBuilder get(String path, {bool needLogin = true}) => ApiBuilder(
    httpManager: this,
    path: path,
    method: HttpMethod.GET,
    needLogin: needLogin,
  );
}
