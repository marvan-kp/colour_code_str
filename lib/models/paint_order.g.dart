// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paint_order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaintOrderAdapter extends TypeAdapter<PaintOrder> {
  @override
  final int typeId = 0;

  @override
  PaintOrder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaintOrder(
      id: fields[0] as String?,
      colorCode: fields[1] as String,
      base: fields[2] as String,
      product: fields[3] as String,
      subProduct: fields[4] as String,
      canSize: fields[5] as String,
      liters: fields[6] as int,
      pricePerLiter: fields[7] as double,
      quantity: fields[8] as int,
      totalCost: fields[9] as double,
      customer: fields[10] as String,
      createdAt: fields[11] as DateTime,
      isSynced: fields[12] as bool,
      deviceId: fields[13] as String,
      updatedAt: fields[14] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PaintOrder obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.colorCode)
      ..writeByte(2)
      ..write(obj.base)
      ..writeByte(3)
      ..write(obj.product)
      ..writeByte(4)
      ..write(obj.subProduct)
      ..writeByte(5)
      ..write(obj.canSize)
      ..writeByte(6)
      ..write(obj.liters)
      ..writeByte(7)
      ..write(obj.pricePerLiter)
      ..writeByte(8)
      ..write(obj.quantity)
      ..writeByte(9)
      ..write(obj.totalCost)
      ..writeByte(10)
      ..write(obj.customer)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.isSynced)
      ..writeByte(13)
      ..write(obj.deviceId)
      ..writeByte(14)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaintOrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
