// Flutter imports:
import 'dart:io';

/// 是否应在当前平台包裹升级提示组件 ([UpgradeWrapper] / upgrader)。
///
/// 规则：
/// - 仅当 `enableUpgradePrompt` 开启 **且** 当前不是 OHOS 时包裹。
/// - OHOS 没有对应的应用商店，upgrader 无法查询版本更新，包裹会导致
///   运行期错误或无意义的升级检查，故在 OHOS 上跳过。
///
/// 平台检测统一用 [Platform.operatingSystem] == 'ohos'
/// （本 OHOS Flutter fork 不提供 [Platform.isOHOS]）。
bool shouldWrapUpgrade({
  required bool enableUpgradePrompt,
  required bool isOhos,
}) {
  return enableUpgradePrompt && !isOhos;
}
