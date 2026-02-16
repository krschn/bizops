import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_deleted_suppliers.dart';
import '../../domain/usecases/get_suppliers.dart';
import '../../domain/usecases/permanent_delete_supplier.dart';
import '../../domain/usecases/restore_supplier.dart';
import '../../domain/usecases/save_supplier.dart';
import '../../domain/usecases/soft_delete_supplier.dart';
import 'supplier_event.dart';
import 'supplier_state.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  SupplierBloc({
    required GetSuppliers getSuppliers,
    required GetDeletedSuppliers getDeletedSuppliers,
    required SaveSupplier saveSupplier,
    required SoftDeleteSupplier softDeleteSupplier,
    required RestoreSupplier restoreSupplier,
    required PermanentDeleteSupplier permanentDeleteSupplier,
  })  : _getSuppliers = getSuppliers,
        _getDeletedSuppliers = getDeletedSuppliers,
        _saveSupplier = saveSupplier,
        _softDeleteSupplier = softDeleteSupplier,
        _restoreSupplier = restoreSupplier,
        _permanentDeleteSupplier = permanentDeleteSupplier,
        super(const SupplierInitial()) {
    on<SuppliersLoaded>(_onSuppliersLoaded);
    on<SuppliersTrashLoaded>(_onSuppliersTrashLoaded);
    on<SupplierSaveRequested>(_onSupplierSaveRequested);
    on<SupplierDeleteRequested>(_onSupplierDeleteRequested);
    on<SupplierRestoreRequested>(_onSupplierRestoreRequested);
    on<SupplierPermanentDeleteRequested>(_onSupplierPermanentDeleteRequested);
  }

  final GetSuppliers _getSuppliers;
  final GetDeletedSuppliers _getDeletedSuppliers;
  final SaveSupplier _saveSupplier;
  final SoftDeleteSupplier _softDeleteSupplier;
  final RestoreSupplier _restoreSupplier;
  final PermanentDeleteSupplier _permanentDeleteSupplier;

  Future<void> _onSuppliersLoaded(
    SuppliersLoaded event,
    Emitter<SupplierState> emit,
  ) async {
    emit(const SupplierLoading());
    final result = await _getSuppliers();
    result.fold(
      (failure) => emit(SupplierError(failure)),
      (suppliers) => emit(SupplierLoaded(suppliers)),
    );
  }

  Future<void> _onSuppliersTrashLoaded(
    SuppliersTrashLoaded event,
    Emitter<SupplierState> emit,
  ) async {
    emit(const SupplierLoading());
    final result = await _getDeletedSuppliers();
    result.fold(
      (failure) => emit(SupplierError(failure)),
      (suppliers) => emit(SupplierTrashLoaded(suppliers)),
    );
  }

  Future<void> _onSupplierSaveRequested(
    SupplierSaveRequested event,
    Emitter<SupplierState> emit,
  ) async {
    emit(const SupplierSaving());
    final result = await _saveSupplier(event.supplier);
    result.fold(
      (failure) => emit(SupplierError(failure)),
      (_) => emit(const SupplierSaveSuccess()),
    );
  }

  Future<void> _onSupplierDeleteRequested(
    SupplierDeleteRequested event,
    Emitter<SupplierState> emit,
  ) async {
    final result = await _softDeleteSupplier(event.id);
    result.fold(
      (failure) => emit(SupplierError(failure)),
      (_) => add(const SuppliersLoaded()),
    );
  }

  Future<void> _onSupplierRestoreRequested(
    SupplierRestoreRequested event,
    Emitter<SupplierState> emit,
  ) async {
    final result = await _restoreSupplier(event.id);
    result.fold(
      (failure) => emit(SupplierError(failure)),
      (_) => add(const SuppliersTrashLoaded()),
    );
  }

  Future<void> _onSupplierPermanentDeleteRequested(
    SupplierPermanentDeleteRequested event,
    Emitter<SupplierState> emit,
  ) async {
    final result = await _permanentDeleteSupplier(event.id);
    result.fold(
      (failure) => emit(SupplierError(failure)),
      (_) => add(const SuppliersTrashLoaded()),
    );
  }
}
