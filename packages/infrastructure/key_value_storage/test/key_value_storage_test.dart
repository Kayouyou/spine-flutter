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

    test('authToken has string valueType', () {
      expect(PreferenceKey.authToken.valueType, StorageValueType.string);
    });

    test('agreePrivacyAndProtocol has bool valueType', () {
      expect(PreferenceKey.agreePrivacyAndProtocol.valueType, StorageValueType.bool);
    });

    test('carEventInputLimit has int valueType', () {
      expect(PreferenceKey.carEventInputLimit.valueType, StorageValueType.int);
    });

    test('authToken has auth group', () {
      expect(PreferenceKey.authToken.group, PreferenceKeyGroup.auth);
    });

    test('locationCityName has location group', () {
      expect(PreferenceKey.locationCityName.group, PreferenceKeyGroup.location);
    });

    test('agreePrivacyAndProtocol has privacy group', () {
      expect(PreferenceKey.agreePrivacyAndProtocol.group, PreferenceKeyGroup.privacy);
    });

    test('keysInGroup returns correct keys', () {
      final authKeys = PreferenceKey.keysInGroup(PreferenceKeyGroup.auth);
      expect(authKeys, contains(PreferenceKey.authToken));
      expect(authKeys, contains(PreferenceKey.authUserId));
      expect(authKeys, contains(PreferenceKey.loginByUserName));
    });

    test('all keys have non-empty rawKey', () {
      for (final key in PreferenceKey.values) {
        expect(key.rawKey, isNotEmpty);
      }
    });
  });
}
