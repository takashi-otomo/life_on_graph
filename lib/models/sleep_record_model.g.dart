// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SleepRecordModelAdapter extends TypeAdapter<SleepRecordModel> {
  @override
  final int typeId = 0;

  @override
  SleepRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepRecordModel(
      uuid: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
      stageType: fields[3] as String,
      sourcePackage: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SleepRecordModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.stageType)
      ..writeByte(4)
      ..write(obj.sourcePackage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
