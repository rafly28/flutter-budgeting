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
      bankName: fields[2] == null ? '' : fields[2] as String,
      accountNumber: fields[3] == null ? '' : fields[3] as String,
      accountHolderName: fields[4] == null ? '' : fields[4] as String,
      pocketCategory: fields[5] == null ? 'savings' : fields[5] as String,
      assetType: fields[6] == null ? 'cash' : fields[6] as String,
      unitCount: fields[7] == null ? 0.0 : fields[7] as double,
      avgBuyPrice: fields[8] == null ? 0.0 : fields[8] as double,
      lastMarketPrice: fields[9] == null ? 0.0 : fields[9] as double,
      symbol: fields[10] == null ? '' : fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SavingAccount obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.balance)
      ..writeByte(2)
      ..write(obj.bankName)
      ..writeByte(3)
      ..write(obj.accountNumber)
      ..writeByte(4)
      ..write(obj.accountHolderName)
      ..writeByte(5)
      ..write(obj.pocketCategory)
      ..writeByte(6)
      ..write(obj.assetType)
      ..writeByte(7)
      ..write(obj.unitCount)
      ..writeByte(8)
      ..write(obj.avgBuyPrice)
      ..writeByte(9)
      ..write(obj.lastMarketPrice)
      ..writeByte(10)
      ..write(obj.symbol);
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
