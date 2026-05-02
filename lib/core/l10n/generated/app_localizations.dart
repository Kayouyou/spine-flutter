import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// 网络连接失败时的错误提示
  ///
  /// In zh, this message translates to:
  /// **'网络连接失败'**
  String get networkError;

  /// 请求被用户取消
  ///
  /// In zh, this message translates to:
  /// **'请求已取消'**
  String get requestCancelled;

  /// 网络连接超时提示
  ///
  /// In zh, this message translates to:
  /// **'连接超时'**
  String get connectionTimeout;

  /// 用户未登录或Token失效
  ///
  /// In zh, this message translates to:
  /// **'请先登录'**
  String get unauthorized;

  /// 用户Token已过期，需重新登录
  ///
  /// In zh, this message translates to:
  /// **'登录已过期'**
  String get tokenExpired;

  /// 用户无权限访问该资源
  ///
  /// In zh, this message translates to:
  /// **'无权访问'**
  String get forbidden;

  /// 请求的资源不存在
  ///
  /// In zh, this message translates to:
  /// **'资源不存在'**
  String get notFound;

  /// 服务器内部错误
  ///
  /// In zh, this message translates to:
  /// **'服务器错误'**
  String get serverError;

  /// 用户输入参数校验失败
  ///
  /// In zh, this message translates to:
  /// **'输入参数无效'**
  String get invalidInput;

  /// 未知的错误类型
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get unknown;

  /// 重试按钮文本
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// 加载状态提示
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// 应用名称
  ///
  /// In zh, this message translates to:
  /// **'我的应用'**
  String get appName;

  /// 首页标题
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get homeTitle;

  /// 详情页标题
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get detailTitle;

  /// 网络断开状态提示
  ///
  /// In zh, this message translates to:
  /// **'网络连接已断开'**
  String get networkDisconnected;

  /// 网络检查中提示
  ///
  /// In zh, this message translates to:
  /// **'正在检查网络...'**
  String get checkingNetwork;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
