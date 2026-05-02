// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CacheDataAdapter extends TypeAdapter<CacheData> {
  @override
  final int typeId = 0;

  @override
  CacheData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheData(
      fields[0] as dynamic,
      ttl: Duration(hours: 24), // 默认值，实际从expireAt计算
    );
  }

  @override
  void write(BinaryWriter writer, CacheData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.value)
      ..writeByte(1)
      ..write(obj.expireAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}