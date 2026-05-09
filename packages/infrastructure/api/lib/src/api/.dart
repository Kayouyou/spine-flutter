import 'package:freezed_annotation/freezed_annotation.dart';

part '.freezed.dart';
part '.g.dart';

@freezed
class  with _$ {
  const factory ({

  }) = _;

  factory .fromJson(Map<String, dynamic> json) =>
      _$FromJson(json);
}
