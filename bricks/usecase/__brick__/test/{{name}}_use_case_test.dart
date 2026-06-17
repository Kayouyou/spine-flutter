import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:domain/domain.dart';
import 'package:domain/src/repositories/i{{repository.snakeCase()}}_repository.dart';
import 'package:domain/src/usecases/{{name.snakeCase()}}_use_case.dart';

class Mock{{repository.pascalCase()}}Repository extends Mock implements I{{repository.pascalCase()}}Repository {}

void main() {
  group('{{name.pascalCase()}}UseCase', () {
    late Mock{{repository.pascalCase()}}Repository mockRepository;
    late {{name.pascalCase()}}UseCase useCase;

    setUp(() {
      mockRepository = Mock{{repository.pascalCase()}}Repository();
      useCase = {{name.pascalCase()}}UseCase(mockRepository);
    });

    test('should return result from repository', () async {
      // Arrange
      final expectedResult = Result<String, DomainException>.success('test data');
      when(() => mockRepository.get{{repository.pascalCase()}}())
          .thenAnswer((_) async => expectedResult);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isOk, isTrue);
      expect(result.asOk.value, equals('test data'));
      verify(() => mockRepository.get{{repository.pascalCase()}}()).called(1);
    });

    test('should propagate repository errors', () async {
      // Arrange
      final expectedResult = Result<String, DomainException>.failure(
        DomainException('Test error'),
      );
      when(() => mockRepository.get{{repository.pascalCase()}}())
          .thenAnswer((_) async => expectedResult);

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isErr, isTrue);
      expect(result.asErr.error.message, equals('Test error'));
      verify(() => mockRepository.get{{repository.pascalCase()}}()).called(1);
    });

    test('should handle repository exceptions', () async {
      // Arrange
      when(() => mockRepository.get{{repository.pascalCase()}}())
          .thenThrow(Exception('Unexpected error'));

      // Act & Assert
      expect(() => useCase.call(), throwsException);
    });
  });
}
