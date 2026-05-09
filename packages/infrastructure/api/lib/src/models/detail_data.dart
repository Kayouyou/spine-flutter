import 'package:freezed_annotation/freezed_annotation.dart';

part 'detail_data.freezed.dart';
part 'detail_data.g.dart';

@freezed
class DetailData with _$DetailData {
  const factory DetailData({
    required String id,
    required String title,
    required String content,
    String? imageUrl,
  }) = _DetailData;

  factory DetailData.fromJson(Map<String, dynamic> json) => _$DetailDataFromJson(json);
}
