# Plan 03 — Suppliers

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

- Immutable via `const` constructor or `freezed`.
- Equality based on all fields.
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

```
@HiveType(typeId: 2)
SupplierModel extends HiveObject
  @HiveField(0) id: String
  @HiveField(1) name: String
  @HiveField(2) isDeleted: bool
  @HiveField(3) createdAt: DateTime
  @HiveField(4) updatedAt: DateTime
```

**Critical:** `typeId: 2` — must not clash with `ProductModel` (typeId: 1).

- Run `dart run build_runner build` to generate `supplier_model.g.dart`.
- Provides `toEntity()` → `Supplier` and a static/factory `fromEntity(Supplier)` → `SupplierModel`.

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

**Events** (`supplier_event.dart`):
```
SupplierEvent (sealed/freezed)
  SuppliersLoaded()
  SuppliersTrashLoaded()
  SupplierSaveRequested(Supplier supplier)
  SupplierDeleteRequested(String id)
  SupplierRestoreRequested(String id)
  SupplierPermanentDeleteRequested(String id)
```

**States** (`supplier_state.dart`):
```
SupplierState (sealed/freezed)
  initial()
  loading()
  loaded(List<Supplier> suppliers)
  trashLoaded(List<Supplier> suppliers)
  saving()
  saveSuccess()
  error(Failure failure)
```

**BLoC** (`supplier_bloc.dart`):
- Injects: `GetSuppliers`, `GetDeletedSuppliers`, `SaveSupplier`, `SoftDeleteSupplier`, `RestoreSupplier`, `PermanentDeleteSupplier`.
- `on<SuppliersLoaded>` — emits `loading()`, calls `GetSuppliers`, emits `loaded(suppliers)` or `error(failure)`.
- `on<SuppliersTrashLoaded>` — emits `loading()`, calls `GetDeletedSuppliers`, emits `trashLoaded(suppliers)` or `error(failure)`.
- `on<SupplierSaveRequested>` — emits `saving()`, calls `SaveSupplier`, emits `saveSuccess()` or `error(failure)`.
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
- Active tab: `BlocBuilder` on `loaded` state → `ListView` of `SupplierListTile`.
  - On delete: shows `ConfirmDeleteDialog`, on confirm adds `SupplierDeleteRequested(id)`.
- Trash tab: `BlocBuilder` on `trashLoaded` state → `ListView` of `SupplierTrashTile`.
- FAB: navigates to `/suppliers/new`.
- Shows `AppLoadingWidget` on `loading` state.
- Shows `AppErrorWidget` on `error` state with retry.
- Shows `AppEmptyStateWidget` when list is empty.

**`lib/features/suppliers/presentation/pages/supplier_form_page.dart`**

- `SupplierFormPage` — receives optional `supplierId` from route params.
- If `supplierId` is non-null, loads existing supplier and pre-fills form.
- Form fields:
  - Name: `TextFormField`, required.
- Save button: adds `SupplierSaveRequested(supplier)` where `supplier` is:
  - New: `Supplier(id: uuid, name: ..., isDeleted: false, createdAt: now, updatedAt: now)`.
  - Edit: existing supplier `copyWith(name: ..., updatedAt: now)`.
- On `saveSuccess` state: `context.pop()`.
- On `error` state: show `SnackBar` with failure message.
- Uses `LabeledField` for the name field.
- Uses `PrimaryButton` for save, with `isLoading: true` during `saving` state.

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

In `lib/features/suppliers/data/datasources/supplier_local_data_source.dart`:
- `@LazySingleton(as: SupplierLocalDataSource)` on `SupplierLocalDataSourceImpl`.

In `lib/features/suppliers/data/repositories/supplier_repository_impl.dart`:
- `@LazySingleton(as: SupplierRepository)` on `SupplierRepositoryImpl`.

In each use case:
- `@injectable` annotation.

`SupplierBloc`:
- `@injectable` annotation (transient).

`Box<SupplierModel>`:
- Register in a DI module:
  ```dart
  @module
  abstract class SuppliersModule {
    @lazySingleton
    Box<SupplierModel> get supplierBox => Hive.box<SupplierModel>(HiveBoxNames.suppliers);
  }
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
lib/features/suppliers/data/models/supplier_model.g.dart          ← generated
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

- `SuppliersLoaded` → emits `[loading(), loaded(suppliers)]`.
- `SuppliersLoaded` when use case fails → emits `[loading(), error(failure)]`.
- `SupplierSaveRequested` valid → emits `[saving(), saveSuccess()]`.
- `SupplierDeleteRequested` → calls `SoftDeleteSupplier`, then re-loads active list.
- `SupplierRestoreRequested` → calls `RestoreSupplier`, then re-loads trash list.
- `SupplierPermanentDeleteRequested` → calls `PermanentDeleteSupplier`, then re-loads trash list.

---

## Key Constraint

- `typeId: 2` is reserved for `SupplierModel`. Do not use for any other model.
- Supplier `name` is denormalized into `TransactionLineModel` (Plan 04) at the time a transaction line is created. Soft-deleting or renaming a supplier does **not** affect existing transaction lines.

---

## Verification Checklist

- [ ] `build_runner` generates `supplier_model.g.dart` without errors.
- [ ] Supplier list shows active suppliers; Trash tab shows soft-deleted suppliers.
- [ ] Creating a supplier with empty name shows validation error (SnackBar or inline).
- [ ] Soft-deleting moves supplier to Trash tab; no longer appears in active list.
- [ ] Restoring from Trash moves supplier back to Active tab.
- [ ] Permanent delete removes from Trash (cannot be recovered).
- [ ] All unit and BLoC tests pass.
