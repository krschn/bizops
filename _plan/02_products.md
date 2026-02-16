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

- Immutable via `const` constructor.
- Implements `Equatable` — equality based on all fields.
- `copyWith(...)` method for field updates.
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

```dart
class ProductModel extends HiveObject {
  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  String id;
  String name;
  double price;
  String unit;
  bool isDeleted;
  DateTime createdAt;
  DateTime updatedAt;

  Product toEntity() => Product(
    id: id, name: name, price: price, unit: unit,
    isDeleted: isDeleted, createdAt: createdAt, updatedAt: updatedAt,
  );

  static ProductModel fromEntity(Product p) => ProductModel(
    id: p.id, name: p.name, price: p.price, unit: p.unit,
    isDeleted: p.isDeleted, createdAt: p.createdAt, updatedAt: p.updatedAt,
  );
}

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 1;

  @override
  ProductModel read(BinaryReader reader) {
    return ProductModel(
      id: reader.readString(),
      name: reader.readString(),
      price: reader.readDouble(),
      unit: reader.readString(),
      isDeleted: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeDouble(obj.price)
      ..writeString(obj.unit)
      ..writeBool(obj.isDeleted)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
```

No `@HiveType`/`@HiveField` annotations. No generated `.g.dart` file. The adapter is registered in `hive_initializer.dart` via `Hive.registerAdapter(ProductModelAdapter())`.

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

**Events** (`product_event.dart`) — plain sealed classes:
```dart
sealed class ProductEvent {
  const ProductEvent();
}
final class ProductsLoaded extends ProductEvent {
  const ProductsLoaded();
}
final class ProductsTrashLoaded extends ProductEvent {
  const ProductsTrashLoaded();
}
final class ProductSaveRequested extends ProductEvent {
  const ProductSaveRequested(this.product);
  final Product product;
}
final class ProductDeleteRequested extends ProductEvent {
  const ProductDeleteRequested(this.id);
  final String id;
}
final class ProductRestoreRequested extends ProductEvent {
  const ProductRestoreRequested(this.id);
  final String id;
}
final class ProductPermanentDeleteRequested extends ProductEvent {
  const ProductPermanentDeleteRequested(this.id);
  final String id;
}
```

**States** (`product_state.dart`) — plain sealed classes with Equatable:
```dart
sealed class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}
final class ProductInitial extends ProductState {
  const ProductInitial();
}
final class ProductLoading extends ProductState {
  const ProductLoading();
}
final class ProductLoaded extends ProductState {
  const ProductLoaded(this.products);
  final List<Product> products;
  @override
  List<Object?> get props => [products];
}
final class ProductTrashLoaded extends ProductState {
  const ProductTrashLoaded(this.products);
  final List<Product> products;
  @override
  List<Object?> get props => [products];
}
final class ProductSaving extends ProductState {
  const ProductSaving();
}
final class ProductSaveSuccess extends ProductState {
  const ProductSaveSuccess();
}
final class ProductError extends ProductState {
  const ProductError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
```

**BLoC** (`product_bloc.dart`):
- Injects: `GetProducts`, `GetDeletedProducts`, `SaveProduct`, `SoftDeleteProduct`, `RestoreProduct`, `PermanentDeleteProduct`.
- `on<ProductsLoaded>` — emits `ProductLoading()`, calls `GetProducts`, emits `ProductLoaded(products)` or `ProductError(failure)`.
- `on<ProductsTrashLoaded>` — emits `ProductLoading()`, calls `GetDeletedProducts`, emits `ProductTrashLoaded(products)` or `ProductError(failure)`.
- `on<ProductSaveRequested>` — emits `ProductSaving()`, calls `SaveProduct`, emits `ProductSaveSuccess()` or `ProductError(failure)`.
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
- Active tab: `BlocBuilder` on `ProductLoaded` state → `ListView` of `ProductListTile`.
  - On delete: shows `ConfirmDeleteDialog`, on confirm adds `ProductDeleteRequested(id)`.
- Trash tab: `BlocBuilder` on `ProductTrashLoaded` state → `ListView` of `ProductTrashTile`.
- FAB: navigates to `/products/new`.
- Shows `AppLoadingWidget` on `ProductLoading` state.
- Shows `AppErrorWidget` on `ProductError` state with retry.
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
- On `ProductSaveSuccess` state: `context.pop()`.
- On `ProductError` state: show `SnackBar` with failure message.
- Uses `LabeledField` for each field.
- Uses `PrimaryButton` for save, with `isLoading: true` during `ProductSaving` state.

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

In `lib/core/di/injection.dart`, register manually:

```dart
// Products
getIt.registerLazySingleton<Box<ProductModel>>(
  () => Hive.box<ProductModel>(HiveBoxNames.products),
);
getIt.registerLazySingleton<ProductLocalDataSource>(
  () => ProductLocalDataSourceImpl(getIt()),
);
getIt.registerLazySingleton<ProductRepository>(
  () => ProductRepositoryImpl(getIt()),
);
getIt.registerFactory(() => GetProducts(getIt()));
getIt.registerFactory(() => GetDeletedProducts(getIt()));
getIt.registerFactory(() => SaveProduct(getIt()));
getIt.registerFactory(() => SoftDeleteProduct(getIt()));
getIt.registerFactory(() => RestoreProduct(getIt()));
getIt.registerFactory(() => PermanentDeleteProduct(getIt()));
getIt.registerFactory(() => ProductBloc(
  getProducts: getIt(),
  getDeletedProducts: getIt(),
  saveProduct: getIt(),
  softDeleteProduct: getIt(),
  restoreProduct: getIt(),
  permanentDeleteProduct: getIt(),
));
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

- `ProductsLoaded` → emits `[ProductLoading(), ProductLoaded(products)]`.
- `ProductsLoaded` when use case fails → emits `[ProductLoading(), ProductError(failure)]`.
- `ProductSaveRequested` valid → emits `[ProductSaving(), ProductSaveSuccess()]`.
- `ProductDeleteRequested` → calls `SoftDeleteProduct`, then re-loads.

---

## Verification Checklist

- [ ] Product list shows active products; Trash tab shows soft-deleted products.
- [ ] Creating a product with empty name shows validation error.
- [ ] Soft-deleting moves product to Trash tab.
- [ ] Restoring from Trash moves product back to Active tab.
- [ ] Permanent delete removes from Trash (not recoverable).
- [ ] All unit tests pass.
