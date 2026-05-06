import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:api/src/http/token_supplier.dart';
import 'package:api/src/http/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:synchronized/synchronized.dart';

import 'package:uuid/uuid.dart';
import '../../api.dart';
import 'package:api/src/endpoints/api_endpoints.dart' show ApiBase;
import '../http/http_constant.dart';
import 'header_interceptor.dart';

/*
%%{init: {'theme':'dark', 'themeVariables': {'primaryColor':'#ff6b6b','primaryTextColor':'#fff','primaryBorderColor':'#ff6b6b','lineColor':'#ffa726','sectionBkgColor':'#1e1e1e','altSectionBkgColor':'#2d2d2d','gridColor':'#404040','secondaryColor':'#4fc3f7','tertiaryColor':'#81c784'}}}%%
flowchart TD
    A[响应被拦截] --> B{是否需要续期?};
    B -- 否 --> C[直接转发原始响应];

    B -- 是 --> D[请求加入待处理队列];
    D --> E[进入续期锁];

    E --> F{检查续期状态};
    F -- "状态: renewing" --> G[等待当前续期完成];
    F -- "状态: success (近期)" --> H["立即重试所有排队请求"];
    F -- "状态: idle 或 failed" --> I[启动新的续期流程];

    subgraph "单一实例续期流程 (异步)"
        I --> J["设置状态为 renewing"];
        J --> K[执行续期API调用];
        K --> L{API调用是否成功?};
        L -- 是 --> M["存储新Token并设置状态为 success"];
        M --> N[重试所有排队中的请求];

        L -- 否 --> O["设置状态为 failed"];
        O --> P[让所有排队中的请求失败];
    end

    subgraph "排队请求处理"
        G --> Q{进行中的续期是否成功?};
        Q -- 是 --> N;
        Q -- 否 --> P;
        N --> R[使用新Token重发原始请求];
        P --> S["使用原始(错误)响应完成请求"];
        H --> R;
    end

    subgraph "最终处理"
        R --> T[转发新的成功响应];
        S --> U[转发原始失败响应];
        C --> V[完成];
        T --> V;
        U --> V;
    end
*/

/// Token续期状态
enum TokenRenewalState {
  /// 空闲状态，没有续期操作在进行
  idle,

  /// 正在进行续期操作
  renewing,

  /// 续期成功
  success,

  /// 续期失败
  failed,
}

/// 请求包装类，用于存储和恢复请求
class _PendingRequest {
  final RequestOptions requestOptions;
  final Completer<Response> completer;
  final ResponseInterceptorHandler handler;
  final Response originalResponse;
  final DateTime timestamp;

  _PendingRequest({
    required this.requestOptions,
    required this.completer,
    required this.handler,
    required this.originalResponse,
  }) : timestamp = DateTime.now();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _PendingRequest) return false;

    // 定义两个请求相同的标准：路径、方法、参数和数据都相同
    return requestOptions.path == other.requestOptions.path &&
        requestOptions.method == other.requestOptions.method &&
        requestOptions.queryParameters.toString() ==
            other.requestOptions.queryParameters.toString() &&
        requestOptions.data.toString() == other.requestOptions.data.toString();
  }

  @override
  int get hashCode =>
      requestOptions.path.hashCode ^
      requestOptions.method.hashCode ^
      requestOptions.queryParameters.toString().hashCode ^
      requestOptions.data.toString().hashCode;
}

/// 优化版Token续期拦截器
/// 功能要求：
/// 1. 如果请求路径包含 User/Token/Renewal 就是正在续期请求，全局保证只请求一次续期
/// 2. 所有需要续期的请求（_shouldRenewToken返回true）都要被拦截和缓存
/// 3. 续期成功后重试所有缓存的请求，并清空缓存
/// 4. 多个并发请求都只触发一次token续期操作
class TokenRenewalInterceptor extends Interceptor {
  TokenRenewalInterceptor(
    this._dio,
    [TokenSupplier? tokenSupplier]
  ) {
    _tokenSupplier = tokenSupplier;
    _renewalLock = Lock();
  }

  final Dio _dio;
  TokenSupplier? _tokenSupplier;
  late final Lock _renewalLock;

