import 'package:key_value_storage/key_value_storage.dart';

class TokenStorage {
  TokenStorage(this._keyValueStorage);
  final KeyValueStorage _keyValueStorage;

  Future<String?> getToken() async {
    return _keyValueStorage.getString(PreferenceKey.authToken);
  }

  Future<void> setToken(String token) async {
    await _keyValueStorage.putString(PreferenceKey.authToken, token);
  }

  Future<String?> getUserId() async {
    return _keyValueStorage.getString(PreferenceKey.authUserId);
  }

  Future<void> setUserId(String userId) async {
    await _keyValueStorage.putString(PreferenceKey.authUserId, userId);
  }

  Future<void> clear() async {
    await _keyValueStorage.delete(PreferenceKey.authToken);
    await _keyValueStorage.delete(PreferenceKey.authUserId);
  }
}
