import 'app_localizations.dart';

/// The translations for Chinese (`zh`).
// ignore_for_file: use_super_parameters
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get networkError => '网络连接失败';

  @override
  String get requestCancelled => '请求已取消';

  @override
  String get connectionTimeout => '连接超时';

  @override
  String get unauthorized => '请先登录';

  @override
  String get tokenExpired => '登录已过期';

  @override
  String get forbidden => '无权访问';

  @override
  String get notFound => '资源不存在';

  @override
  String get serverError => '服务器错误';

  @override
  String get invalidInput => '输入参数无效';

  @override
  String get unknown => '未知错误';

  @override
  String get retry => '重试';

  @override
  String get loading => '加载中...';

  @override
  String get appName => '我的应用';

  @override
  String get homeTitle => '首页';

  @override
  String get detailTitle => '详情';

  @override
  String get networkDisconnected => '网络连接已断开';

  @override
  String get checkingNetwork => '正在检查网络...';
}
