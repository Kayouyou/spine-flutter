import 'package:flutter_test/flutter_test.dart';
import 'package:feature_detail/feature_detail.dart';

void main() {
  group('FeatureDetail', () {
    test('exports are available', () {
      // Verify barrel file exports work
      expect(setupFeatureDetail, isA<Function>());
    });
  });
}