import 'package:api/api.dart';
import '../../http/http_method.dart';

/// Demo API mixin — example for scaffold users
mixin DemoApiMixin on ApiBase {
  /// Health check endpoint
  Future<dynamic> healthCheck() async {
    return httpManager.fireInternal(
      path: '/api/demo/health',
      method: HttpMethod.GET,
      needLogin: false,
    );
  }
}
