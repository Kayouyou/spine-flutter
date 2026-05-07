import 'package:key_value_storage/key_value_storage.dart';

class TokenStorage {
  TokenStorage(this._keyValueStorage);
  final KeyValueStorage _keyValueStorage;

  Future<String?> getToken() async {
    return _keyValueStorage.getString(PreferenceKey.authToken.rawKey);
  }

  Future<void> setToken(String token) async {
    await _keyValueStorage.putString(PreferenceKey.authToken.rawKey, token);
  }

  Future<String?> getUserId() async {
    return _keyValueStorage.getString(PreferenceKey.authUserId.rawKey);
  }

  Future<void> setUserId(String userId) async {
    await _keyValueStorage.putString(PreferenceKey.authUserId.rawKey, userId);
  }

  Future<void> clear() async {
    await _keyValueStorage.delete(PreferenceKey.authToken.rawKey);
    await _keyValueStorage.delete(PreferenceKey.authUserId.rawKey);
  }
}
