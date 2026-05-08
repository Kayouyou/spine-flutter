import 'package:freezed_annotation/freezed_annotation.dart';

part 'test_mason_state.freezed.dart';

/// TestMason 状态
///
/// 职责：定义 TestMason 页面的所有可能状态
/// 使用：BlocBuilder 响应状态更新 UI
/// 状态流转：Initial → Loading → Loaded/Error
@freezed
sealed class TestMasonState with _$TestMasonState {
  const factory TestMasonState.initial() = TestMasonInitial;
  const factory TestMasonState.loading() = TestMasonLoading;
  const factory TestMasonState.loaded({required Map<String, dynamic> data}) = TestMasonLoaded;
  const factory TestMasonState.error({required String errorCode}) = TestMasonError;
}