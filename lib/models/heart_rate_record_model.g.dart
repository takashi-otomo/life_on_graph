// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'heart_rate_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HeartRateRecordModelAdapter extends TypeAdapter<HeartRateRecordModel> {
  @override
  final int typeId = 2;

  @override
  HeartRateRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HeartRateRecordModel(
      uuid: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
      beatsPerMinute: fields[3] as int,
      sourcePackage: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HeartRateRecordModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.beatsPerMinute)
      ..writeByte(4)
      ..write(obj.sourcePackage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeartRateRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
