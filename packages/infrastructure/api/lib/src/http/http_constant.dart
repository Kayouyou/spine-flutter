import 'package:flutter/foundation.dart';

class HttpConstant {
  static const bool IsRelease = !kDebugMode; // 正式/测试环境切换

  static const String Http_Host =
      IsRelease ? 'fn.jzfeng.com' : '47.92.151.39:5216';
  static const String AccessKeyId =
      String.fromEnvironment('OVSX_APP_TOKEN');

  static const int ReceiveTimeout = 15000;
  static const int ConnectTimeout = 15000;
  static const int SendTimeout = 15000;
  static const int Retry_Max_Count = 3;
  static const String Version = 'v1.0';
  static const int SignType = 101;
  static const int Client = 10;
  static const bool Proxy_Enable = false; // 是否启用代理，方便调试抓包

  // 代理设置 Charles 抓包用192.168.2.67
  static const CompanyIp = '192.168.1.181'; // 公司ipni
  static const HomeIp = '192.168.66.176'; // 家ip
  static const IphoneIp = '172.20.10.11'; // 手机 热点ip
  static var proxyIp = CompanyIp; // 代理服务ip
  static const Proxy_Port = 8888; // 代理服务端口

  static const int reTokenCode = 1000102; // token续期的code
  static const int reLoginCode = 1000103; // token长失效，重新登录code

  // 新增错误码
  static const int NetworkErrorCode = -1111; // 网络连接错误
  static const int UnknownErrorCode = -1; // 未知错误
  static const int OssTokenErrorCode = 1111; // OSS Token获取失败
}

class AliyunOSSConstant {
  static const AccessKey = String.fromEnvironment('OVSX_OSS_TOKEN');

  static const BucketName = 'ovsx-usr';
  static const Endpoint = 'https://oss-cn-zhangjiakou.aliyuncs.com';
  static const OSSUrl = 'https://ovsx-usr.oss-cn-zhangjiakou.aliyuncs.com';

  static const FeedBackBucketName = 'feedback2';
  static const FeedBackOSSUrl = 'https://feedback2.oss-cn-shenzhen.aliyuncs.com';

  static const Subject1ScoreBucketName = 'feedback2';
  static const Subject1ScoreOSSUrl =
      'https://feedback2.oss-cn-shenzhen.aliyuncs.com';

  static const SignInBucketName = 'feedback2';
  static const SignInBucketNameOSSUrl =
      'https://feedback2.oss-cn-shenzhen.aliyuncs.com';
}
