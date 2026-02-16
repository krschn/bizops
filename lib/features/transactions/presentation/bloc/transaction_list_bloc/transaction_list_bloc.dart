import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_deleted_transactions.dart';
import '../../../domain/usecases/get_transactions.dart';
import '../../../domain/usecases/permanent_delete_transaction.dart';
import '../../../domain/usecases/restore_transaction.dart';
import '../../../domain/usecases/soft_delete_transaction.dart';
import 'transaction_list_event.dart';
import 'transaction_list_state.dart';

class TransactionListBloc
    extends Bloc<TransactionListEvent, TransactionListState> {
  TransactionListBloc({
    required GetTransactions getTransactions,
    required GetDeletedTransactions getDeletedTransactions,
    required SoftDeleteTransaction softDeleteTransaction,
    required RestoreTransaction restoreTransaction,
    required PermanentDeleteTransaction permanentDeleteTransaction,
  })  : _getTransactions = getTransactions,
        _getDeletedTransactions = getDeletedTransactions,
        _softDeleteTransaction = softDeleteTransaction,
        _restoreTransaction = restoreTransaction,
        _permanentDeleteTransaction = permanentDeleteTransaction,
        super(const TransactionListInitial()) {
    on<TransactionsLoaded>(_onTransactionsLoaded);
    on<TransactionsTrashLoaded>(_onTransactionsTrashLoaded);
    on<TransactionDeleteRequested>(_onTransactionDeleteRequested);
    on<TransactionRestoreRequested>(_onTransactionRestoreRequested);
    on<TransactionPermanentDeleteRequested>(
      _onTransactionPermanentDeleteRequested,
    );
  }

  final GetTransactions _getTransactions;
  final GetDeletedTransactions _getDeletedTransactions;
  final SoftDeleteTransaction _softDeleteTransaction;
  final RestoreTransaction _restoreTransaction;
  final PermanentDeleteTransaction _permanentDeleteTransaction;

  Future<void> _onTransactionsLoaded(
    TransactionsLoaded event,
    Emitter<TransactionListState> emit,
  ) async {
    emit(const TransactionListLoading());
    final result = await _getTransactions();
    result.fold(
      (failure) => emit(TransactionListError(failure)),
      (transactions) => emit(TransactionListLoaded(transactions)),
    );
  }

  Future<void> _onTransactionsTrashLoaded(
    TransactionsTrashLoaded event,
    Emitter<TransactionListState> emit,
  ) async {
    emit(const TransactionListLoading());
    final result = await _getDeletedTransactions();
    result.fold(
      (failure) => emit(TransactionListError(failure)),
      (transactions) => emit(TransactionListTrashLoaded(transactions)),
    );
  }

  Future<void> _onTransactionDeleteRequested(
    TransactionDeleteRequested event,
    Emitter<TransactionListState> emit,
  ) async {
    final result = await _softDeleteTransaction(event.id);
    result.fold(
      (failure) => emit(TransactionListError(failure)),
      (_) => add(const TransactionsLoaded()),
    );
  }

  Future<void> _onTransactionRestoreRequested(
    TransactionRestoreRequested event,
    Emitter<TransactionListState> emit,
  ) async {
    final result = await _restoreTransaction(event.id);
    result.fold(
      (failure) => emit(TransactionListError(failure)),
      (_) => add(const TransactionsTrashLoaded()),
    );
  }

  Future<void> _onTransactionPermanentDeleteRequested(
    TransactionPermanentDeleteRequested event,
    Emitter<TransactionListState> emit,
  ) async {
    final result = await _permanentDeleteTransaction(event.id);
    result.fold(
      (failure) => emit(TransactionListError(failure)),
      (_) => add(const TransactionsTrashLoaded()),
    );
  }
}
