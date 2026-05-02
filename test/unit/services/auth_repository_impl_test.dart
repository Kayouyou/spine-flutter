// Package imports:
import 'package:auth/auth.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AuthRepositoryImpl repo;

  setUp(() {
    mockDio = MockDio();
    repo = AuthRepositoryImpl(mockDio);
    registerFallbackValue(RequestOptions());
  });

  group('getCurrentUser', () {
    test('200 时返回 User', () async {
      final response = Response(
        requestOptions: RequestOptions(),
        data: {'id': '1', 'name': 'Test'},
        statusCode: 200,
      );
      when(() => mockDio.get('/api/user/me')).thenAnswer((_) async => response);

      final user = await repo.getCurrentUser();
      expect(user.id, '1');
      expect(user.name, 'Test');
    });

    test('401 时抛出 UnauthorizedException', () async {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 401),
      );
      when(() => mockDio.get('/api/user/me')).thenThrow(error);

      expect(
        () => repo.getCurrentUser(),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('404 时抛出 NotFoundException', () async {
      final error = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
      );
      when(() => mockDio.get('/api/user/me')).thenThrow(error);

      expect(() => repo.getCurrentUser(), throwsA(isA<NotFoundException>()));
    });

    test('连接错误时抛出 NetworkException', () async {
      final error = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
        message: '无网络',
      );
      when(() => mockDio.get('/api/user/me')).thenThrow(error);

      expect(
        () => repo.getCurrentUser(),
        throwsA(predicate((e) => e is NetworkException && e.statusCode == null)),
      );
    });
  });
}
