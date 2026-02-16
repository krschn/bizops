# Plan 03 — Suppliers DONE

**Objective:** Full CRUD for suppliers (name only). Same soft-delete + trash/restore pattern as Products. Suppliers are referenced by Transactions (Plan 04) so their `id` and `name` must be stable.

---

## Dependencies

- Plan 01 complete (core infrastructure, DI, Hive init, shared widgets).

> Plan 03 is independent of Plan 02 and can be implemented in parallel.

---

## New Packages

None beyond Plan 01.

---

## Domain Layer

### Entity

File: `lib/features/suppliers/domain/entities/supplier.dart`

```
Supplier (immutable, equatable)
  id: String
  name: String
  isDeleted: bool
  createdAt: DateTime
  updatedAt: DateTime
```

- Immutable via `const` constructor.
- Implements `Equatable` — equality based on all fields.
- `copyWith(...)` method for field updates.
- No framework dependencies.

### Repository Interface

File: `lib/features/suppliers/domain/repositories/supplier_repository.dart`

```
abstract class SupplierRepository {
  Future<Either<Failure, List<Supplier>>> getAll();          // active only (isDeleted == false)
  Future<Either<Failure, List<Supplier>>> getDeleted();      // trash (isDeleted == true)
  Future<Either<Failure, Supplier>> getById(String id);
  Future<Either<Failure, Unit>> save(Supplier supplier);     // insert or update
  Future<Either<Failure, Unit>> softDelete(String id);       // sets isDeleted = true, updatedAt = now
  Future<Either<Failure, Unit>> restore(String id);          // sets isDeleted = false, updatedAt = now
  Future<Either<Failure, Unit>> permanentDelete(String id);  // removes from Hive box entirely
}
```

### Use Cases

All in `lib/features/suppliers/domain/usecases/`.

Each use case is a class with a single `call(...)` method. Injected via constructor with `SupplierRepository`.

| File | Class | Signature |
|---|---|---|
| `get_suppliers.dart` | `GetSuppliers` | `call() → Future<Either<Failure, List<Supplier>>>` |
| `get_deleted_suppliers.dart` | `GetDeletedSuppliers` | `call() → Future<Either<Failure, List<Supplier>>>` |
| `save_supplier.dart` | `SaveSupplier` | `call(Supplier supplier) → Future<Either<Failure, Unit>>` |
| `soft_delete_supplier.dart` | `SoftDeleteSupplier` | `call(String id) → Future<Either<Failure, Unit>>` |
| `restore_supplier.dart` | `RestoreSupplier` | `call(String id) → Future<Either<Failure, Unit>>` |
| `permanent_delete_supplier.dart` | `PermanentDeleteSupplier` | `call(String id) → Future<Either<Failure, Unit>>` |

**Validation in `SaveSupplier`:**
- `name` must not be empty → return `ValidationFailure('Name is required')`.
- On pass, delegate to repository.

---

## Data Layer

### Hive Model

File: `lib/features/suppliers/data/models/supplier_model.dart`

```dart
class SupplierModel extends HiveObject {
  SupplierModel({
    required this.id,
    required this.name,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  String id;
  String name;
  bool isDeleted;
  DateTime createdAt;
  DateTime updatedAt;

  Supplier toEntity() => Supplier(
    id: id, name: name,
    isDeleted: isDeleted, createdAt: createdAt, updatedAt: updatedAt,
  );

  static SupplierModel fromEntity(Supplier s) => SupplierModel(
    id: s.id, name: s.name,
    isDeleted: s.isDeleted, createdAt: s.createdAt, updatedAt: s.updatedAt,
  );
}

class SupplierModelAdapter extends TypeAdapter<SupplierModel> {
  @override
  final int typeId = 2;

  @override
  SupplierModel read(BinaryReader reader) {
    return SupplierModel(
      id: reader.readString(),
      name: reader.readString(),
      isDeleted: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, SupplierModel obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeBool(obj.isDeleted)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
```

**Critical:** `typeId: 2` — must not clash with `ProductModel` (typeId: 1). No `@HiveType`/`@HiveField` annotations. No generated `.g.dart` file.

### Data Source

File: `lib/features/suppliers/data/datasources/supplier_local_data_source.dart`

```
abstract class SupplierLocalDataSource {
  Future<List<SupplierModel>> getAll();
  Future<List<SupplierModel>> getDeleted();
  Future<SupplierModel?> getById(String id);
  Future<void> save(SupplierModel model);
  Future<void> deleteById(String id);
}
```

Implementation: `SupplierLocalDataSourceImpl`

- Injects `Box<SupplierModel>` (from GetIt).
- `getAll()` — `box.values.where((m) => !m.isDeleted).toList()`.
- `getDeleted()` — `box.values.where((m) => m.isDeleted).toList()`.
- `getById(id)` — `box.get(id)`.
- `save(model)` — `box.put(model.id, model)`.
- `deleteById(id)` — `box.delete(id)`.

### Repository Implementation

File: `lib/features/suppliers/data/repositories/supplier_repository_impl.dart`

