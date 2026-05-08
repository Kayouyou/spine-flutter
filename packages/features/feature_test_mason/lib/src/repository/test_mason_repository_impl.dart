import 'package:dio/dio.dart';
import 'test_mason_repository.dart';

/// TestMason 数据仓库实现
///
/// 职责：通过 API 获取 TestMason 数据
/// 使用：在 DI setup 中注册为 Factory
class TestMasonRepositoryImpl implements TestMasonRepository {
  final Dio _dio;

  TestMasonRepositoryImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getTestMasonData() async {
    final response = await _dio.get('/test_mason');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> refreshTestMasonData() async {
    final response = await _dio.get('/test_mason', queryParameters: {'refresh': true});
    return response.data as Map<String, dynamic>;
  }
}