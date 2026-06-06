import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_value_storage/key_value_storage.dart';

import 'package:api/src/http/http_constant.dart';
import 'package:api/src/http/http_event_bus.dart';
import 'package:api/src/refresh/refresh_api.dart';

void main() {
  group('shouldRenewToken', () {
    test('code == reTokenCode 返回 true', () async {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
        data: '{"code": ${HttpConstant.reTokenCode}, "data": null}',
        statusCode: 200,
      );
      expect(await shouldRenewToken(response), isTrue);
    });

    test('其他 code 返回 false', () async {
      final response = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
        data: '{"code": 0, "data": null}',
      );
      expect(await shouldRenewToken(response), isFalse);
    });

    test('非 JSON / null data 返回 false', () async {
      final r1 = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
      );
      final r2 = Response<dynamic>(
        requestOptions: RequestOptions(path: '/a'),
        data: 'plain text',
        statusCode: 200,
      );
      expect(await shouldRenewToken(r1), isFalse);
      expect(await shouldRenewToken(r2), isFalse);
    });
  });

  group('processRenewalResponse', () {
    test('code == reLoginCode: 触发 logout 事件, 返回 false', () async {
      final storage = _RecordingTokenStorage();
      var logoutFired = false;
      HttpEventBus.instance.addListener(EventKeys.logout, () {
        logoutFired = true;
      });
      addTearDown(() => HttpEventBus.instance.removeListener(EventKeys.logout));

      final data = jsonEncode({'code': HttpConstant.reLoginCode});
      final result = await processRenewalResponse(data, storage);

      expect(result, isFalse);
      expect(logoutFired, isTrue);
      expect(storage.setCount, equals(0));
    });

    test('code == 0 + 含 token: 写入 storage, 返回 true', () async {
      final storage = _RecordingTokenStorage();
      final data = jsonEncode({
        'code': 0,
        'data': {'token': 'new-token-abc'},
      });

      final result = await processRenewalResponse(data, storage);

      expect(result, isTrue);
      expect(storage.lastWritten, equals('new-token-abc'));
    });

    test('code == 0 + 无 token: 不写 storage, 返回 false', () async {
      final storage = _RecordingTokenStorage();
      final data = jsonEncode({'code': 0, 'data': null});

      final result = await processRenewalResponse(data, storage);

      expect(result, isFalse);
      expect(storage.setCount, equals(0));
    });

    test('null storage: code == 0 + 含 token: 返回 true 不抛', () async {
      final data = jsonEncode({
        'code': 0,
        'data': {'token': 'new-token-abc'},
      });

      final result = await processRenewalResponse(data, null);

      expect(result, isTrue);
    });

    test('非 JSON / 异常 data: 返回 false 不抛', () async {
      final storage = _RecordingTokenStorage();
      final result = await processRenewalResponse('not json {{{', storage);
      expect(result, isFalse);
      expect(storage.setCount, equals(0));
    });
  });
}

class _RecordingTokenStorage implements TokenStorage {
  String? lastWritten;
  int setCount = 0;

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> setToken(String token) async {
    lastWritten = token;
    setCount++;
  }

  @override
  Future<String?> getUserId() async => null;

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> clear() async {}
}

