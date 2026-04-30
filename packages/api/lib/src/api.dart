import 'dio/dio_adapter.dart';
import 'http/http_manager.dart';
import 'http/token_supplier.dart';
import 'http/app_logger.dart';
import 'modules/modules.dart';

typedef UserTokenSupplier = Future<String?> Function();
typedef NetworkDisconnectedCallback = void Function();

/// API Client — Core HTTP class with mixin pattern
class Api extends ApiBase with DemoApiMixin {
  static bool testToken = false;

  final HttpManager _httpManager;
  final UserTokenSupplier _userTokenSupplier;
  final NetworkDisconnectedCallback? _networkDisconnectedCallback;

  Api({
    required UserTokenSupplier userTokenSupplier,
    NetworkDisconnectedCallback? networkDisconnectedCallback,
    HttpManager? http,
  })  : _userTokenSupplier = userTokenSupplier,
        _networkDisconnectedCallback = networkDisconnectedCallback,
        _httpManager = http ?? HttpManager.getInstance() {
    _httpManager.userTokenSupplier = _userTokenSupplier;
    if (_networkDisconnectedCallback != null) {
      _httpManager.networkDisconnectedCallBack = _networkDisconnectedCallback!;
    }
  }

  @override
  HttpManager get httpManager => _httpManager;

  /// 设置TokenSupplier
  void setTokenSupplier(TokenSupplier supplier) {
    _httpManager.tokenSupplier = supplier;
  }

  /// 设置Logger到Token续期拦截器
  ///
  /// 在App启动后注入，替换默认debugPrint输出
  /// 主应用的AppLogger需实现AppLoggerInterface接口
  void setLogger(AppLoggerInterface logger) {
    (_httpManager.http as DioAdapter).logger = logger;
  }

  @override
  Map<String, dynamic>? get ossTokenData => null;

  @override
  set ossTokenData(Map<String, dynamic>? value) {}

  @override
  Future<List<Map<String, dynamic>>> queryConfig() async {
    return [];
  }
}
