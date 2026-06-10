import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('AppToast', () {
    test('静态方法存在', () {
      // 验证 AppToast API 存在
      expect(AppToast.show, isA<Function>());
      expect(AppToast.success, isA<Function>());
      expect(AppToast.error, isA<Function>());
      expect(AppToast.info, isA<Function>());
      expect(AppToast.dismiss, isA<Function>());
      expect(AppToast.isShow, isA<bool>());
    });
  });
}
