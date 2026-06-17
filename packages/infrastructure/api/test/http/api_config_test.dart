import 'package:flutter_test/flutter_test.dart';
import 'package:api/src/http/api_config.dart';
import 'package:domain/domain.dart';

/// ApiConfig 注入契约测试
///
/// 验证:
/// 1. EnvApiConfig 从 IAppConfig 正确读取字段 (替代原 HttpConstant 硬编码)
/// 2. ossPublicUrl 拼接正确
/// 3. isRelease 反映 IAppConfig.isProd
void main() {
  group('EnvApiConfig', () {
    test('host 从 IAppConfig.apiHost 读取', () {
      final fake = _FakeAppConfig(
        apiHost: 'api.example.com',
        isProd: true,
      );
      final config = EnvApiConfig(fake);
      expect(config.host, equals('api.example.com'));
    });

    test('isRelease 等于 IAppConfig.isProd', () {
      final devConfig = EnvApiConfig(_FakeAppConfig(apiHost: 'h', isProd: false));
      expect(devConfig.isRelease, isFalse);

      final prodConfig = EnvApiConfig(_FakeAppConfig(apiHost: 'h', isProd: true));
      expect(prodConfig.isRelease, isTrue);
    });

    test('accessKeyId 从 IAppConfig.apiAccessKeyId 读取', () {
      final config = EnvApiConfig(
        _FakeAppConfig(apiHost: 'h', apiAccessKeyId: 'secret-key-123'),
      );
      expect(config.accessKeyId, equals('secret-key-123'));
    });

    test('ossBucket + ossEndpoint 从 IAppConfig 读取', () {
      final config = EnvApiConfig(
        _FakeAppConfig(
          apiHost: 'h',
          ossBucket: 'my-bucket',
          ossEndpoint: 'https://oss-cn-zhangjiakou.aliyuncs.com',
        ),
      );
      expect(config.ossBucket, equals('my-bucket'));
      expect(config.ossEndpoint, equals('https://oss-cn-zhangjiakou.aliyuncs.com'));
    });

    test('ossPublicUrl 拼接: https://{bucket}.{host}', () {
      final config = EnvApiConfig(
        _FakeAppConfig(
          apiHost: 'h',
          ossBucket: 'ovsx-usr',
          ossEndpoint: 'https://oss-cn-zhangjiakou.aliyuncs.com',
        ),
      );
      expect(
        config.ossPublicUrl,
        equals('https://ovsx-usr.oss-cn-zhangjiakou.aliyuncs.com'),
      );
    });

    test('ossPublicUrl 处理 endpoint 无协议情况', () {
      // 容错: 即使 endpoint 没带 https:// 前缀, 也能正确提取 host
      final config = EnvApiConfig(
        _FakeAppConfig(
          apiHost: 'h',
          ossBucket: 'b',
          ossEndpoint: 'oss-cn-zhangjiakou.aliyuncs.com',
        ),
      );
      expect(config.ossPublicUrl, equals('https://b.oss-cn-zhangjiakou.aliyuncs.com'));
    });
  });
}

class _FakeAppConfig implements IAppConfig {
  _FakeAppConfig({
    required this.apiHost,
    this.isProd = false,
    this.apiAccessKeyId = 'fake-key',
    this.ossBucket = 'fake-bucket',
    this.ossEndpoint = 'https://fake.oss.aliyuncs.com',
    this.ossAccessKey = 'fake-oss-key',
  });

  @override
  final String apiHost;
  @override
  final bool isProd;
  @override
  final String apiAccessKeyId;
  @override
  final String ossBucket;
  @override
  final String ossEndpoint;
  @override
  final String ossAccessKey;

  @override
  bool get isDev => !isProd;
  @override
  bool get enableDebugLog => !isProd;
  @override
  bool get enableAuthGuard => true;
  @override
  String get apiBaseUrl => 'https://$apiHost';
  @override
  int get networkTimeout => 30;
  @override
  String get sentryDsn => '';
  @override
  String get appStoreId => '';
}