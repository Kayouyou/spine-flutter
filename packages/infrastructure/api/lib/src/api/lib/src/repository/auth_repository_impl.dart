import 'package:domain/domain.dart';
import '../api/auth_api.dart';

/// Auth 数据仓储实现
class AuthRepositoryImpl {
  final AuthApi _api;

  AuthRepositoryImpl(this._api);


  Future<Result<List<LoginRequest,LoginResponse,UserProfile>, DomainException>> getList() async {
    try {
      final response = await _api.getList();
      return Result.success(response);
    } catch (e) {
      return Result.failure(NetworkException(e.toString()));
    }
  }

  Future<Result<LoginRequest,LoginResponse,UserProfile, DomainException>> getById(String id) async {
    try {
      final response = await _api.getById(id);
      return Result.success(response);
    } catch (e) {
      return Result.failure(NetworkException(e.toString()));
    }
  }


}