- Implements `SupplierRepository`.
- Wraps all data source calls in `try/catch` → maps exceptions to `StorageFailure`.
- `softDelete` — gets model, sets `isDeleted = true`, `updatedAt = DateTime.now()`, saves.
- `restore` — gets model, sets `isDeleted = false`, `updatedAt = DateTime.now()`, saves.
- `permanentDelete` — calls data source `deleteById`.

---

## Presentation Layer

### BLoC

Files in `lib/features/suppliers/presentation/bloc/`:

**Events** (`supplier_event.dart`) — plain sealed classes:
```dart
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
```

**States** (`supplier_state.dart`) — plain sealed classes with Equatable:
```dart
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
```

**BLoC** (`supplier_bloc.dart`):
- Injects: `GetSuppliers`, `GetDeletedSuppliers`, `SaveSupplier`, `SoftDeleteSupplier`, `RestoreSupplier`, `PermanentDeleteSupplier`.
- `on<SuppliersLoaded>` — emits `SupplierLoading()`, calls `GetSuppliers`, emits `SupplierLoaded(suppliers)` or `SupplierError(failure)`.
- `on<SuppliersTrashLoaded>` — emits `SupplierLoading()`, calls `GetDeletedSuppliers`, emits `SupplierTrashLoaded(suppliers)` or `SupplierError(failure)`.
- `on<SupplierSaveRequested>` — emits `SupplierSaving()`, calls `SaveSupplier`, emits `SupplierSaveSuccess()` or `SupplierError(failure)`.
- `on<SupplierDeleteRequested>` — calls `SoftDeleteSupplier`, then re-adds `SuppliersLoaded()`.
- `on<SupplierRestoreRequested>` — calls `RestoreSupplier`, then re-adds `SuppliersTrashLoaded()`.
- `on<SupplierPermanentDeleteRequested>` — calls `PermanentDeleteSupplier`, then re-adds `SuppliersTrashLoaded()`.

### Pages

**`lib/features/suppliers/presentation/pages/supplier_list_page.dart`**

- `SupplierListPage` — `StatefulWidget` with two tabs: **Active** and **Trash**.
- Uses `DefaultTabController` with `TabBar` inside `AppBar`.
- Provides `SupplierBloc` via `BlocProvider`.
- On init, adds `SuppliersLoaded()`.
- On tab switch to Trash, adds `SuppliersTrashLoaded()`.
- Active tab: `BlocBuilder` on `SupplierLoaded` state → `ListView` of `SupplierListTile`.
  - On delete: shows `ConfirmDeleteDialog`, on confirm adds `SupplierDeleteRequested(id)`.
- Trash tab: `BlocBuilder` on `SupplierTrashLoaded` state → `ListView` of `SupplierTrashTile`.
- FAB: navigates to `/suppliers/new`.
- Shows `AppLoadingWidget` on `SupplierLoading` state.
- Shows `AppErrorWidget` on `SupplierError` state with retry.
- Shows `AppEmptyStateWidget` when list is empty.

**`lib/features/suppliers/presentation/pages/supplier_form_page.dart`**

- `SupplierFormPage` — receives optional `supplierId` from route params.
- If `supplierId` is non-null, loads existing supplier and pre-fills form.
- Form fields:
  - Name: `TextFormField`, required.
- Save button: adds `SupplierSaveRequested(supplier)` where `supplier` is:
  - New: `Supplier(id: uuid, name: ..., isDeleted: false, createdAt: now, updatedAt: now)`.
  - Edit: existing supplier `copyWith(name: ..., updatedAt: now)`.
- On `SupplierSaveSuccess` state: `context.pop()`.
- On `SupplierError` state: show `SnackBar` with failure message.
- Uses `LabeledField` for the name field.
- Uses `PrimaryButton` for save, with `isLoading: true` during `SupplierSaving` state.

### Widgets

**`lib/features/suppliers/presentation/widgets/supplier_list_tile.dart`**
```
SupplierListTile({ required Supplier supplier, required VoidCallback onDelete, required VoidCallback onEdit })
```
- `ListTile` showing supplier name.
- Trailing: edit icon + delete icon.

**`lib/features/suppliers/presentation/widgets/supplier_trash_tile.dart`**
```
SupplierTrashTile({ required Supplier supplier, required VoidCallback onRestore, required VoidCallback onPermanentDelete })
```
- `ListTile` with muted/strikethrough styling.
- Trailing: restore icon + permanent delete icon.
- Permanent delete shows `ConfirmDeleteDialog` before proceeding.

---

## Dependency Injection Registration

In `lib/core/di/injection.dart`, register manually:

