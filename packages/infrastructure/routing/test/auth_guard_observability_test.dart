// packages/infrastructure/routing/test/auth_guard_observability_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routing/routing.dart';

void main() {
  test('AuthGuard.check 拒绝时打印 redirect /login', () {
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    addTearDown(() => debugPrint = original);

    AuthGuard.check('/profile', () => false);
    AuthGuard.check('/login', () => false); // 白名单放行

    expect(
      logs.any((l) => l.contains('redirect /login')),
      isTrue,
      reason: '拒绝时应有 redirect /login 记录',
    );
    expect(
      logs.any((l) => l.contains('allow')),
      isTrue,
      reason: '/login 白名单应记录 allow',
    );
  });
}
