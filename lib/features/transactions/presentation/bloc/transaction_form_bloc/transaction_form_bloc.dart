import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/utils/transaction_utils.dart';
import '../../../../products/domain/usecases/get_products.dart';
import '../../../../suppliers/domain/usecases/get_suppliers.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/usecases/get_transaction_by_id.dart';
import '../../../domain/usecases/save_transaction.dart';
import 'transaction_form_event.dart';
import 'transaction_form_state.dart';

class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormState> {
  TransactionFormBloc({
    required GetTransactionById getTransactionById,
    required GetProducts getProducts,
    required GetSuppliers getSuppliers,
    required SaveTransaction saveTransaction,
  })  : _getTransactionById = getTransactionById,
        _getProducts = getProducts,
        _getSuppliers = getSuppliers,
        _saveTransaction = saveTransaction,
        super(const TransactionFormInitial()) {
    on<TransactionFormInitialized>(_onInitialized);
    on<TransactionLineAdded>(_onLineAdded);
    on<TransactionLineEdited>(_onLineEdited);
    on<TransactionLineRemoved>(_onLineRemoved);
    on<TransactionLineRestored>(_onLineRestored);
    on<TransactionSaveRequested>(_onSaveRequested);
  }

  final GetTransactionById _getTransactionById;
  final GetProducts _getProducts;
  final GetSuppliers _getSuppliers;
  final SaveTransaction _saveTransaction;

  static const _uuid = Uuid();

  Future<void> _onInitialized(
    TransactionFormInitialized event,
    Emitter<TransactionFormState> emit,
  ) async {
    emit(const TransactionFormLoading());

    final productsResult = await _getProducts();
    final suppliersResult = await _getSuppliers();

    if (productsResult.isLeft()) {
      productsResult.fold(
        (failure) => emit(TransactionFormError(failure)),
        (_) {},
      );
      return;
    }
    if (suppliersResult.isLeft()) {
      suppliersResult.fold(
        (failure) => emit(TransactionFormError(failure)),
        (_) {},
      );
      return;
    }

    final products = productsResult.getOrElse(() => []);
    final suppliers = suppliersResult.getOrElse(() => []);

    if (event.existingTransactionId != null) {
      final txResult = await _getTransactionById(event.existingTransactionId!);
      txResult.fold(
        (failure) => emit(TransactionFormError(failure)),
        (tx) => emit(
          TransactionFormReady(
            existingTransaction: tx,
            lines: tx.lines,
            availableProducts: products,
            availableSuppliers: suppliers,
            grandTotal: computeGrandTotal(tx.lines),
          ),
        ),
      );
    } else {
      emit(
        TransactionFormReady(
          lines: const [],
          availableProducts: products,
          availableSuppliers: suppliers,
          grandTotal: 0,
        ),
      );
    }
  }

  void _onLineAdded(
    TransactionLineAdded event,
    Emitter<TransactionFormState> emit,
  ) {
    final current = state;
    if (current is! TransactionFormReady) return;

    final nextSortOrder = current.lines.length;
    final newLine = event.line.copyWith(sortOrder: nextSortOrder);
    final updatedLines = [...current.lines, newLine];
    emit(
      current.copyWith(
        lines: updatedLines,
        grandTotal: computeGrandTotal(updatedLines),
      ),
    );
  }

  void _onLineEdited(
    TransactionLineEdited event,
    Emitter<TransactionFormState> emit,
  ) {
    final current = state;
    if (current is! TransactionFormReady) return;

    final updatedLines = current.lines.map((l) {
      if (l.id == event.lineId) {
        return l.copyWith(
          quantity: event.newQuantity,
          lineTotal: event.newQuantity * l.unitPrice,
        );
      }
      return l;
    }).toList();
    emit(
      current.copyWith(
        lines: updatedLines,
        grandTotal: computeGrandTotal(updatedLines),
      ),
    );
  }

  void _onLineRemoved(
    TransactionLineRemoved event,
    Emitter<TransactionFormState> emit,
  ) {
    final current = state;
    if (current is! TransactionFormReady) return;

    final updatedLines = current.lines.map((l) {
      if (l.id == event.lineId) return l.copyWith(isDeleted: true);
      return l;
    }).toList();
    emit(
      current.copyWith(
        lines: updatedLines,
        grandTotal: computeGrandTotal(updatedLines),
      ),
    );
  }

  void _onLineRestored(
    TransactionLineRestored event,
    Emitter<TransactionFormState> emit,
  ) {
    final current = state;
    if (current is! TransactionFormReady) return;

    final updatedLines = current.lines.map((l) {
      if (l.id == event.lineId) return l.copyWith(isDeleted: false);
      return l;
    }).toList();
    emit(
      current.copyWith(
        lines: updatedLines,
        grandTotal: computeGrandTotal(updatedLines),
      ),
    );
  }

  Future<void> _onSaveRequested(
    TransactionSaveRequested event,
    Emitter<TransactionFormState> emit,
  ) async {
    final current = state;
    if (current is! TransactionFormReady) return;

    emit(const TransactionFormSaving());

    final now = DateTime.now();
    final existing = current.existingTransaction;
    final grandTotal = computeGrandTotal(current.lines);

    final transaction = existing != null
        ? existing.copyWith(
            lines: current.lines,
            grandTotal: grandTotal,
            updatedAt: now,
          )
        : Transaction(
            id: _uuid.v4(),
            transactedAt: now,
            lines: current.lines,
            grandTotal: grandTotal,
            isDeleted: false,
            createdAt: now,
            updatedAt: now,
          );

    final result = await _saveTransaction(transaction);
    result.fold(
      (failure) => emit(TransactionFormError(failure)),
      (_) => emit(TransactionFormSaveSuccess(transaction.id)),
    );
  }
}
