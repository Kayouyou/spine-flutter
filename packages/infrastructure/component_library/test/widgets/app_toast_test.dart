import 'package:flutter_test/flutter_test.dart';
import 'package:component_library/component_library.dart';

void main() {
  group('AppToast', () {
    test('API 存在', () {
      // 验证 AppToast 类存在且有以下静态方法
      // 编译通过即证明 API 存在
      expect(AppToast, isNotNull);
      
      // 验证方法签名（通过 Function 类型检查）
      void Function(String, {bool dismissOnTap}) show = AppToast.show;
      void Function(String) success = AppToast.success;
      void Function(String) error = AppToast.error;
      void Function(String) info = AppToast.info;
      void Function() dismiss = AppToast.dismiss;
      bool Function() isShow = () => AppToast.isShow;
      
      expect(show, isNotNull);
      expect(success, isNotNull);
      expect(error, isNotNull);
      expect(info, isNotNull);
      expect(dismiss, isNotNull);
      expect(isShow, isNotNull);
    });
  });
}
