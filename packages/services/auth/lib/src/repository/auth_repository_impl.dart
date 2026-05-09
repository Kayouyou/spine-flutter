// packages/services/auth/lib/src/repository/auth_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';

/// UserRepository 的远程实现
///
/// 通过 Dio 访问后端 API，将 DioException 映射为 DomainException。
/// 返回 Result 类型处理成功和异常。
class AuthRepositoryImpl implements UserRepository {
  final Dio _dio;

  AuthRepositoryImpl(this._dio);

  @override
  Future<Result<User, DomainException>> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/user/me');
      return Result.success(User.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  @override
  Future<Result<void, DomainException>> updateProfile(ProfileData data) async {
    try {
      await _dio.put('/api/user/profile', data: {
        if (data.name != null) 'name': data.name,
        if (data.avatar != null) 'avatar': data.avatar,
        if (data.email != null) 'email': data.email,
      },);
      return Result.success(null,);
    } on DioException catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  /// 将 DioException 映射为 DomainException
  DomainException _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) return const UnauthorizedException();
    if (statusCode == 404) return const NotFoundException();
    if (statusCode == 422) {
      final errors = (e.response?.data as Map<String, dynamic>?)?['errors'];
      return ValidationException(
        '表单验证失败',
        fieldErrors: errors != null
            ? Map<String, String>.from(errors)
            : const {},
      );
    }
    return NetworkException(
      e.message ?? '网络请求失败',
      statusCode: statusCode,
    );
  }
}