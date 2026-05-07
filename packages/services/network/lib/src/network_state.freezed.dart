// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NetworkState {
  NetworkStatus get status => throw _privateConstructorUsedError;
  DateTime? get lastDisconnectedAt => throw _privateConstructorUsedError;
  NetworkUIStyle get uiStyle => throw _privateConstructorUsedError;
  NetworkQuality get quality => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $NetworkStateCopyWith<NetworkState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkStateCopyWith<$Res> {
  factory $NetworkStateCopyWith(
          NetworkState value, $Res Function(NetworkState) then) =
      _$NetworkStateCopyWithImpl<$Res, NetworkState>;
  @useResult
  $Res call(
      {NetworkStatus status,
      DateTime? lastDisconnectedAt,
      NetworkUIStyle uiStyle,
      NetworkQuality quality});
}

/// @nodoc
class _$NetworkStateCopyWithImpl<$Res, $Val extends NetworkState>
    implements $NetworkStateCopyWith<$Res> {
  _$NetworkStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? lastDisconnectedAt = freezed,
    Object? uiStyle = null,
    Object? quality = null,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as NetworkStatus,
      lastDisconnectedAt: freezed == lastDisconnectedAt
          ? _value.lastDisconnectedAt
          : lastDisconnectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      uiStyle: null == uiStyle
          ? _value.uiStyle
          : uiStyle // ignore: cast_nullable_to_non_nullable
              as NetworkUIStyle,
      quality: null == quality
          ? _value.quality
          : quality // ignore: cast_nullable_to_non_nullable
              as NetworkQuality,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NetworkStateImplCopyWith<$Res>
    implements $NetworkStateCopyWith<$Res> {
  factory _$$NetworkStateImplCopyWith(
          _$NetworkStateImpl value, $Res Function(_$NetworkStateImpl) then) =
      __$$NetworkStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {NetworkStatus status,
      DateTime? lastDisconnectedAt,
      NetworkUIStyle uiStyle,
      NetworkQuality quality});
}

/// @nodoc
class __$$NetworkStateImplCopyWithImpl<$Res>
    extends _$NetworkStateCopyWithImpl<$Res, _$NetworkStateImpl>
    implements _$$NetworkStateImplCopyWith<$Res> {
  __$$NetworkStateImplCopyWithImpl(
      _$NetworkStateImpl _value, $Res Function(_$NetworkStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? lastDisconnectedAt = freezed,
    Object? uiStyle = null,
    Object? quality = null,
  }) {
    return _then(_$NetworkStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as NetworkStatus,
      lastDisconnectedAt: freezed == lastDisconnectedAt
          ? _value.lastDisconnectedAt
          : lastDisconnectedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      uiStyle: null == uiStyle
          ? _value.uiStyle
          : uiStyle // ignore: cast_nullable_to_non_nullable
              as NetworkUIStyle,
      quality: null == quality
          ? _value.quality
          : quality // ignore: cast_nullable_to_non_nullable
              as NetworkQuality,
    ));
  }
}

/// @nodoc

class _$NetworkStateImpl extends _NetworkState {
  const _$NetworkStateImpl(
      {required this.status,
      this.lastDisconnectedAt,
      this.uiStyle = NetworkUIStyle.banner,
      this.quality = NetworkQuality.good})
      : super._();

  @override
  final NetworkStatus status;
  @override
  final DateTime? lastDisconnectedAt;
  @override
  @JsonKey()
  final NetworkUIStyle uiStyle;
  @override
  @JsonKey()
  final NetworkQuality quality;

  @override
  String toString() {
    return 'NetworkState(status: $status, lastDisconnectedAt: $lastDisconnectedAt, uiStyle: $uiStyle, quality: $quality)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastDisconnectedAt, lastDisconnectedAt) ||
                other.lastDisconnectedAt == lastDisconnectedAt) &&
            (identical(other.uiStyle, uiStyle) || other.uiStyle == uiStyle) &&
            (identical(other.quality, quality) || other.quality == quality));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, status, lastDisconnectedAt, uiStyle, quality);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkStateImplCopyWith<_$NetworkStateImpl> get copyWith =>
      __$$NetworkStateImplCopyWithImpl<_$NetworkStateImpl>(this, _$identity);
}

abstract class _NetworkState extends NetworkState {
  const factory _NetworkState(
      {required final NetworkStatus status,
      final DateTime? lastDisconnectedAt,
      final NetworkUIStyle uiStyle,
      final NetworkQuality quality}) = _$NetworkStateImpl;
  const _NetworkState._() : super._();

  @override
  NetworkStatus get status;
  @override
  DateTime? get lastDisconnectedAt;
  @override
  NetworkUIStyle get uiStyle;
  @override
  NetworkQuality get quality;
  @override
  @JsonKey(ignore: true)
  _$$NetworkStateImplCopyWith<_$NetworkStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
