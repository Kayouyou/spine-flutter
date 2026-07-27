import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CancelTokenManager.cancelAll', () {
    tearDown(() {
      CancelTokenManager.instance.clearAll();
    });

    test('cancelAll 取消所有页面在途请求并清空映射', () {
      final manager = CancelTokenManager.instance;
      manager.clearAll();

      final t1 = CancelToken();
      final t2 = CancelToken();
      final t3 = CancelToken();
      manager.register('pageA', t1);
      manager.register('pageA', t2);
      manager.register('pageB', t3);

      expect(manager.getTokenCount('pageA'), 2);
      expect(manager.getTokenCount('pageB'), 1);

      // 执行全局取消
      manager.cancelAll('用户登出');

      // 所有 token 均被取消
      expect(t1.isCancelled, isTrue);
      expect(t2.isCancelled, isTrue);
      expect(t3.isCancelled, isTrue);

      // 映射已清空
      expect(manager.getTokenCount('pageA'), 0);
      expect(manager.getTokenCount('pageB'), 0);
    });

    test('cancelAll 后再次 register 可正常工作（无残留）', () {
      final manager = CancelTokenManager.instance;
      manager.clearAll();

      final t = CancelToken();
      manager.register('pageC', t);
      manager.cancelAll();

      // 重新注册一个页面
      final tNew = CancelToken();
      manager.register('pageD', tNew);
      expect(manager.getTokenCount('pageD'), 1);
      expect(tNew.isCancelled, isFalse);
    });

    test('空管理器调用 cancelAll 不抛异常', () {
      final manager = CancelTokenManager.instance;
      manager.clearAll();
      expect(() => manager.cancelAll(), returnsNormally);
    });
  });
}
