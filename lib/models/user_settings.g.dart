// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 4;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      payday: fields[0] as int,
      isNotificationEnabled: fields[1] == null ? true : fields[1] as bool,
      resetBalanceOnPayday: fields[2] == null ? false : fields[2] as bool,
      themeColor: fields[3] == null ? 4280171146 : fields[3] as int,
      budgetingMode: fields[4] == null ? 'standard' : fields[4] as String,
      isBalanceHidden: fields[5] == null ? true : fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.payday)
      ..writeByte(1)
      ..write(obj.isNotificationEnabled)
      ..writeByte(2)
      ..write(obj.resetBalanceOnPayday)
      ..writeByte(3)
      ..write(obj.themeColor)
      ..writeByte(4)
      ..write(obj.budgetingMode)
      ..writeByte(5)
      ..write(obj.isBalanceHidden);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
