import 'package:equatable/equatable.dart';

class TransactionLine extends Equatable {
  const TransactionLine({
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

  final String id;
  final String transactionId;
  final String supplierId;
  final String supplierName;
  final String productId;
  final String productName;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final bool isDeleted;
  final int sortOrder;

  TransactionLine copyWith({
    String? id,
    String? transactionId,
    String? supplierId,
    String? supplierName,
    String? productId,
    String? productName,
    String? unit,
    double? quantity,
    double? unitPrice,
    double? lineTotal,
    bool? isDeleted,
    int? sortOrder,
  }) =>
      TransactionLine(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        supplierId: supplierId ?? this.supplierId,
        supplierName: supplierName ?? this.supplierName,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        unit: unit ?? this.unit,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        lineTotal: lineTotal ?? this.lineTotal,
        isDeleted: isDeleted ?? this.isDeleted,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  @override
  List<Object?> get props => [
        id,
        transactionId,
        supplierId,
        supplierName,
        productId,
        productName,
        unit,
        quantity,
        unitPrice,
        lineTotal,
        isDeleted,
        sortOrder,
      ];
}
