import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    const json = {
      'id': 'user-1',
      'name': 'Test User',
      'avatar': 'https://example.com/avatar.png',
      'email': 'test@example.com',
    };

    test('fromJson 创建完整字段的 User', () {
      final user = User.fromJson(json);
      expect(user.id, 'user-1');
      expect(user.name, 'Test User');
      expect(user.avatar, 'https://example.com/avatar.png');
      expect(user.email, 'test@example.com');
    });

    test('fromJson 处理缺失可选字段', () {
      final user = User.fromJson({'id': 'user-2', 'name': 'Minimal'});
      expect(user.avatar, isNull);
      expect(user.email, isNull);
    });

    test('toJson 生成正确的 Map', () {
      final user = User.fromJson(json);
      expect(user.toJson(), json);
    });

    test('Equatable — 相同值产生相等对象', () {
      final a = User.fromJson(json);
      final b = User.fromJson(json);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Equatable — 不同值产生不相等对象', () {
      final a = User.fromJson(json);
      final b = User.fromJson({...json, 'id': 'user-2'});
      expect(a, isNot(equals(b)));
    });
  });
}
