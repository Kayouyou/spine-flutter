import 'package:api/api.dart';
import 'package:auth/auth.dart';
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserApi extends Mock implements UserApi {}

void main() {
  late MockUserApi mockApi;
  late UserRepositoryImpl repo;

  setUp(() {
    mockApi = MockUserApi();
    repo = UserRepositoryImpl(mockApi);
  });

  group('getCurrentUser', () {
    test('200 时返回 User', () async {
      when(() => mockApi.getCurrentUser()).thenAnswer((_) async => const UserProfile(
        id: '1',
        name: 'Test',
        email: 'test@test.com',
      ),);

      final result = await repo.getCurrentUser();
      result.when(
        success: (user) {
          expect(user.id, '1');
          expect(user.name, 'Test');
        },
        failure: (_) => fail('应返回成功结果'),
      );
    });

    test('401 时返回 UnauthorizedException', () async {
      when(() => mockApi.getCurrentUser()).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(requestOptions: RequestOptions(), statusCode: 401),
        ),
      );

      final result = await repo.getCurrentUser();
      result.when(
        success: (_) => fail('应返回失败结果'),
        failure: (error) {
          expect(error, isA<UnauthorizedException>());
        },
      );
    });

    test('404 时返回 NotFoundException', () async {
      when(() => mockApi.getCurrentUser()).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(requestOptions: RequestOptions(), statusCode: 404),
        ),
      );

      final result = await repo.getCurrentUser();
      result.when(
        success: (_) => fail('应返回失败结果'),
        failure: (error) {
          expect(error, isA<NotFoundException>());
        },
      );
    });

    test('连接错误时返回 NetworkException', () async {
      when(() => mockApi.getCurrentUser()).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
          message: '无网络',
        ),
      );

      final result = await repo.getCurrentUser();
      result.when(
        success: (_) => fail('应返回失败结果'),
        failure: (error) {
          expect(error, isA<NetworkException>());
          expect((error as NetworkException).statusCode, isNull);
        },
      );
    });
  });
}
