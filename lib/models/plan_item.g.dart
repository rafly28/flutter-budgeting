// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanItemAdapter extends TypeAdapter<PlanItem> {
  @override
  final int typeId = 8;

  @override
  PlanItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanItem(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      isPaid: fields[3] as bool,
      category: fields[4] as String,
      monthKey: fields[5] as String,
      planType: fields[6] == null ? 'expense' : fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PlanItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.isPaid)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.monthKey)
      ..writeByte(6)
      ..write(obj.planType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
