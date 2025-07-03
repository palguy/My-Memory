// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemoryItemAdapter extends TypeAdapter<MemoryItem> {
  @override
  final int typeId = 0;

  @override
  MemoryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemoryItem(
      category: fields[0] as String,
      question: fields[1] as String,
      answer: fields[2] as String,
      imagePath: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MemoryItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.category)
      ..writeByte(1)
      ..write(obj.question)
      ..writeByte(2)
      ..write(obj.answer)
      ..writeByte(3)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
