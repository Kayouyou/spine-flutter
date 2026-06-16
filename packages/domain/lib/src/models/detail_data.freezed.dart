// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'detail_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DetailData _$DetailDataFromJson(Map<String, dynamic> json) {
  return _DetailData.fromJson(json);
}

/// @nodoc
mixin _$DetailData {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<dynamic> get relatedItems => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this DetailData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DetailData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetailDataCopyWith<DetailData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetailDataCopyWith<$Res> {
  factory $DetailDataCopyWith(
          DetailData value, $Res Function(DetailData) then) =
      _$DetailDataCopyWithImpl<$Res, DetailData>;
  @useResult
  $Res call(
      {String id,
      String title,
      List<dynamic> relatedItems,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$DetailDataCopyWithImpl<$Res, $Val extends DetailData>
    implements $DetailDataCopyWith<$Res> {
  _$DetailDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DetailData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? relatedItems = null,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      relatedItems: null == relatedItems
          ? _value.relatedItems
          : relatedItems // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DetailDataImplCopyWith<$Res>
    implements $DetailDataCopyWith<$Res> {
  factory _$$DetailDataImplCopyWith(
          _$DetailDataImpl value, $Res Function(_$DetailDataImpl) then) =
      __$$DetailDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      List<dynamic> relatedItems,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$DetailDataImplCopyWithImpl<$Res>
    extends _$DetailDataCopyWithImpl<$Res, _$DetailDataImpl>
    implements _$$DetailDataImplCopyWith<$Res> {
  __$$DetailDataImplCopyWithImpl(
      _$DetailDataImpl _value, $Res Function(_$DetailDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of DetailData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? relatedItems = null,
    Object? metadata = freezed,
  }) {
    return _then(_$DetailDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      relatedItems: null == relatedItems
          ? _value._relatedItems
          : relatedItems // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DetailDataImpl implements _DetailData {
  const _$DetailDataImpl(
      {required this.id,
      required this.title,
      final List<dynamic> relatedItems = const [],
      final Map<String, dynamic>? metadata})
      : _relatedItems = relatedItems,
        _metadata = metadata;

  factory _$DetailDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetailDataImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  final List<dynamic> _relatedItems;
  @override
  @JsonKey()
  List<dynamic> get relatedItems {
    if (_relatedItems is EqualUnmodifiableListView) return _relatedItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_relatedItems);
  }

  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'DetailData(id: $id, title: $title, relatedItems: $relatedItems, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetailDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality()
                .equals(other._relatedItems, _relatedItems) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      const DeepCollectionEquality().hash(_relatedItems),
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of DetailData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetailDataImplCopyWith<_$DetailDataImpl> get copyWith =>
      __$$DetailDataImplCopyWithImpl<_$DetailDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DetailDataImplToJson(
      this,
    );
  }
}

abstract class _DetailData implements DetailData {
  const factory _DetailData(
      {required final String id,
      required final String title,
      final List<dynamic> relatedItems,
      final Map<String, dynamic>? metadata}) = _$DetailDataImpl;

  factory _DetailData.fromJson(Map<String, dynamic> json) =
      _$DetailDataImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  List<dynamic> get relatedItems;
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of DetailData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetailDataImplCopyWith<_$DetailDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
