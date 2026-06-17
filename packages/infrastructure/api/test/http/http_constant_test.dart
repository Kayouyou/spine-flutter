import 'package:flutter_test/flutter_test.dart';
import 'package:api/src/http/http_constant.dart';

void main() {
  group('HttpConstant — keys from dart-define', () {
    test('AliyunOSS AccessKey returns empty when dart-define not set', () {
      expect(AliyunOSSConstant.AccessKey, isEmpty,
          reason: 'OSS AccessKey must be from dart-define (String.fromEnvironment), not hardcoded',);
    });

    test('proxyIp 返回空 (无 dart-define)', () {
      // proxyIp 改为 getter, 默认空字符串 (无 dart-define)
      expect(HttpConstant.proxyIp, isEmpty,
          reason: 'proxyIp 必须从 dart-define PROXY_IP 读取, 不在源码硬编码',);
    });
  });

  group('HttpConstant — 业务常量保留', () {
    test('业务错误码不变', () {
      expect(HttpConstant.reTokenCode, equals(1000102));
      expect(HttpConstant.reLoginCode, equals(1000103));
      expect(HttpConstant.NetworkErrorCode, equals(-1111));
      expect(HttpConstant.UnknownErrorCode, equals(-1));
      expect(HttpConstant.OssTokenErrorCode, equals(1111));
    });

    test('请求签名 metadata 不变', () {
      expect(HttpConstant.Version, equals('v1.0'));
      expect(HttpConstant.SignType, equals(101));
      expect(HttpConstant.Client, equals(10));
    });

    test('网络超时不变', () {
      expect(HttpConstant.ReceiveTimeout, equals(15000));
      expect(HttpConstant.ConnectTimeout, equals(15000));
      expect(HttpConstant.SendTimeout, equals(15000));
    });
  });
}