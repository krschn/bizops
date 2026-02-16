# Plan 02 — Products

**Objective:** Full CRUD for products (name, price, unit of measure). Soft-deleted products are recoverable from a Trash section. No hard deletes from the active list.

---

## Dependencies

- Plan 01 complete (core infrastructure, DI, Hive init, shared widgets).

---

## New Packages

None beyond Plan 01.

---

## Domain Layer

### Entity

File: `lib/features/products/domain/entities/product.dart`

```
Product (immutable, equatable)
  id: String
  name: String
  price: double
  unit: String           // e.g. "kg", "pcs", "box"
  isDeleted: bool
  createdAt: DateTime
  updatedAt: DateTime
```

- Immutable via `const` constructor or `freezed`.
- Equality based on all fields.
- No framework dependencies.

### Repository Interface

File: `lib/features/products/domain/repositories/product_repository.dart`

```
abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getAll();          // active only (isDeleted == false)
  Future<Either<Failure, List<Product>>> getDeleted();      // trash (isDeleted == true)
  Future<Either<Failure, Product>> getById(String id);
  Future<Either<Failure, Unit>> save(Product product);      // insert or update
  Future<Either<Failure, Unit>> softDelete(String id);      // sets isDeleted = true, updatedAt = now
  Future<Either<Failure, Unit>> restore(String id);         // sets isDeleted = false, updatedAt = now
  Future<Either<Failure, Unit>> permanentDelete(String id); // removes from Hive box entirely
}
```

### Use Cases

All in `lib/features/products/domain/usecases/`.

Each use case is a class with a single `call(...)` method returning `Either<Failure, T>`. Injected via constructor with `ProductRepository`.

| File | Class | Signature |
|---|---|---|
| `get_products.dart` | `GetProducts` | `call() → Future<Either<Failure, List<Product>>>` |
| `get_deleted_products.dart` | `GetDeletedProducts` | `call() → Future<Either<Failure, List<Product>>>` |
| `save_product.dart` | `SaveProduct` | `call(Product product) → Future<Either<Failure, Unit>>` |
| `soft_delete_product.dart` | `SoftDeleteProduct` | `call(String id) → Future<Either<Failure, Unit>>` |
| `restore_product.dart` | `RestoreProduct` | `call(String id) → Future<Either<Failure, Unit>>` |
| `permanent_delete_product.dart` | `PermanentDeleteProduct` | `call(String id) → Future<Either<Failure, Unit>>` |

**Validation in `SaveProduct`:**
- `name` must not be empty → return `ValidationFailure('Name is required')`.
- `price` must be >= 0 → return `ValidationFailure('Price must be non-negative')`.
- `unit` must not be empty → return `ValidationFailure('Unit is required')`.
- On pass, delegate to repository.

---

## Data Layer

### Hive Model

File: `lib/features/products/data/models/product_model.dart`

```
@HiveType(typeId: 1)
ProductModel extends HiveObject
  @HiveField(0) id: String
  @HiveField(1) name: String
  @HiveField(2) price: double
  @HiveField(3) unit: String
  @HiveField(4) isDeleted: bool
  @HiveField(5) createdAt: DateTime
  @HiveField(6) updatedAt: DateTime
```

- Run `dart run build_runner build` to generate `product_model.g.dart`.
- Provides `toEntity()` → `Product` and a static/factory `fromEntity(Product)` → `ProductModel`.

### Data Source

File: `lib/features/products/data/datasources/product_local_data_source.dart`

```
abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getAll();
  Future<List<ProductModel>> getDeleted();
  Future<ProductModel?> getById(String id);
  Future<void> save(ProductModel model);
  Future<void> deleteById(String id);   // physical removal (for permanentDelete)
}
```

Implementation: `ProductLocalDataSourceImpl`

- Injects `Box<ProductModel>` (from GetIt).
- `getAll()` — `box.values.where((m) => !m.isDeleted).toList()`.
- `getDeleted()` — `box.values.where((m) => m.isDeleted).toList()`.
- `getById(id)` — `box.get(id)` (key is `id`).
- `save(model)` — `box.put(model.id, model)`.
- `deleteById(id)` — `box.delete(id)`.

### Repository Implementation

File: `lib/features/products/data/repositories/product_repository_impl.dart`

