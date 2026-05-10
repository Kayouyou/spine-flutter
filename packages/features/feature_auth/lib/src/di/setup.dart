import 'package:domain/domain.dart';
import 'package:get_it/get_it.dart';
import '../cubit/login_cubit.dart';
import '../repository/mock_auth_repository.dart';

void setupFeatureAuth(GetIt sl) {
  sl.registerFactory<AuthRepository>(() => MockAuthRepository());
  sl.registerFactory<LoginCubit>(() => LoginCubit(sl<AuthRepository>()));
}