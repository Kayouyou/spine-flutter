import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:feature_detail/src/cubit/detail_cubit.dart';
import 'package:domain/domain.dart';
import 'package:feature_detail/src/repository/detail_repository_impl.dart';

void setupFeatureDetail(GetIt sl) {
  sl.registerFactory<DetailRepository>(() => DetailRepositoryImpl(sl<Dio>()));
  sl.registerFactory<DetailCubit>(() => DetailCubit(sl<DetailRepository>()));
}