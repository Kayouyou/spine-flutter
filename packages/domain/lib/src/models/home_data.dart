import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_data.freezed.dart';
part 'home_data.g.dart';

/// 首页数据模型
///
/// 从 API 响应映射的强类型数据。
@freezed
class HomeData with _$HomeData {
  const factory HomeData({
    required String title,
    @Default([]) List<dynamic> items,
    Map<String, dynamic>? metadata,
  }) = _HomeData;

  factory HomeData.fromJson(Map<String, dynamic> json) =>
      _$HomeDataFromJson(json);
}
