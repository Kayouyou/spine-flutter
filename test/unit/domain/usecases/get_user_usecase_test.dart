import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('GetUserUseCase', () {
    late GetUserUseCase usecase;
    late MockUserRepository mockRepo;

    setUp(() {
      mockRepo = MockUserRepository();
      usecase = GetUserUseCase(mockRepo);
    });

    test('execute returns User from repository', () async {
      final expectedUser = User(id: '1', name: 'Test User', email: 'test@example.com');
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => Result.success(expectedUser));

      final result = await usecase.execute();
      result.when(
        success: (user) {
          expect(user.id, '1');
          expect(user.name, 'Test User');
          expect(user.email, 'test@example.com');
        },
        failure: (_) => fail('应返回成功结果'),
      );
      verify(() => mockRepo.getCurrentUser()).called(1);
    });

    test('execute throws UnauthorizedException when repo throws', () async {
      when(() => mockRepo.getCurrentUser()).thenThrow(const UnauthorizedException());
      await expectLater(
        () => usecase.execute(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('execute throws NetworkException when repo throws', () async {
      when(() => mockRepo.getCurrentUser()).thenThrow(const NetworkException('Network failed', statusCode: 500));
      await expectLater(
        () => usecase.execute(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