  /// 日志输出实例
  ///
  /// 默认使用DefaultLogger（debugPrint输出）
  /// 可通过setter注入主应用的AppLogger
  AppLoggerInterface _logger = DefaultLogger();

  /// 设置Logger（支持依赖注入）
  ///
  /// 在App启动后注入，替换默认debugPrint输出
  /// 主应用的AppLogger需实现AppLoggerInterface接口
  set logger(AppLoggerInterface logger) => _logger = logger;

  /// 设置TokenSupplier（支持延迟注入）
  set tokenSupplier(TokenSupplier supplier) {
    _tokenSupplier = supplier;
  }

  // 使用Set存储待处理请求，自动去重
  final Set<_PendingRequest> _pendingRequests = {};

  // 当前续期状态
  TokenRenewalState _renewalState = TokenRenewalState.idle;

  // 续期请求路径标识
  static const String _tokenRenewalPath = "User/Token/Renewal";

  // 最近一次续期时间
  DateTime? _lastRenewalTime;

  // 续期操作的Completer，用于等待续期完成
  Completer<bool>? _renewalCompleter;

  /// 添加请求到待处理队列
  void _addToPendingRequests(
    RequestOptions requestOptions,
    Completer<Response> completer,
    ResponseInterceptorHandler handler,
    Response originalResponse,
  ) {
    // 跳过续期请求本身
    if (requestOptions.path.contains(_tokenRenewalPath)) {
      return;
    }

    try {
      final request = _PendingRequest(
        requestOptions: requestOptions,
        completer: completer,
        handler: handler,
        originalResponse: originalResponse,
      );

      _pendingRequests.add(request);
      _logger.debug('添加请求到队列: ${requestOptions.path}, 当前队列大小: ${_pendingRequests.length}');
    } catch (e) {
      _logger.error('添加请求到队列时出错: $e');
    }
  }

  /// 拦截器的核心方法，处理响应
  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // 1. 处理续期请求本身
    if (response.requestOptions.path.contains(_tokenRenewalPath)) {
      return _handleRenewalResponse(response, handler);
    }

    // 2. 检查是否需要续期
    bool needsRenewal = false;
    try {
      needsRenewal = await _shouldRenewToken(response);
    } catch (e) {
      _logger.error('检查是否需要续期时出错: $e');
      return handler.next(response);
    }

    // 如果不需要续期，直接处理响应
    if (!needsRenewal) {
      return handler.next(response);
    }

    _logger.info('请求需要续期: ${response.requestOptions.path}');

    // 创建一个Completer来控制响应流程
    final completer = Completer<Response>();

    // 当Completer完成时，将结果传递给handler
    completer.future.then((newResponse) {
      handler.next(newResponse);
    }).catchError((error) {
      _logger.warning('续期过程中出错，返回原始响应: $error');
      handler.next(response);
    });

    // 3. 将当前请求添加到缓存队列
    _addToPendingRequests(
      response.requestOptions,
      completer,
      handler,
      response,
    );