- Implements `ProductRepository`.
- Wraps all data source calls in `try/catch` → maps exceptions to `StorageFailure`.
- `softDelete` — gets model, sets `isDeleted = true`, `updatedAt = DateTime.now()`, saves.
- `restore` — gets model, sets `isDeleted = false`, `updatedAt = DateTime.now()`, saves.
- `permanentDelete` — calls data source `deleteById`.

---

## Presentation Layer

### BLoC

Files in `lib/features/products/presentation/bloc/`:

**Events** (`product_event.dart`):
```
ProductEvent (sealed/freezed)
  ProductsLoaded()
  ProductsTrashLoaded()
  ProductSaveRequested(Product product)
  ProductDeleteRequested(String id)
  ProductRestoreRequested(String id)
  ProductPermanentDeleteRequested(String id)
```

**States** (`product_state.dart`):
```
ProductState (sealed/freezed)
  initial()
  loading()
  loaded(List<Product> products)
  trashLoaded(List<Product> products)
  saving()
  saveSuccess()
  error(Failure failure)
```

**BLoC** (`product_bloc.dart`):
- Injects: `GetProducts`, `GetDeletedProducts`, `SaveProduct`, `SoftDeleteProduct`, `RestoreProduct`, `PermanentDeleteProduct`.
- `on<ProductsLoaded>` — emits `loading()`, calls `GetProducts`, emits `loaded(products)` or `error(failure)`.
- `on<ProductsTrashLoaded>` — emits `loading()`, calls `GetDeletedProducts`, emits `trashLoaded(products)` or `error(failure)`.
- `on<ProductSaveRequested>` — emits `saving()`, calls `SaveProduct`, emits `saveSuccess()` or `error(failure)`.
- `on<ProductDeleteRequested>` — calls `SoftDeleteProduct`, then re-adds `ProductsLoaded()`.
- `on<ProductRestoreRequested>` — calls `RestoreProduct`, then re-adds `ProductsTrashLoaded()`.
- `on<ProductPermanentDeleteRequested>` — calls `PermanentDeleteProduct`, then re-adds `ProductsTrashLoaded()`.

### Pages

**`lib/features/products/presentation/pages/product_list_page.dart`**

- `ProductListPage` — `StatefulWidget` with two tabs: **Active** and **Trash**.
- Uses `DefaultTabController` with `TabBar` inside `AppBar`.
- Provides `ProductBloc` via `BlocProvider`.
- On init, adds `ProductsLoaded()`.
- On tab switch to Trash, adds `ProductsTrashLoaded()`.
- Active tab: `BlocBuilder` on `loaded` state → `ListView` of `ProductListTile`.
  - On delete: shows `ConfirmDeleteDialog`, on confirm adds `ProductDeleteRequested(id)`.
- Trash tab: `BlocBuilder` on `trashLoaded` state → `ListView` of `ProductTrashTile`.
- FAB: navigates to `/products/new`.
- Shows `AppLoadingWidget` on `loading` state.
- Shows `AppErrorWidget` on `error` state with retry.
- Shows `AppEmptyStateWidget` when list is empty.

**`lib/features/products/presentation/pages/product_form_page.dart`**

- `ProductFormPage` — receives optional `productId` from route params.
- If `productId` is non-null, loads existing product via `GetById` (or from bloc state) and pre-fills form.
- Form fields:
  - Name: `TextFormField`, required.
  - Price: `TextFormField`, `TextInputType.numberWithOptions(decimal: true)`, required, >= 0.
  - Unit: `TextFormField`, required (e.g. "kg", "pcs").
- Save button: adds `ProductSaveRequested(product)` where `product` is:
  - New: `Product(id: uuid, ..., isDeleted: false, createdAt: now, updatedAt: now)`.
  - Edit: existing product `copyWith(name, price, unit, updatedAt: now)`.
- On `saveSuccess` state: `context.pop()`.
- On `error` state: show `SnackBar` with failure message.
- Uses `LabeledField` for each field.
- Uses `PrimaryButton` for save, with `isLoading: true` during `saving` state.

### Widgets

**`lib/features/products/presentation/widgets/product_list_tile.dart`**
```
ProductListTile({ required Product product, required VoidCallback onDelete, required VoidCallback onEdit })
```
- `ListTile` showing name, price + unit as subtitle.
- Trailing: edit icon + delete icon.

