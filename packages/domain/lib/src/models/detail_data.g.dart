// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DetailDataImpl _$$DetailDataImplFromJson(Map<String, dynamic> json) =>
    _$DetailDataImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      relatedItems: json['relatedItems'] as List<dynamic>? ?? const [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$DetailDataImplToJson(_$DetailDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'relatedItems': instance.relatedItems,
      'metadata': instance.metadata,
    };
