// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saving_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingAccountAdapter extends TypeAdapter<SavingAccount> {
  @override
  final int typeId = 7;

  @override
  SavingAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingAccount(
      name: fields[0] as String,
      balance: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SavingAccount obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.balance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
