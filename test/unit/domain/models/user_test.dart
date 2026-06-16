import 'package:flutter_test/flutter_test.dart';
import 'package:domain/domain.dart';

void main() {
  group('User', () {
    test('fromJson creates User correctly', () {
      final json = {'id': '1', 'name': 'Test', 'avatar': 'url', 'email': 'test@example.com'};
      final user = User.fromJson(json);

      expect(user.id, '1');
      expect(user.name, 'Test');
      expect(user.avatar, 'url');
      expect(user.email, 'test@example.com');
    });

    test('toJson produces correct map', () {
      const user = User(id: '1', name: 'Test', avatar: 'url', email: 'test@example.com');
      final map = user.toJson();

      expect(map['id'], '1');
      expect(map['name'], 'Test');
      expect(map['avatar'], 'url');
      expect(map['email'], 'test@example.com');
    });

    test('toJson omits null fields', () {
      const user = User(id: '1', name: 'Test');
      final map = user.toJson();

      expect(map['avatar'], isNull);
      expect(map['email'], isNull);
    });

    test('equality works correctly', () {
      const user1 = User(id: '1', name: 'Test');
      const user2 = User(id: '1', name: 'Test');
      const user3 = User(id: '2', name: 'Other');

      expect(user1, user2);
      expect(user1, isNot(user3));
    });

    test('copyWith creates modified copy', () {
      const user = User(id: '1', name: 'Test');
      final modified = user.copyWith(name: 'Modified');

      expect(modified.id, '1');
      expect(modified.name, 'Modified');
    });
  });
}