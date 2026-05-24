import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feature scaffold contract', () {
    test('feature barrel does not use import side-effect registration', () {
      final file = File(
        'bricks/feature/__brick__/lib/feature_{{name}}.dart',
      );
      final content = file.readAsStringSync();

      expect(
        content.contains('FeatureRegistry.instance.register'),
        isFalse,
        reason: 'Feature 接入必须只在 root composition root 显式注册',
      );
    });

    test('make create-feature output reminds root explicit registration', () {
      final file = File('makefile');
      final content = file.readAsStringSync();

      expect(
        content.contains('lib/core/di/setup.dart'),
        isTrue,
        reason: '创建 feature 后必须提示开发者去 root setup 显式注册',
      );
    });
  });
}
