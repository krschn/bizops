import 'package:hive/hive.dart';

import '../../domain/entities/transaction_line.dart';

class TransactionLineModel extends HiveObject {
  TransactionLineModel({
    required this.id,
    required this.transactionId,
    required this.supplierId,
    required this.supplierName,
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.isDeleted,
    required this.sortOrder,
  });

  late String id;
  late String transactionId;
  late String supplierId;
  late String supplierName;
  late String productId;
  late String productName;
  late String unit;
  late double quantity;
  late double unitPrice;
  late double lineTotal;
  late bool isDeleted;
  late int sortOrder;

  TransactionLine toEntity() => TransactionLine(
        id: id,
        transactionId: transactionId,
        supplierId: supplierId,
        supplierName: supplierName,
        productId: productId,
        productName: productName,
        unit: unit,
        quantity: quantity,
        unitPrice: unitPrice,
        lineTotal: lineTotal,
        isDeleted: isDeleted,
        sortOrder: sortOrder,
      );

  static TransactionLineModel fromEntity(TransactionLine line) =>
      TransactionLineModel(
        id: line.id,
        transactionId: line.transactionId,
        supplierId: line.supplierId,
        supplierName: line.supplierName,
        productId: line.productId,
        productName: line.productName,
        unit: line.unit,
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        lineTotal: line.lineTotal,
        isDeleted: line.isDeleted,
        sortOrder: line.sortOrder,
      );
}

class TransactionLineModelAdapter extends TypeAdapter<TransactionLineModel> {
  @override
  final int typeId = 3;

  @override
  TransactionLineModel read(BinaryReader reader) {
    final id = reader.readString();
    final transactionId = reader.readString();
    final supplierId = reader.readString();
    final supplierName = reader.readString();
    final productId = reader.readString();
    final productName = reader.readString();
    final unit = reader.readString();
    final quantity = reader.readDouble();
    final unitPrice = reader.readDouble();
    final lineTotal = reader.readDouble();
    final isDeleted = reader.readBool();
    final sortOrder = reader.readInt();
    return TransactionLineModel(
      id: id,
      transactionId: transactionId,
      supplierId: supplierId,
      supplierName: supplierName,
      productId: productId,
      productName: productName,
      unit: unit,
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal: lineTotal,
      isDeleted: isDeleted,
      sortOrder: sortOrder,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionLineModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.transactionId);
    writer.writeString(obj.supplierId);
    writer.writeString(obj.supplierName);
    writer.writeString(obj.productId);
    writer.writeString(obj.productName);
    writer.writeString(obj.unit);
    writer.writeDouble(obj.quantity);
    writer.writeDouble(obj.unitPrice);
    writer.writeDouble(obj.lineTotal);
    writer.writeBool(obj.isDeleted);
    writer.writeInt(obj.sortOrder);
  }
}
