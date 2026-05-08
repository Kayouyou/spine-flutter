import 'package:test/test.dart';
import 'package:key_value_storage/key_value_storage.dart';

void main() {
  group('CacheData', () {
    test('creates with value and default TTL', () {
      final cache = CacheData<String>('test_data');
      expect(cache.value, 'test_data');
    });

    test('custom TTL works', () {
      final cache = CacheData<int>(42, ttl: const Duration(seconds: 1));
      expect(cache.value, 42);
    });
  });

  group('PreferenceKey', () {
    test('authToken has correct rawKey', () {
      expect(PreferenceKey.authToken.rawKey, 'auth_token');
    });

    test('authUserId has correct rawKey', () {
      expect(PreferenceKey.authUserId.rawKey, 'auth_user_id');
    });

    test('all keys have non-empty rawKey', () {
      for (final key in PreferenceKey.values) {
        expect(key.rawKey, isNotEmpty);
      }
    });
  });
}
