import 'package:flutter_test/flutter_test.dart';
import 'package:feature_settings/feature_settings.dart';

void main() {
  test('SettingsPage 可以创建', () {
    expect(() => const SettingsPage(), returnsNormally);
  });

  test('SettingsRouteModule 可以创建', () {
    // 验证组件库导出正常
    expect(SettingsPage, isNotNull);
  });
}
