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
      final user = User(id: '1', name: 'Test', avatar: 'url', email: 'test@example.com');
      final map = user.toJson();

      expect(map['id'], '1');
      expect(map['name'], 'Test');
      expect(map['avatar'], 'url');
      expect(map['email'], 'test@example.com');
    });

    test('toJson omits null fields', () {
      final user = User(id: '1', name: 'Test');
      final map = user.toJson();

      expect(map['avatar'], isNull);
      expect(map['email'], isNull);
    });

    test('equality works correctly', () {
      final user1 = User(id: '1', name: 'Test');
      final user2 = User(id: '1', name: 'Test');
      final user3 = User(id: '2', name: 'Other');

      expect(user1, user2);
      expect(user1, isNot(user3));
    });

    test('props includes all fields', () {
      final user = User(id: '1', name: 'Test', avatar: 'url', email: 'test@example.com');
      expect(user.props, ['1', 'Test', 'url', 'test@example.com']);
    });
  });
}