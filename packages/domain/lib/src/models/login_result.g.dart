// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LoginResultImpl _$$LoginResultImplFromJson(Map<String, dynamic> json) =>
    _$LoginResultImpl(
      userId: json['userId'] as String,
      token: json['token'] as String,
      isNewUser: json['isNewUser'] as bool? ?? false,
    );

Map<String, dynamic> _$$LoginResultImplToJson(_$LoginResultImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'token': instance.token,
      'isNewUser': instance.isNewUser,
    };
