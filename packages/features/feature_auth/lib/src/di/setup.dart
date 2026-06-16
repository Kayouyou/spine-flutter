import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';
import 'package:auth/auth.dart';
import 'package:routing/routing.dart';
import '../cubit/login_cubit.dart';
import '../routes/auth_route_module.dart';

void setupFeatureAuth(GetIt sl) {
  sl.registerFactory<LoginCubit>(() => LoginCubit(
    repository: sl<AuthRepository>(),
    authManager: sl<AuthManager>(),
  ));

  RouteModuleRegistry.instance.register(
    'feature_auth',
    (ctx) => AuthRouteModule(
      ctx,
      createCubit: () => sl<LoginCubit>(),
    ),
  );
}
