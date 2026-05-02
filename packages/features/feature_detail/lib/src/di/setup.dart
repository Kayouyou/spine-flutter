import 'package:get_it/get_it.dart';
import 'package:feature_detail/src/cubit/detail_cubit.dart';
import 'package:feature_detail/src/repository/detail_repository.dart';
import 'package:feature_detail/src/repository/detail_repository_impl.dart';
import 'package:api/api.dart';

void setupFeatureDetail(GetIt sl) {
  sl.registerFactory<DetailRepository>(() => DetailRepositoryImpl(sl<Api>()));
  sl.registerFactory<DetailCubit>(() => DetailCubit(sl<DetailRepository>()));
}