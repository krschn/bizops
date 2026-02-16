import 'package:equatable/equatable.dart';

import 'transaction_line.dart';

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.transactedAt,
    required this.lines,
    required this.grandTotal,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime transactedAt;
  final List<TransactionLine> lines;
  final double grandTotal;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction copyWith({
    String? id,
    DateTime? transactedAt,
    List<TransactionLine>? lines,
    double? grandTotal,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Transaction(
        id: id ?? this.id,
        transactedAt: transactedAt ?? this.transactedAt,
        lines: lines ?? this.lines,
        grandTotal: grandTotal ?? this.grandTotal,
        isDeleted: isDeleted ?? this.isDeleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props =>
      [id, transactedAt, lines, grandTotal, isDeleted, createdAt, updatedAt];
}
