import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_data.freezed.dart';
part 'vehicle_data.g.dart';

@freezed
class VehicleData with _$VehicleData {
  const factory VehicleData({
    required String id,
    required String name,
    required String plate,
    required String status,
    String? type,
  }) = _VehicleData;

  factory VehicleData.fromJson(Map<String, dynamic> json) => _$VehicleDataFromJson(json);
}