**`lib/features/products/presentation/widgets/product_trash_tile.dart`**
```
ProductTrashTile({ required Product product, required VoidCallback onRestore, required VoidCallback onPermanentDelete })
```
- `ListTile` with muted/strikethrough styling.
- Trailing: restore icon + permanent delete icon.
- Permanent delete shows `ConfirmDeleteDialog` before proceeding.

---

## Dependency Injection Registration

In `lib/features/products/data/datasources/product_local_data_source.dart`:
- `@LazySingleton(as: ProductLocalDataSource)` on `ProductLocalDataSourceImpl`.

In `lib/features/products/data/repositories/product_repository_impl.dart`:
- `@LazySingleton(as: ProductRepository)` on `ProductRepositoryImpl`.

In each use case:
- `@injectable` annotation.

`ProductBloc`:
- `@injectable` annotation (transient — new instance per page).

`Box<ProductModel>`:
- Register in `lib/core/di/injection.dart` (or a products-specific module) as:
  ```dart
  @module
  abstract class ProductsModule {
    @lazySingleton
    Box<ProductModel> get productBox => Hive.box<ProductModel>(HiveBoxNames.products);
  }
  ```

---

## Files to Create

```
lib/features/products/domain/entities/product.dart
lib/features/products/domain/repositories/product_repository.dart
lib/features/products/domain/usecases/get_products.dart
lib/features/products/domain/usecases/get_deleted_products.dart
lib/features/products/domain/usecases/save_product.dart
lib/features/products/domain/usecases/soft_delete_product.dart
lib/features/products/domain/usecases/restore_product.dart
lib/features/products/domain/usecases/permanent_delete_product.dart
lib/features/products/data/models/product_model.dart
lib/features/products/data/models/product_model.g.dart          ← generated
lib/features/products/data/datasources/product_local_data_source.dart
lib/features/products/data/repositories/product_repository_impl.dart
lib/features/products/presentation/bloc/product_event.dart
lib/features/products/presentation/bloc/product_state.dart
lib/features/products/presentation/bloc/product_bloc.dart
lib/features/products/presentation/pages/product_list_page.dart
lib/features/products/presentation/pages/product_form_page.dart
lib/features/products/presentation/widgets/product_list_tile.dart
lib/features/products/presentation/widgets/product_trash_tile.dart
test/features/products/domain/usecases/get_products_test.dart
test/features/products/domain/usecases/save_product_test.dart
test/features/products/domain/usecases/soft_delete_product_test.dart
test/features/products/domain/usecases/restore_product_test.dart
test/features/products/data/repositories/product_repository_impl_test.dart
test/features/products/presentation/bloc/product_bloc_test.dart
```

---

## Test Coverage

### Use Case Tests (mock `ProductRepository` with mocktail)

- `GetProductsTest` — returns list on success; returns `StorageFailure` on error.
- `SaveProductTest`:
  - Valid product → delegates to repository.
  - Empty name → returns `ValidationFailure`.
  - Negative price → returns `ValidationFailure`.
  - Empty unit → returns `ValidationFailure`.
- `SoftDeleteProductTest` — delegates to repository with correct id.
- `RestoreProductTest` — delegates to repository with correct id.

### Repository Tests (mock `ProductLocalDataSource`)

- `getAll` — calls data source `getAll`, maps models to entities.
- `softDelete` — fetches model, mutates fields, saves; returns `Left(StorageFailure)` on exception.
- `permanentDelete` — calls `deleteById`.

### BLoC Tests (use `bloc_test`, mock all use cases)

- `ProductsLoaded` → emits `[loading(), loaded(products)]`.
- `ProductsLoaded` when use case fails → emits `[loading(), error(failure)]`.
- `ProductSaveRequested` valid → emits `[saving(), saveSuccess()]`.
- `ProductDeleteRequested` → calls `SoftDeleteProduct`, then re-loads.

---

## Verification Checklist

- [ ] `build_runner` generates `product_model.g.dart` without errors.
- [ ] Product list shows active products; Trash tab shows soft-deleted products.
- [ ] Creating a product with empty name shows validation error.
- [ ] Soft-deleting moves product to Trash tab.
- [ ] Restoring from Trash moves product back to Active tab.
- [ ] Permanent delete removes from Trash (not recoverable).
- [ ] All unit tests pass.
