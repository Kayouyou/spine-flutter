import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('root scaffold contract', () {
    test('root setup keeps explicit feature registration', () {
      final content = File('lib/core/di/setup.dart').readAsStringSync();
      expect(
        content.contains("FeatureRegistry.instance.register('feature_home'"),
        isTrue,
      );
      expect(
        content.contains('FeatureRegistry.instance.runAll(sl);'),
        isTrue,
      );
    });

    test('README documents scaffold-check command', () {
      final content = File('README.md').readAsStringSync();
      expect(content.contains('make scaffold-check'), isTrue);
    });
  });
}