    // 4. 启动或等待续期流程
    await _renewalLock.synchronized(() async {
      // 如果已经有续期在进行，等待其完成
      if (_renewalState == TokenRenewalState.renewing) {
        _logger.debug('已有续期正在进行，等待续期完成: ${response.requestOptions.path}');
        return;
      }

      // 如果短时间内已经续期成功，直接重试请求
      if (_renewalState == TokenRenewalState.success &&
          _lastRenewalTime != null &&
          DateTime.now().difference(_lastRenewalTime!) < Duration(seconds: 5)) {
        _logger.debug('短时间内已经续期成功，直接重试请求');
        await _retryAllPendingRequests();
        return;
      }

      // 启动新的续期流程
      _renewalState = TokenRenewalState.renewing;
      _renewalCompleter = Completer<bool>();

      // 使用Future.microtask确保不阻塞当前线程
      Future.microtask(() async {
        try {
          _logger.info('开始执行token续期流程');

          // 执行续期
          final success = await _performTokenRenewal();

          if (success) {
            _renewalState = TokenRenewalState.success;
            _lastRenewalTime = DateTime.now();
            _logger.info('续期成功，开始重试队列中的请求');

            // 重试所有缓存的请求
            await _retryAllPendingRequests();
          } else {
            _renewalState = TokenRenewalState.failed;
            _logger.warning('续期失败，完成所有等待的请求（使用原始响应）');

            // 续期失败，使用原始响应完成所有等待的请求（fire-and-forget）
            _completeAllPendingRequestsWithOriginalResponse();
          }

          // 完成续期Completer
          if (!_renewalCompleter!.isCompleted) {
            _renewalCompleter!.complete(success);
          }
        } catch (e) {
          _logger.error('续期过程中出错: $e');

          // 出错时，使用原始响应完成所有等待的请求（fire-and-forget）
          _completeAllPendingRequestsWithOriginalResponse();

          // 完成续期Completer
          if (!_renewalCompleter!.isCompleted) {
            _renewalCompleter!.complete(false);
          }

          _renewalState = TokenRenewalState.failed;
        } finally {
          // 延迟重置状态，确保所有请求都有时间处理
          Future.delayed(Duration(seconds: 3), () {
            if (_renewalState != TokenRenewalState.renewing) {
              _renewalState = TokenRenewalState.idle;
            }
          });
        }
      });
    });
  }

  /// 处理续期请求的响应
  Future<void> _handleRenewalResponse(
      Response response, ResponseInterceptorHandler handler) async {
    // 如果不是第一个续期请求，等待已有的续期完成
    if (_renewalState == TokenRenewalState.renewing &&
        _renewalCompleter != null) {
      _logger.debug('已有被动续期请求在执行，等待被动续期完成: ${response.requestOptions.path}');

      try {
        // 等待续期完成
        final success = await _renewalCompleter!.future.timeout(
          Duration(seconds: 10),
          onTimeout: () {
            _logger.warning('等待被动续期超时');
            return false;
          },
        );

        if (success) {
          // 获取最新token
          if (_tokenSupplier != null) {
            final token = await _tokenSupplier!.getToken();
            if (token != null && token.isNotEmpty) {
              // 构建成功响应
              final successResponse = Response(
                requestOptions: response.requestOptions,
                statusCode: 200,
                data: {
                  'code': 0,
                  'message': 'Token renewal successful',
                  'data': {'token': token, 'expires': 7200}
                },
              );
              return handler.next(successResponse);
            }
          }
        }
      } catch (e) {
        _logger.error('等待被动续期出错: $e');
      }

      // 如果等待失败，返回原始响应
      return handler.next(response);
    }

    // 这是第一个续期请求，处理它
    try {
      _logger.info('处理续期请求: ${response.requestOptions.path}');

      // 设置状态为正在续期
      _renewalState = TokenRenewalState.renewing;
      _renewalCompleter = Completer<bool>();

      // 处理续期响应
      final success = await _processRenewalResponse(response.data);

      if (success) {
        _renewalState = TokenRenewalState.success;
        _lastRenewalTime = DateTime.now();

        // 重试所有等待的请求
        await _retryAllPendingRequests();
      } else {
        _renewalState = TokenRenewalState.failed;

        // 完成所有等待的请求（使用原始响应，fire-and-forget）
        _completeAllPendingRequestsWithOriginalResponse();
      }

      // 完成续期Completer
      if (!_renewalCompleter!.isCompleted) {
        _renewalCompleter!.complete(success);
      }

      // 延迟重置状态
      Future.delayed(Duration(seconds: 3), () {
        _renewalState = TokenRenewalState.idle;
      });

      return handler.next(response);
    } catch (e) {
      _logger.error('处理续期请求出错: $e');

      // 重置状态
      _renewalState = TokenRenewalState.failed;

      // 完成续期Completer
      if (_renewalCompleter != null && !_renewalCompleter!.isCompleted) {
        _renewalCompleter!.complete(false);
      }

      return handler.next(response);
    }
  }

  /// 执行token续期
  Future<bool> _performTokenRenewal() async {
    try {
      // 检查是否在短时间内已经续期过
      if (_lastRenewalTime != null) {
        final timeSinceLastRenewal =
            DateTime.now().difference(_lastRenewalTime!);
        if (timeSinceLastRenewal < Duration(seconds: 5)) {
          _logger.debug('最近已经续期过，跳过本次续期');
          return true;
        }
      }

      // 创建续期请求参数
      final username = _tokenSupplier != null ? await _tokenSupplier!.getUsername() : null;
      final params = <String, dynamic>{
        'Client': 10,
        'UserFlag': username ?? '',
      };
      final headers = <String, dynamic>{
        'Content-type': 'application/json',
        'accessKeyId': const String.fromEnvironment('ovsx-app-token'),
        'version': HttpConstant.Version,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'signType': HttpConstant.SignType.toString(),
        'nonce': Uuid().v4(),
        'token': '',
        'sign': '',
      };
      final token = _tokenSupplier != null ? await _tokenSupplier!.getToken() : null;
      if (token != null && token.isNotEmpty) {
        headers['token'] = token;
      }
      final url = (HttpConstant.IsRelease
          ? Uri.https(HttpConstant.Http_Host, ApiBase.tokenRenewal)
          : Uri.http(HttpConstant.Http_Host, ApiBase.tokenRenewal)).toString();

      // 执行续期请求
      final response = await _executeRenewalRequest(
        url: url,
        params: params,
        headers: headers,
        cancelToken: CancelToken(),
      );

      // 处理续期响应
      if (response.statusCode == 200) {
        return await _processRenewalResponse(response.data);
      }

      _logger.warning('续期失败，状态码: ${response.statusCode}');
      return false;
    } catch (e) {
      _logger.error('执行续期操作时出错: $e');
      return false;
    }
  }

  /// 处理续期响应数据
  Future<bool> _processRenewalResponse(dynamic responseData) async {
    try {
      final data =
          responseData is String ? jsonDecode(responseData) : responseData;
      final code = data['code'];

      _logger.debug('续期响应解析，code: $code');

      if (code == HttpConstant.reLoginCode) {
        _logger.warning('服务器返回需要重新登录的状态');
        HttpEventBus.instance.commit(EventKeys.logout);
        return false;
      }

      if (code == 0 && data['data']?['token'] != null) {
        final newToken = data['data']['token'];
        final tokenPreview =
            newToken.length > 10 ? newToken.substring(0, 10) + '...' : newToken;

        _logger.info('获取到新token: $tokenPreview');
        if (_tokenSupplier != null) {
          await _tokenSupplier!.setToken(newToken);
        }
        return true;
      }

      _logger.warning('续期失败，未获取到有效token');
      return false;
    } catch (e) {
      _logger.error('处理续期响应异常: $e');
      return false;
    }
  }

  /// 重试所有等待的请求
  Future<void> _retryAllPendingRequests() async {
    if (_pendingRequests.isEmpty) {
      return;
    }

    _logger.debug('开始重试队列中的请求，数量: ${_pendingRequests.length}');

    // 复制请求集合，避免并发修改
    final requests = List<_PendingRequest>.from(_pendingRequests);

    // 按时间戳排序，优先处理较早的请求
    requests.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 清空队列
    _pendingRequests.clear();

    // 分批处理请求，每批最多5个
    const batchSize = 5;
    for (int i = 0; i < requests.length; i += batchSize) {
      final end =
          (i + batchSize < requests.length) ? i + batchSize : requests.length;
      final batch = requests.sublist(i, end);

      // 并行处理每一批请求
      await Future.wait(
        batch.map((request) async {
          try {
            _logger.debug('重试队列中的请求: ${request.requestOptions.path}');

            // 重试请求，失败时自动重试一次
            final response =
                await _retryRequestWithRetry(request.requestOptions);

            if (response != null) {
              // 使用重试成功的响应完成Completer
              request.completer.complete(response);
            } else {
              // 重试失败，使用原始响应完成Completer
              request.completer.complete(request.originalResponse);
            }
          } catch (e) {
            _logger.warning('重试请求失败: ${request.requestOptions.path}, 错误: $e');

            // 出错时，使用原始响应完成Completer
            request.completer.complete(request.originalResponse);
          }
        }),
      );

      // 批次间添加短暂延迟，避免请求风暴
      if (end < requests.length) {
        await Future.delayed(Duration(milliseconds: 50));
      }
    }

    _logger.info('所有队列请求重试完成');
  }

  /// 使用原始响应完成所有等待的请求
  /// 注意：此方法设计为 fire-and-forget，不阻塞续期流程
  void _completeAllPendingRequestsWithOriginalResponse() {
    if (_pendingRequests.isEmpty) {
      return;
    }

    _logger.debug('开始完成所有等待的请求（使用原始响应），数量: ${_pendingRequests.length}');

    // 复制请求集合，避免并发修改
    final requests = List<_PendingRequest>.from(_pendingRequests);

    // 按时间戳排序，优先处理较早的请求
    requests.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 清空队列
    _pendingRequests.clear();

    // 分批处理请求，每批最多10个
    const batchSize = 10;
    for (int i = 0; i < requests.length; i += batchSize) {
      final end =
          (i + batchSize < requests.length) ? i + batchSize : requests.length;
      final batch = requests.sublist(i, end);

      // 并行处理每一批请求（fire-and-forget，不阻塞）
      Future.wait(
        batch.map((request) async {
          try {
            _logger.debug('完成等待的请求: ${request.requestOptions.path}');

            // 使用原始响应完成Completer
            request.completer.complete(request.originalResponse);
          } catch (e) {
            _logger.warning('完成等待的请求失败: ${request.requestOptions.path}, 错误: $e');
          }
        }),
      );

      // 批次间添加短暂延迟，避免请求风暴（fire-and-forget）
      if (end < requests.length) {
        Future.delayed(Duration(milliseconds: 50));
      }
    }

    _logger.info('所有等待的请求完成');
  }

  /// 重试单个请求，失败时重试一次
  Future<Response?> _retryRequestWithRetry(
      RequestOptions requestOptions) async {
    try {
      // 第一次尝试
      return await _retryRequest(requestOptions);
    } catch (e) {
      _logger.warning('第一次重试失败，尝试再次重试: ${requestOptions.path}, 错误: $e');

      try {
        // 短暂延迟后第二次尝试
        await Future.delayed(Duration(milliseconds: 200));
        return await _retryRequest(requestOptions);
      } catch (e) {
        _logger.warning('第二次重试也失败，放弃重试: ${requestOptions.path}, 错误: $e');
        return null;
      }
    }
  }

  /// 重试单个请求
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    // 获取最新token
    final token = _tokenSupplier != null ? await _tokenSupplier!.getToken() : null;
    final _headers = requestOptions.headers;
    final _token = _headers['token'];
    if (_token != null && _token is String && _token.isNotEmpty) {
      _headers['token'] = token;
    }

    // 创建新的请求选项，保留原始请求的所有参数
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

    // 执行请求
    return await _dio.request(
      requestOptions.path,
      options: options,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
    );
  }

  /// 检查是否需要续期
  Future<bool> _shouldRenewToken(Response response) async {
    try {
      // 检查响应状态
      final data =
          response.data is String ? jsonDecode(response.data) : response.data;
      return data['code'] == HttpConstant.reTokenCode;
    } catch (e) {
      _logger.error('解析响应数据出错: $e');
      return false;
    }
  }

  /// 执行续期请求
  Future<Response> _executeRenewalRequest({required String url, required Map<String, dynamic> params, required Map<String, dynamic> headers, required CancelToken cancelToken}) async {
    // 创建专用的Dio实例用于续期请求
    final tokenDio = Dio()..interceptors.add(HeaderInterceptor());
    _configureProxy(tokenDio);

    _logger.debug('准备发送续期请求: $url');

    // 执行请求
    final response = await tokenDio.post(
      url,
      data: params,
      options: Options(
        headers: headers,
        validateStatus: (status) => true, // 接受所有状态码
        receiveTimeout: Duration(seconds: HttpConstant.ReceiveTimeout),
        sendTimeout: Duration(seconds: HttpConstant.SendTimeout),
      ),
    );

    _logger.debug('续期请求返回状态码: ${response.statusCode}');
    return response;
  }

  /// 配置代理
  void _configureProxy(Dio dio) {
    if (!HttpConstant.Proxy_Enable) return;

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (uri) {
          return 'PROXY ${HttpConstant.Proxy_Ip}:${HttpConstant.Proxy_Port}';
        };
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );
  }
}
