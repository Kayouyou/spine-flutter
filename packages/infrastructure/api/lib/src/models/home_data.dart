import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_data.freezed.dart';
part 'home_data.g.dart';

@freezed
class HomeData with _$HomeData {
  const factory HomeData({
    required String title,
    required String sections,
    String? banner,
  }) = _HomeData;

  factory HomeData.fromJson(Map<String, dynamic> json) => _$HomeDataFromJson(json);
}
