import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'preference_key.dart';

class PreferencesService {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<void> setString(PreferenceKey key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key.rawKey, value);
  }

  Future<String?> getString(PreferenceKey key) async {
    final prefs = await _prefs;
    return prefs.getString(key.rawKey);
  }

  Future<void> setInt(PreferenceKey key, int value) async {
    final prefs = await _prefs;
    await prefs.setInt(key.rawKey, value);
  }

  Future<int?> getInt(PreferenceKey key) async {
    final prefs = await _prefs;
    return prefs.getInt(key.rawKey);
  }

  Future<void> setBool(PreferenceKey key, bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(key.rawKey, value);
  }

  Future<bool?> getBool(PreferenceKey key) async {
    final prefs = await _prefs;
    return prefs.getBool(key.rawKey) ?? false;
  }

  Future<void> saveMap(Map<String, dynamic> map, PreferenceKey key) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(map);
    await prefs.setString(key.rawKey, jsonString);
  }

  Future<Map<String, dynamic>> readMapFromSharedPreferences(
      PreferenceKey key,) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(key.rawKey);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    } else {
      return {};
    }
  }

  Future<void> saveListMap(List<dynamic> dataList, PreferenceKey key) async {
    final jsonString = jsonEncode(dataList);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key.rawKey, jsonString);
  }

  Future<List<dynamic>> readListMap(PreferenceKey key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key.rawKey);
    return jsonString != null
        ? jsonDecode(jsonString) as List<dynamic>
        : [];
  }

  Future<bool> remove(PreferenceKey key) async {
    final prefs = await _prefs;
    return await prefs.remove(key.rawKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    final privacyProtocol =
        prefs.getBool(PreferenceKey.agreePrivacyAndProtocol.rawKey);
    final driverLicense =
        prefs.getBool(PreferenceKey.agreePrivacyDriverLicense.rawKey);
    final firstLaunchOnboardingCompleted = prefs
        .getBool(PreferenceKey.firstLaunchOnboardingCompleted.rawKey);

    debugPrint(
        'PreferencesService.clear() - 保存的值: privacy=$privacyProtocol, driver=$driverLicense, onboarding=$firstLaunchOnboardingCompleted',);

    await prefs.clear();

    if (privacyProtocol == true) {
      await prefs.setBool(
          PreferenceKey.agreePrivacyAndProtocol.rawKey, true,);
      debugPrint(
          'PreferencesService.clear() - 已恢复AgreePrivacyAndProtocol为true',);
    } else {
      debugPrint(
          'PreferencesService.clear() - AgreePrivacyAndProtocol未恢复，原值为: $privacyProtocol',);
    }

    if (driverLicense == true) {
      await prefs.setBool(
          PreferenceKey.agreePrivacyDriverLicense.rawKey, true,);
      debugPrint(
          'PreferencesService.clear() - 已恢复AgreePrivacyDriverLicense为true',);
    }

    if (firstLaunchOnboardingCompleted == true) {
      await prefs.setBool(
          PreferenceKey.firstLaunchOnboardingCompleted.rawKey, true,);
      debugPrint(
          'PreferencesService.clear() - 已恢复FirstLaunchOnboardingCompleted为true',);
    }
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