```dart
// Suppliers
getIt.registerLazySingleton<Box<SupplierModel>>(
  () => Hive.box<SupplierModel>(HiveBoxNames.suppliers),
);
getIt.registerLazySingleton<SupplierLocalDataSource>(
  () => SupplierLocalDataSourceImpl(getIt()),
);
getIt.registerLazySingleton<SupplierRepository>(
  () => SupplierRepositoryImpl(getIt()),
);
getIt.registerFactory(() => GetSuppliers(getIt()));
getIt.registerFactory(() => GetDeletedSuppliers(getIt()));
getIt.registerFactory(() => SaveSupplier(getIt()));
getIt.registerFactory(() => SoftDeleteSupplier(getIt()));
getIt.registerFactory(() => RestoreSupplier(getIt()));
getIt.registerFactory(() => PermanentDeleteSupplier(getIt()));
getIt.registerFactory(() => SupplierBloc(
  getSuppliers: getIt(),
  getDeletedSuppliers: getIt(),
  saveSupplier: getIt(),
  softDeleteSupplier: getIt(),
  restoreSupplier: getIt(),
  permanentDeleteSupplier: getIt(),
));
```

---

## Files to Create

```
lib/features/suppliers/domain/entities/supplier.dart
lib/features/suppliers/domain/repositories/supplier_repository.dart
lib/features/suppliers/domain/usecases/get_suppliers.dart
lib/features/suppliers/domain/usecases/get_deleted_suppliers.dart
lib/features/suppliers/domain/usecases/save_supplier.dart
lib/features/suppliers/domain/usecases/soft_delete_supplier.dart
lib/features/suppliers/domain/usecases/restore_supplier.dart
lib/features/suppliers/domain/usecases/permanent_delete_supplier.dart
lib/features/suppliers/data/models/supplier_model.dart
lib/features/suppliers/data/datasources/supplier_local_data_source.dart
lib/features/suppliers/data/repositories/supplier_repository_impl.dart
lib/features/suppliers/presentation/bloc/supplier_event.dart
lib/features/suppliers/presentation/bloc/supplier_state.dart
lib/features/suppliers/presentation/bloc/supplier_bloc.dart
lib/features/suppliers/presentation/pages/supplier_list_page.dart
lib/features/suppliers/presentation/pages/supplier_form_page.dart
lib/features/suppliers/presentation/widgets/supplier_list_tile.dart
lib/features/suppliers/presentation/widgets/supplier_trash_tile.dart
test/features/suppliers/domain/usecases/get_suppliers_test.dart
test/features/suppliers/domain/usecases/save_supplier_test.dart
test/features/suppliers/domain/usecases/soft_delete_supplier_test.dart
test/features/suppliers/domain/usecases/restore_supplier_test.dart
test/features/suppliers/data/repositories/supplier_repository_impl_test.dart
test/features/suppliers/presentation/bloc/supplier_bloc_test.dart
```

---

## Test Coverage

### Use Case Tests (mock `SupplierRepository` with mocktail)

- `GetSuppliersTest` — returns list on success; returns `StorageFailure` on error.
- `SaveSupplierTest`:
  - Valid supplier → delegates to repository, returns `Right(unit)`.
  - Empty name → returns `Left(ValidationFailure('Name is required'))`.
- `SoftDeleteSupplierTest` — delegates to repository with correct id.
- `RestoreSupplierTest` — delegates to repository with correct id.
- `PermanentDeleteSupplierTest` — delegates to repository with correct id.

### Repository Tests (mock `SupplierLocalDataSource`)

- `getAll` — calls data source `getAll`, maps models to entities.
- `getDeleted` — calls data source `getDeleted`, maps models to entities.
- `softDelete` — fetches model, mutates `isDeleted = true` and `updatedAt`, saves; returns `Left(StorageFailure)` on exception.
- `restore` — fetches model, mutates `isDeleted = false` and `updatedAt`, saves.
- `permanentDelete` — calls `deleteById`.

### BLoC Tests (use `bloc_test`, mock all use cases)

- `SuppliersLoaded` → emits `[SupplierLoading(), SupplierLoaded(suppliers)]`.
- `SuppliersLoaded` when use case fails → emits `[SupplierLoading(), SupplierError(failure)]`.
- `SupplierSaveRequested` valid → emits `[SupplierSaving(), SupplierSaveSuccess()]`.
- `SupplierDeleteRequested` → calls `SoftDeleteSupplier`, then re-loads active list.
- `SupplierRestoreRequested` → calls `RestoreSupplier`, then re-loads trash list.
- `SupplierPermanentDeleteRequested` → calls `PermanentDeleteSupplier`, then re-loads trash list.

---

## Key Constraint

- `typeId: 2` is reserved for `SupplierModel`. Do not use for any other model.
- Supplier `name` is denormalized into `TransactionLineModel` (Plan 04) at the time a transaction line is created. Soft-deleting or renaming a supplier does **not** affect existing transaction lines.

---

## Verification Checklist

- [ ] Supplier list shows active suppliers; Trash tab shows soft-deleted suppliers.
- [ ] Creating a supplier with empty name shows validation error (SnackBar or inline).
- [ ] Soft-deleting moves supplier to Trash tab; no longer appears in active list.
- [ ] Restoring from Trash moves supplier back to Active tab.
- [ ] Permanent delete removes from Trash (cannot be recovered).
- [ ] All unit and BLoC tests pass.
