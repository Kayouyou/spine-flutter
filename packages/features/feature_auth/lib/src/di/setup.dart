import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';
import 'package:routing/routing.dart';
import '../cubit/login_cubit.dart';
import '../routes/auth_route_module.dart';

void setupFeatureAuth(GetIt sl) {
  // LoginCubit 注：AuthRepository 已在 setupAuth(sl) 中注册
  sl.registerFactory<LoginCubit>(() => LoginCubit(sl<AuthRepository>()));

  // 路由注册
  RouteModuleRegistry.instance.register('feature_auth', (ctx) => AuthRouteModule(ctx));
}