import 'package:freezed_annotation/freezed_annotation.dart';

part 'detail_data.freezed.dart';
part 'detail_data.g.dart';

/// 详情数据模型
///
/// 从 API 响应映射的强类型数据。
@freezed
class DetailData with _$DetailData {
  const factory DetailData({
    required String id,
    required String title,
    @Default([]) List<dynamic> relatedItems,
    Map<String, dynamic>? metadata,
  }) = _DetailData;

  factory DetailData.fromJson(Map<String, dynamic> json) =>
      _$DetailDataFromJson(json);
}
