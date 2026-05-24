import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:routing/routing.dart';
import 'package:feature_home/src/cubit/home_cubit.dart';
import 'package:domain/domain.dart';
import 'package:feature_home/src/repository/home_repository_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:alice/alice.dart';
import '../routes/home_route_module.dart';

void setupFeatureHome(GetIt sl) {
  sl.registerFactory<HomeRepository>(() => HomeRepositoryImpl(sl<Dio>()));
  sl.registerFactory<HomeCubit>(() => HomeCubit(sl<HomeRepository>()));

  RouteModuleRegistry.instance.register(
    'feature_home',
    (ctx) => HomeRouteModule(
      ctx,
      createCubit: () => sl<HomeCubit>(),
      onOpenDebugInspector: kDebugMode && sl.isRegistered<Alice>()
          ? () => sl<Alice>().showInspector()
          : null,
    ),
  );
}
