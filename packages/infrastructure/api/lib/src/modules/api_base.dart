import 'package:api/src/http/http_manager.dart';

/// Abstract base class providing common dependencies for API mixins.
abstract class ApiBase {
  /// Provides access to the HTTP manager instance.
  HttpManager get httpManager;

  /// Provides access to the application configuration query function.
  Future<List<Map<String, dynamic>>> queryConfig();

  /// Getter for the OSS token data.
  Map<String, dynamic>? get ossTokenData;

  /// Setter for the OSS token data.
  set ossTokenData(Map<String, dynamic>? value);
}
