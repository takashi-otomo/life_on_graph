// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'steps_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StepsRecordModelAdapter extends TypeAdapter<StepsRecordModel> {
  @override
  final typeId = 1;

  @override
  StepsRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StepsRecordModel(
      uuid: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime,
      count: (fields[3] as num).toInt(),
      sourcePackage: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StepsRecordModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.count)
      ..writeByte(4)
      ..write(obj.sourcePackage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepsRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
