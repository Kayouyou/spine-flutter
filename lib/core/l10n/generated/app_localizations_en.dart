import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get networkError => 'Network connection failed';

  @override
  String get requestCancelled => 'Request cancelled';

  @override
  String get connectionTimeout => 'Connection timeout';

  @override
  String get unauthorized => 'Please login first';

  @override
  String get tokenExpired => 'Session expired';

  @override
  String get forbidden => 'Access denied';

  @override
  String get notFound => 'Resource not found';

  @override
  String get serverError => 'Server error';

  @override
  String get invalidInput => 'Invalid input';

  @override
  String get unknown => 'Unknown error';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get appName => 'My App';

  @override
  String get homeTitle => 'Home';

  @override
  String get detailTitle => 'Detail';

  @override
  String get networkDisconnected => 'Network connection lost';

  @override
  String get checkingNetwork => 'Checking network...';

  @override
  String get checkNow => 'Check Now';
}
