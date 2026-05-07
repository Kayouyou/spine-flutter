import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:feature_home/src/cubit/home_cubit.dart';
import 'package:domain/domain.dart';
import 'package:feature_home/src/repository/home_repository_impl.dart';

void setupFeatureHome(GetIt sl) {
  sl.registerFactory<HomeRepository>(() => HomeRepositoryImpl(sl<Dio>()));
  sl.registerFactory<HomeCubit>(() => HomeCubit(sl<HomeRepository>()));
}