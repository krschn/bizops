import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/transaction.dart';

sealed class TransactionListState extends Equatable {
  const TransactionListState();

  @override
  List<Object?> get props => [];
}

final class TransactionListInitial extends TransactionListState {
  const TransactionListInitial();
}

final class TransactionListLoading extends TransactionListState {
  const TransactionListLoading();
}

final class TransactionListLoaded extends TransactionListState {
  const TransactionListLoaded(this.transactions);
  final List<Transaction> transactions;

  @override
  List<Object?> get props => [transactions];
}

final class TransactionListTrashLoaded extends TransactionListState {
  const TransactionListTrashLoaded(this.transactions);
  final List<Transaction> transactions;

  @override
  List<Object?> get props => [transactions];
}

final class TransactionListError extends TransactionListState {
  const TransactionListError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
