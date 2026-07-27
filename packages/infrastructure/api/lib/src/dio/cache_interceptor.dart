import 'package:dio/dio.dart';

import '../http/app_logger.dart';

/// 缓存策略（与后端无关，纯客户端缓存语义）
enum CacheStrategy {
  /// 不缓存（默认；对现有请求完全透明，零行为变化）
  none,

  /// 缓存优先：命中且未过期直接返回缓存；否则走网络并在响应后写入缓存
  cacheFirst,

  /// 网络优先：先走网络，成功后写入缓存；网络失败且有新鲜缓存则回退缓存
  networkFirst,

  /// 仅缓存：只返回缓存，未命中直接失败（不发起网络请求）
  cacheOnly,

  /// 仅网络：永不走缓存（等价于 none，保留以对齐 Gitee 语义）
  networkOnly,
}

/// 缓存存储抽象
///
/// 解耦具体存储介质，便于测试与后续替换为持久化实现。
/// 默认实现为内存 + TTL 的 [MemoryCacheStore]。
/// 注：分页列表端点的专用缓存请使用项目已有的 [ListCacheManager]（仓储层），
/// 本拦截器面向“通用 GET 响应”的轻量缓存。
abstract class CacheStore {
  /// 读取缓存；不存在或已过期返回 null
  dynamic get(String key);

  /// 写入缓存，[maxAge] 为有效期
  void set(String key, dynamic data, Duration maxAge);

  /// 是否存在且未过期的缓存
  bool isFresh(String key);

  /// 清空全部缓存
  void clear();
}

class _Entry {
  _Entry(this.data, this.expireAt);
  final dynamic data;
  final DateTime expireAt;
}

/// 内存缓存存储（带 TTL）
class MemoryCacheStore implements CacheStore {
  final Map<String, _Entry> _store = {};

  @override
  dynamic get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.expireAt.isBefore(DateTime.now())) {
      _store.remove(key);
      return null;
    }
    return entry.data;
  }

  @override
  void set(String key, dynamic data, Duration maxAge) {
    _store[key] = _Entry(data, DateTime.now().add(maxAge));
  }

  @override
  bool isFresh(String key) {
    final entry = _store[key];
    if (entry == null) return false;
    if (entry.expireAt.isBefore(DateTime.now())) {
      _store.remove(key);
      return false;
    }
    return true;
  }

  @override
  void clear() => _store.clear();
}

/// 通用 GET 响应缓存拦截器（P1）
///
/// 通过请求 `extra` 控制：
/// - `extra['cacheStrategy']`：`CacheStrategy`，不设置则默认 [CacheStrategy.none]（透明）。
/// - `extra['cacheMaxAge']`：`Duration`，缓存有效期，默认 5 分钟。
///
/// 仅对 GET 请求生效；非 GET 自动退化为 none。
/// R3 合规：仅依赖 dio / infra 内部，不引入 UI/Flutter 之外的反依赖。
class CacheInterceptor extends Interceptor {
  CacheInterceptor({
    CacheStore? store,
    AppLoggerInterface? logger,
  })  : _store = store ?? MemoryCacheStore(),
        _logger = logger ?? DefaultLogger();

  final CacheStore _store;
  final AppLoggerInterface _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final strategy = _getStrategy(options);

    if (strategy == CacheStrategy.none ||
        strategy == CacheStrategy.networkOnly) {
      return handler.next(options);
    }

    final key = _cacheKey(options);

    if (strategy == CacheStrategy.cacheOnly) {
      final cached = _store.get(key);
      if (cached != null) {
        _logger.debug('[Cache] cacheOnly 命中: $key');
        return handler.resolve(
          _cachedResponse(options, cached, cacheOnError: false),
          true,
        );
      }
      _logger.debug('[Cache] cacheOnly 未命中: $key');
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          error: 'Cache miss',
        ),
        true,
      );
    }

    if (strategy == CacheStrategy.cacheFirst) {
      final cached = _store.get(key);
      if (cached != null) {
        _logger.debug('[Cache] cacheFirst 命中: $key');
        return handler.resolve(
          _cachedResponse(options, cached, cacheOnError: false),
          true,
        );
      }
      // 未命中：继续走网络，响应阶段写入缓存
      return handler.next(options);
    }

    // networkFirst：先走网络，命中缓存仅用于错误回退
    return handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final strategy = _getStrategy(response.requestOptions);
    if (strategy == CacheStrategy.none ||
        strategy == CacheStrategy.cacheOnly ||
        strategy == CacheStrategy.networkOnly) {
      return handler.next(response);
    }

    if (response.statusCode == 200 && response.data != null) {
      final key = _cacheKey(response.requestOptions);
      final maxAge = _getMaxAge(response.requestOptions);
      _store.set(key, response.data, maxAge);
      _logger.debug('[Cache] 写入缓存: $key, 有效期: ${maxAge.inSeconds}s');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final strategy = _getStrategy(err.requestOptions);
    if (strategy == CacheStrategy.networkFirst) {
      final key = _cacheKey(err.requestOptions);
      final cached = _store.get(key);
      if (cached != null) {
        _logger.debug('[Cache] 网络错误，回退缓存: $key');
        return handler.resolve(
          _cachedResponse(err.requestOptions, cached, cacheOnError: true),
        );
      }
    }
    return handler.next(err);
  }

  CacheStrategy _getStrategy(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') return CacheStrategy.none;
    final s = options.extra['cacheStrategy'];
    if (s is CacheStrategy) return s;
    return CacheStrategy.none; // 默认透明，不缓存（与 Gitee 默认 networkFirst 不同，避免影响既有请求）
  }

  Duration _getMaxAge(RequestOptions options) {
    final maxAge = options.extra['cacheMaxAge'];
    if (maxAge is Duration) return maxAge;
    return const Duration(minutes: 5);
  }

  String _cacheKey(RequestOptions options) {
    final params = options.queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return params.isNotEmpty ? '${options.method}/${options.path}?$params' : '${options.method}/${options.path}';
  }

  Response<dynamic> _cachedResponse(
    RequestOptions options,
    dynamic data, {
    required bool cacheOnError,
  }) =>
      Response<dynamic>(
        requestOptions: options,
        data: data,
        statusCode: 200,
        extra: {'fromCache': true, 'cacheOnError': cacheOnError},
      );
}
