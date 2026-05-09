// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VehicleData _$VehicleDataFromJson(Map<String, dynamic> json) {
  return _VehicleData.fromJson(json);
}

/// @nodoc
mixin _$VehicleData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get plate => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VehicleDataCopyWith<VehicleData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VehicleDataCopyWith<$Res> {
  factory $VehicleDataCopyWith(
          VehicleData value, $Res Function(VehicleData) then) =
      _$VehicleDataCopyWithImpl<$Res, VehicleData>;
  @useResult
  $Res call(
      {String id, String name, String plate, String status, String? type});
}

/// @nodoc
class _$VehicleDataCopyWithImpl<$Res, $Val extends VehicleData>
    implements $VehicleDataCopyWith<$Res> {
  _$VehicleDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? plate = null,
    Object? status = null,
    Object? type = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      plate: null == plate
          ? _value.plate
          : plate // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VehicleDataImplCopyWith<$Res>
    implements $VehicleDataCopyWith<$Res> {
  factory _$$VehicleDataImplCopyWith(
          _$VehicleDataImpl value, $Res Function(_$VehicleDataImpl) then) =
      __$$VehicleDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String name, String plate, String status, String? type});
}

/// @nodoc
class __$$VehicleDataImplCopyWithImpl<$Res>
    extends _$VehicleDataCopyWithImpl<$Res, _$VehicleDataImpl>
    implements _$$VehicleDataImplCopyWith<$Res> {
  __$$VehicleDataImplCopyWithImpl(
      _$VehicleDataImpl _value, $Res Function(_$VehicleDataImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? plate = null,
    Object? status = null,
    Object? type = freezed,
  }) {
    return _then(_$VehicleDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      plate: null == plate
          ? _value.plate
          : plate // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VehicleDataImpl implements _VehicleData {
  const _$VehicleDataImpl(
      {required this.id,
      required this.name,
      required this.plate,
      required this.status,
      this.type});

  factory _$VehicleDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$VehicleDataImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String plate;
  @override
  final String status;
  @override
  final String? type;

  @override
  String toString() {
    return 'VehicleData(id: $id, name: $name, plate: $plate, status: $status, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VehicleDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.plate, plate) || other.plate == plate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, plate, status, type);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VehicleDataImplCopyWith<_$VehicleDataImpl> get copyWith =>
      __$$VehicleDataImplCopyWithImpl<_$VehicleDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VehicleDataImplToJson(
      this,
    );
  }
}

abstract class _VehicleData implements VehicleData {
  const factory _VehicleData(
      {required final String id,
      required final String name,
      required final String plate,
      required final String status,
      final String? type}) = _$VehicleDataImpl;

  factory _VehicleData.fromJson(Map<String, dynamic> json) =
      _$VehicleDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get plate;
  @override
  String get status;
  @override
  String? get type;
  @override
  @JsonKey(ignore: true)
  _$$VehicleDataImplCopyWith<_$VehicleDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
