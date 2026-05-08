import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:feature_test_mason/src/cubit/test_mason_cubit.dart';
import 'package:feature_test_mason/src/repository/test_mason_repository.dart';
import 'package:feature_test_mason/src/repository/test_mason_repository_impl.dart';

/// 注册 TestMason 功能模块的依赖注入
///
/// 职责：在 GetIt 中注册 Repository 和 Cubit
/// 使用：在 app 启动时调用 setupFeatureTestMason(sl)
void setupFeatureTestMason(GetIt sl) {
  sl.registerFactory<TestMasonRepository>(() => TestMasonRepositoryImpl(sl<Dio>()));
  sl.registerFactory<TestMasonCubit>(() => TestMasonCubit(sl<TestMasonRepository>()));
}