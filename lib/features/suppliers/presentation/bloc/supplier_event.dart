import '../../domain/entities/supplier.dart';

sealed class SupplierEvent {
  const SupplierEvent();
}

final class SuppliersLoaded extends SupplierEvent {
  const SuppliersLoaded();
}

final class SuppliersTrashLoaded extends SupplierEvent {
  const SuppliersTrashLoaded();
}

final class SupplierSaveRequested extends SupplierEvent {
  const SupplierSaveRequested(this.supplier);
  final Supplier supplier;
}

final class SupplierDeleteRequested extends SupplierEvent {
  const SupplierDeleteRequested(this.id);
  final String id;
}

final class SupplierRestoreRequested extends SupplierEvent {
  const SupplierRestoreRequested(this.id);
  final String id;
}

final class SupplierPermanentDeleteRequested extends SupplierEvent {
  const SupplierPermanentDeleteRequested(this.id);
  final String id;
}
