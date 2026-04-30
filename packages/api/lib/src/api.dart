import 'package:key_value_storage/key_value_storage.dart';

import 'http/http_manager.dart';
import 'http/token_supplier.dart';
import 'http/http_method.dart';
import 'modules/modules.dart';

typedef UserTokenSupplier = Future<String?> Function();
typedef NetworkDisconnectedCallback = void Function();

/// API Client — Core HTTP class with mixin pattern
class Api extends ApiBase with DemoApiMixin {
  static bool testToken = false;

  final HttpManager _httpManager;
  final UserTokenSupplier _userTokenSupplier;
  final NetworkDisconnectedCallback _networkDisconnectedCallback;

  Api({
    required UserTokenSupplier userTokenSupplier,
    required NetworkDisconnectedCallback networkDisconnectedCallback,
    HttpManager? http,
  })  : _userTokenSupplier = userTokenSupplier,
        _networkDisconnectedCallback = networkDisconnectedCallback,
        _httpManager = http ?? HttpManager.getInstance() {
    _httpManager.userTokenSupplier = _userTokenSupplier;
    _httpManager.networkDisconnectedCallBack = _networkDisconnectedCallback;
  }

  @override
  HttpManager get httpManager => _httpManager;

  void setTokenSupplier(TokenSupplier supplier) {
    _httpManager.tokenSupplier = supplier;
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
