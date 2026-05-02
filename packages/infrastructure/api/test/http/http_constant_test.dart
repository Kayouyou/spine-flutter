import 'package:flutter_test/flutter_test.dart';
import 'package:api/src/http/http_constant.dart';

void main() {
  group('HttpConstant — keys from dart-define', () {
    test('AccessKeyId returns empty string when dart-define not set', () {
      expect(HttpConstant.AccessKeyId, isEmpty,
          reason: 'AccessKeyId must be from dart-define (String.fromEnvironment), not hardcoded');
    });

    test('AliyunOSS AccessKey returns empty when dart-define not set', () {
      expect(AliyunOSSConstant.AccessKey, isEmpty,
          reason: 'OSS AccessKey must be from dart-define, not hardcoded');
    });
  });
}
