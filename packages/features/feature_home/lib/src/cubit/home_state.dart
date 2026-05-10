import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:domain/domain.dart';

part 'home_state.freezed.dart';

@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.initial() = HomeInitial;
  const factory HomeState.loading() = HomeLoading;
  const factory HomeState.loaded({required HomeData data}) = HomeLoaded;
  const factory HomeState.error({required String errorCode}) = HomeError;
}
