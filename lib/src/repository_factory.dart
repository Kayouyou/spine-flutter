import 'package:flutter/foundation.dart';
import 'package:api/api.dart';
import 'package:key_value_storage/key_value_storage.dart';

/// Repository Factory — creates and manages repository instances
class RepositoryFactory {
  final KeyValueStorage keyValueStorage;
  late final Api api;

  RepositoryFactory({required this.keyValueStorage}) {
    _initialize();
  }

  void _initialize() {
    debugPrint('🚀 [RepositoryFactory] Phase 1: Api');
    api = Api(
      userTokenSupplier: () => Future.value(null),
      networkDisconnectedCallback: () => debugPrint('Network disconnected'),
    );
    debugPrint('🚀 [RepositoryFactory] Phase 2: Ready');
  }
}
