// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomCategoryModelAdapter extends TypeAdapter<CustomCategoryModel> {
  @override
  final int typeId = 1;

  @override
  CustomCategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomCategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      isExpense: fields[2] as bool,
      colorValue: fields[3] as int,
      iconCodePoint: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CustomCategoryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isExpense)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.iconCodePoint);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CustomCategoryModelAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}