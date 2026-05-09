// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DetailDataImpl _$$DetailDataImplFromJson(Map<String, dynamic> json) =>
    _$DetailDataImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
    );

Map<String, dynamic> _$$DetailDataImplToJson(_$DetailDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'imageUrl': instance.imageUrl,
    };
