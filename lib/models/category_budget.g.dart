// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_budget.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryBudgetAdapter extends TypeAdapter<CategoryBudget> {
  @override
  final int typeId = 6;

  @override
  CategoryBudget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryBudget(
      categoryName: fields[0] as String,
      limitAmount: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryBudget obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.categoryName)
      ..writeByte(1)
      ..write(obj.limitAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryBudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
