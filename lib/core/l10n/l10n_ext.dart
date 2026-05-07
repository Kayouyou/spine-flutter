import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';

/// BuildContext 扩展 — 简化国际化文本获取
///
/// ```dart
/// Text(context.l10n.retry)      // 替代 AppLocalizations.of(context)!.retry
/// Text(context.l10n.homeTitle)
/// ```
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
