import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../features/products/domain/entities/product.dart';
import '../../../../../features/suppliers/domain/entities/supplier.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/transaction_line.dart';

sealed class TransactionFormState extends Equatable {
  const TransactionFormState();

  @override
  List<Object?> get props => [];
}

final class TransactionFormInitial extends TransactionFormState {
  const TransactionFormInitial();
}

final class TransactionFormLoading extends TransactionFormState {
  const TransactionFormLoading();
}

final class TransactionFormReady extends TransactionFormState {
  const TransactionFormReady({
    this.existingTransaction,
    required this.lines,
    required this.availableProducts,
    required this.availableSuppliers,
    required this.grandTotal,
  });

  final Transaction? existingTransaction;
  final List<TransactionLine> lines;
  final List<Product> availableProducts;
  final List<Supplier> availableSuppliers;
  final double grandTotal;

  @override
  List<Object?> get props => [
        existingTransaction,
        lines,
        availableProducts,
        availableSuppliers,
        grandTotal,
      ];

  TransactionFormReady copyWith({
    Transaction? existingTransaction,
    List<TransactionLine>? lines,
    List<Product>? availableProducts,
    List<Supplier>? availableSuppliers,
    double? grandTotal,
  }) =>
      TransactionFormReady(
        existingTransaction:
            existingTransaction ?? this.existingTransaction,
        lines: lines ?? this.lines,
        availableProducts: availableProducts ?? this.availableProducts,
        availableSuppliers: availableSuppliers ?? this.availableSuppliers,
        grandTotal: grandTotal ?? this.grandTotal,
      );
}

final class TransactionFormSaving extends TransactionFormState {
  const TransactionFormSaving();
}

final class TransactionFormSaveSuccess extends TransactionFormState {
  const TransactionFormSaveSuccess(this.transactionId);
  final String transactionId;

  @override
  List<Object?> get props => [transactionId];
}

final class TransactionFormError extends TransactionFormState {
  const TransactionFormError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
