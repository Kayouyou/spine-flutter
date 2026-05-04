import 'package:get_it/get_it.dart';
import '../cubit/login_cubit.dart';
import '../repository/mock_auth_repository.dart';

void setupFeatureAuth(GetIt sl) {
  sl.registerFactory<MockAuthRepository>(() => MockAuthRepository());
  sl.registerFactory<LoginCubit>(() => LoginCubit(sl<MockAuthRepository>()));
}