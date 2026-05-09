import 'package:dio/dio.dart';
import 'package:domain/domain.dart';

import 'dio_mapper.dart';

/// 将 Future<T> 转换为 Future<Result<T, DomainException>> 的扩展方法。
///
/// 使用示例：
///   final result = await dio.get('/api').toResult();
///   result.when(
///     success: (data) => process(data),
///     failure: (error) => handleError(error),
///   );
extension FutureResult<T> on Future<T> {
  /// 将 Future<T> 转换为 Result<T, DomainException>
  ///
  /// 捕获 DioException 并通过 toDomainException() 转换为 DomainException。
  /// 非 DioException 错误包装为通用 Failure。
  Future<Result<T, DomainException>> toResult() async {
    try {
      final data = await this;
      return Result.success(data);
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    } catch (e) {
      return Result.failure(NetworkException('意外错误：$e'));
    }
  }
}

/// 专门用于 Dio Response 到 Result 的转换扩展
extension ResponseResult on Future<Response> {
  /// 将 Future<Response> 转换为 Result<Map<String, dynamic>, DomainException>
  ///
  /// 返回 JSON 的 API 调用的便捷方法。
  Future<Result<Map<String, dynamic>, DomainException>> toJsonResult() async {
    try {
      final response = await this;
      return Result.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.failure(e.toDomainException());
    } catch (e) {
      return Result.failure(NetworkException('意外错误：$e'));
    }
  }
}
