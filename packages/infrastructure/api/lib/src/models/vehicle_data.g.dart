// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VehicleDataImpl _$$VehicleDataImplFromJson(Map<String, dynamic> json) =>
    _$VehicleDataImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      plate: json['plate'] as String,
      status: json['status'] as String,
      type: json['type'] as String?,
    );

Map<String, dynamic> _$$VehicleDataImplToJson(_$VehicleDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'plate': instance.plate,
      'status': instance.status,
      'type': instance.type,
    };
