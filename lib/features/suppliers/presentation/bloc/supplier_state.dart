import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/supplier.dart';

sealed class SupplierState extends Equatable {
  const SupplierState();

  @override
  List<Object?> get props => [];
}

final class SupplierInitial extends SupplierState {
  const SupplierInitial();
}

final class SupplierLoading extends SupplierState {
  const SupplierLoading();
}

final class SupplierLoaded extends SupplierState {
  const SupplierLoaded(this.suppliers);
  final List<Supplier> suppliers;

  @override
  List<Object?> get props => [suppliers];
}

final class SupplierTrashLoaded extends SupplierState {
  const SupplierTrashLoaded(this.suppliers);
  final List<Supplier> suppliers;

  @override
  List<Object?> get props => [suppliers];
}

final class SupplierSaving extends SupplierState {
  const SupplierSaving();
}

final class SupplierSaveSuccess extends SupplierState {
  const SupplierSaveSuccess();
}

final class SupplierError extends SupplierState {
  const SupplierError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
