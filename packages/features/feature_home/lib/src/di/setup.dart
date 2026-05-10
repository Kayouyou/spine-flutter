import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:routing/routing.dart';
import 'package:feature_home/src/cubit/home_cubit.dart';
import 'package:domain/domain.dart';
import 'package:feature_home/src/repository/home_repository_impl.dart';
import '../routes/home_route_module.dart';

void setupFeatureHome(GetIt sl) {
  // DI 注册
  sl.registerFactory<HomeRepository>(() => HomeRepositoryImpl(sl<Dio>()));
  sl.registerFactory<HomeCubit>(() => HomeCubit(sl<HomeRepository>()));
  
  // 路由注册
  RouteModuleRegistry.instance.register('feature_home', (ctx) => HomeRouteModule(ctx));
}