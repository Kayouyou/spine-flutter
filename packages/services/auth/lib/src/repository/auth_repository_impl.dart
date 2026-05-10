// packages/services/auth/lib/src/repository/auth_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:api/api.dart';
import 'package:domain/domain.dart';

/// UserRepository 的 Retrofit 实现
///
/// 通过 UserApi（Retrofit 代码生成）访问后端，将 DioException 映射为 DomainException。
/// 返回 Result 类型处理成功和异常。
class AuthRepositoryImpl implements UserRepository {
  final UserApi _userApi;

  AuthRepositoryImpl(this._userApi);

  @override
  Future<Result<User, DomainException>> getCurrentUser() async {
    try {
      final profile = await _userApi.getCurrentUser();
      return Result.success(User(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        avatar: profile.avatar,
      ));
    } on DioException catch (e) {
      return Result.failure(_mapError(e));
    }
  }

  @override
  Future<Result<void, DomainException>> updateProfile(ProfileData data) async {
    try {
      await _userApi.updateProfile(UpdateProfileRequest(
        name: data.name,
        email: data.email,
        avatar: data.avatar,
      ));
      return Result.success(null);
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