import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:domain/domain.dart';

part 'detail_state.freezed.dart';

@freezed
sealed class DetailState with _$DetailState {
  const factory DetailState.initial() = DetailInitial;
  const factory DetailState.loading() = DetailLoading;
  const factory DetailState.loaded({required DetailData data}) = DetailLoaded;
  const factory DetailState.error({required String errorCode}) = DetailError;
}
