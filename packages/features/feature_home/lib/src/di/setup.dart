import 'package:get_it/get_it.dart';
import 'package:feature_home/src/cubit/home_cubit.dart';
import 'package:feature_home/src/repository/home_repository.dart';
import 'package:feature_home/src/repository/home_repository_impl.dart';
import 'package:api/api.dart';

void setupFeatureHome(GetIt sl) {
  sl.registerFactory<HomeRepository>(() => HomeRepositoryImpl(sl<Api>()));
  sl.registerFactory<HomeCubit>(() => HomeCubit(sl<HomeRepository>()));
}