import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'paint_order.g.dart';

@HiveType(typeId: 0)
class PaintOrder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String colorCode;

  @HiveField(2)
  final String base;

  @HiveField(3)
  final String product;

  @HiveField(4)
  final String subProduct;

  @HiveField(5)
  final String canSize;

  @HiveField(6)
  final int liters;

  @HiveField(7)
  final double pricePerLiter;

  @HiveField(8)
  final int quantity;

  @HiveField(9)
  final double totalCost;

  @HiveField(10)
  final String customer;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  bool isSynced;

  @HiveField(13)
  final String deviceId;

  @HiveField(14)
  final DateTime updatedAt;

  PaintOrder({
    String? id,
    required this.colorCode,
    required this.base,
    required this.product,
    required this.subProduct,
    required this.canSize,
    required this.liters,
    required this.pricePerLiter,
    required this.quantity,
    required this.totalCost,
    required this.customer,
    required this.createdAt,
    this.isSynced = false,
    required this.deviceId,
    required this.updatedAt,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'colorCode': colorCode,
      'base': base,
      'product': product,
      'subProduct': subProduct,
      'canSize': canSize,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'quantity': quantity,
      'totalCost': totalCost,
      'customer': customer,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced,
      'deviceId': deviceId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PaintOrder.fromMap(Map<String, dynamic> map) {
    return PaintOrder(
      id: map['id'],
      colorCode: map['colorCode'],
      base: map['base'],
      product: map['product'],
      subProduct: map['subProduct'],
      canSize: map['canSize'],
      liters: map['liters'],
      pricePerLiter: map['pricePerLiter'],
      quantity: map['quantity'],
      totalCost: map['totalCost'],
      customer: map['customer'],
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: map['isSynced'] ?? false,
      deviceId: map['deviceId'] ?? 'unknown',
      updatedAt: DateTime.parse(map['updatedAt'] ?? map['createdAt']),
    );
  }

  PaintOrder copyWith({
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return PaintOrder(
      id: id,
      colorCode: colorCode,
      base: base,
      product: product,
      subProduct: subProduct,
      canSize: canSize,
      liters: liters,
      pricePerLiter: pricePerLiter,
      quantity: quantity,
      totalCost: totalCost,
      customer: customer,
      createdAt: createdAt,
      isSynced: isSynced ?? this.isSynced,
      deviceId: deviceId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
