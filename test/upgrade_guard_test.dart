// Flutter imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:spine_flutter/core/services/upgrade_guard.dart';

void main() {
  group('shouldWrapUpgrade', () {
    test('升级提示开启 + 非 OHOS → 包裹', () {
      expect(
        shouldWrapUpgrade(enableUpgradePrompt: true, isOhos: false),
        isTrue,
      );
    });

    test('升级提示关闭 + 非 OHOS → 不包裹', () {
      expect(
        shouldWrapUpgrade(enableUpgradePrompt: false, isOhos: false),
        isFalse,
      );
    });

    test('升级提示开启 + OHOS → 不包裹 (OHOS 无应用商店, upgrader 无法查询版本)', () {
      expect(
        shouldWrapUpgrade(enableUpgradePrompt: true, isOhos: true),
        isFalse,
      );
    });

    test('升级提示关闭 + OHOS → 不包裹', () {
      expect(
        shouldWrapUpgrade(enableUpgradePrompt: false, isOhos: true),
        isFalse,
      );
    });
  });
}
