# Plan 04 — Transactions DONE

**Objective:** Multi-line transactions with auto-stamped datetime, supplier+product snapshot per line, auto-computed totals. Both line-level and transaction-level soft-delete + trash/restore.

---

## Dependencies

- Plan 01 complete (core infrastructure).
- Plan 02 complete (Products — needed to load product picker).
- Plan 03 complete (Suppliers — needed to load supplier picker).

---

## New Packages

Add to `pubspec.yaml`:

```yaml
dependencies:
  uuid: ^4.5.1
```

---

## Core Utility

File: `lib/core/utils/transaction_utils.dart`

```dart
/// Pure function — no BLoC/Hive dependencies.
double computeGrandTotal(List<TransactionLine> lines) {
  return lines
      .where((l) => !l.isDeleted)
      .fold(0.0, (sum, l) => sum + l.lineTotal);
}
```

- `lineTotal` = `quantity * unitPrice` (computed at line-creation time, stored).
- Only active (non-deleted) lines contribute to the grand total.
- Unit-tested independently of BLoC and Hive.

---

## Domain Layer

### Entities

**File: `lib/features/transactions/domain/entities/transaction_line.dart`**

```
TransactionLine (immutable, equatable)
  id: String
  transactionId: String
  supplierId: String
  supplierName: String       ← denormalized snapshot
  productId: String
  productName: String        ← denormalized snapshot
  unit: String               ← denormalized snapshot from product
  quantity: double
  unitPrice: double          ← denormalized snapshot from product price at time of entry
  lineTotal: double          ← quantity * unitPrice, computed and stored
  isDeleted: bool
  sortOrder: int
```

**File: `lib/features/transactions/domain/entities/transaction.dart`**

```
Transaction (immutable, equatable)
  id: String
  transactedAt: DateTime     ← set once on creation; never user-editable
  lines: List<TransactionLine>
  grandTotal: double         ← sum of non-deleted lineTotals; recomputed in BLoC and stored
  isDeleted: bool
  createdAt: DateTime
  updatedAt: DateTime
```

**Denormalization rule:** `supplierName`, `productName`, `unit`, and `unitPrice` are copied from the selected supplier/product at the moment the line is added. They are never recalculated from current supplier/product data after that point.

### Repository Interface

File: `lib/features/transactions/domain/repositories/transaction_repository.dart`

```
abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getAll();
  Future<Either<Failure, List<Transaction>>> getDeleted();
  Future<Either<Failure, Transaction>> getById(String id);
  Future<Either<Failure, Unit>> save(Transaction transaction);
  Future<Either<Failure, Unit>> softDeleteTransaction(String id);
  Future<Either<Failure, Unit>> restoreTransaction(String id);
  Future<Either<Failure, Unit>> permanentDeleteTransaction(String id);
  Future<Either<Failure, Unit>> softDeleteLine(String transactionId, String lineId);
  Future<Either<Failure, Unit>> restoreLine(String transactionId, String lineId);
  Future<Either<Failure, List<Transaction>>> getByDateRange(DateTime from, DateTime to);
}
```

**`getAll()`** — returns transactions where `isDeleted == false`, ordered by `transactedAt` descending.
**`getDeleted()`** — returns transactions where `isDeleted == true`.
**`getByDateRange(from, to)`** — returns non-deleted transactions where `transactedAt` is within `[from, to]` (inclusive). Used by Reporting (Plan 06).
**`softDeleteLine`** — mutates the line's `isDeleted = true` within the transaction, recomputes `grandTotal`, saves the transaction.
**`restoreLine`** — mutates the line's `isDeleted = false`, recomputes `grandTotal`, saves.

### Use Cases

All in `lib/features/transactions/domain/usecases/`.

| File | Class | Signature |
|---|---|---|
| `get_transactions.dart` | `GetTransactions` | `call() → Future<Either<Failure, List<Transaction>>>` |
| `get_deleted_transactions.dart` | `GetDeletedTransactions` | `call() → Future<Either<Failure, List<Transaction>>>` |
| `save_transaction.dart` | `SaveTransaction` | `call(Transaction tx) → Future<Either<Failure, Unit>>` |
| `soft_delete_transaction.dart` | `SoftDeleteTransaction` | `call(String id) → Future<Either<Failure, Unit>>` |
| `restore_transaction.dart` | `RestoreTransaction` | `call(String id) → Future<Either<Failure, Unit>>` |
| `permanent_delete_transaction.dart` | `PermanentDeleteTransaction` | `call(String id) → Future<Either<Failure, Unit>>` |
| `soft_delete_line.dart` | `SoftDeleteLine` | `call(String txId, String lineId) → Future<Either<Failure, Unit>>` |
| `restore_line.dart` | `RestoreLine` | `call(String txId, String lineId) → Future<Either<Failure, Unit>>` |
| `get_transactions_by_date_range.dart` | `GetTransactionsByDateRange` | `call(DateTime from, DateTime to) → Future<Either<Failure, List<Transaction>>>` |

**Validation in `SaveTransaction`:**
- Transaction must have at least one non-deleted line → `ValidationFailure('Transaction must have at least one line')`.
- Each line: `quantity > 0` → else `ValidationFailure('Quantity must be positive')`.
- Each line: `unitPrice >= 0` → else `ValidationFailure('Unit price must be non-negative')`.
- On pass, delegate to repository.

---

## Data Layer

### Hive Models

**File: `lib/features/transactions/data/models/transaction_line_model.dart`**

```dart
class TransactionLineModel extends HiveObject {
  TransactionLineModel({
    required this.id, required this.transactionId,
    required this.supplierId, required this.supplierName,
    required this.productId, required this.productName,
    required this.unit, required this.quantity,
    required this.unitPrice, required this.lineTotal,
    required this.isDeleted, required this.sortOrder,
  });

  String id; String transactionId;
  String supplierId; String supplierName;
  String productId; String productName;
  String unit; double quantity;
  double unitPrice; double lineTotal;
  bool isDeleted; int sortOrder;
}

class TransactionLineModelAdapter extends TypeAdapter<TransactionLineModel> {
  @override final int typeId = 3;

  @override
  TransactionLineModel read(BinaryReader reader) => TransactionLineModel(
    id: reader.readString(), transactionId: reader.readString(),
    supplierId: reader.readString(), supplierName: reader.readString(),
    productId: reader.readString(), productName: reader.readString(),
    unit: reader.readString(), quantity: reader.readDouble(),
    unitPrice: reader.readDouble(), lineTotal: reader.readDouble(),
    isDeleted: reader.readBool(), sortOrder: reader.readInt(),
  );

  @override
  void write(BinaryWriter writer, TransactionLineModel obj) {
    writer
      ..writeString(obj.id)..writeString(obj.transactionId)
      ..writeString(obj.supplierId)..writeString(obj.supplierName)
      ..writeString(obj.productId)..writeString(obj.productName)
      ..writeString(obj.unit)..writeDouble(obj.quantity)
      ..writeDouble(obj.unitPrice)..writeDouble(obj.lineTotal)
      ..writeBool(obj.isDeleted)..writeInt(obj.sortOrder);
  }
}
```

**File: `lib/features/transactions/data/models/transaction_model.dart`**

```dart
class TransactionModel extends HiveObject {
  TransactionModel({
    required this.id, required this.transactedAt,
    required this.lines, required this.grandTotal,
    required this.isDeleted, required this.createdAt, required this.updatedAt,
  });

  String id; DateTime transactedAt;
  List<TransactionLineModel> lines; double grandTotal;
  bool isDeleted; DateTime createdAt; DateTime updatedAt;
}

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override final int typeId = 4;

  @override
  TransactionModel read(BinaryReader reader) => TransactionModel(
    id: reader.readString(),
    transactedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    lines: reader.readList().cast<TransactionLineModel>(),
    grandTotal: reader.readDouble(),
    isDeleted: reader.readBool(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
  );

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeString(obj.id)
      ..writeInt(obj.transactedAt.millisecondsSinceEpoch)
      ..writeList(obj.lines)
      ..writeDouble(obj.grandTotal)
      ..writeBool(obj.isDeleted)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
```

No `@HiveType`/`@HiveField` annotations. No generated `.g.dart` files. Lines are embedded (nested) inside `TransactionModel` — no separate box for lines. Both models provide `toEntity()` / `fromEntity()` mapping.

### Data Source

File: `lib/features/transactions/data/datasources/transaction_local_data_source.dart`

```
abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getAll();
  Future<List<TransactionModel>> getDeleted();
  Future<TransactionModel?> getById(String id);
  Future<void> save(TransactionModel model);
  Future<void> deleteById(String id);
  Future<List<TransactionModel>> getByDateRange(DateTime from, DateTime to);
}
```

Implementation: `TransactionLocalDataSourceImpl`

- Injects `Box<TransactionModel>`.
- `getAll()` — `box.values.where((m) => !m.isDeleted).toList()`, sorted by `transactedAt` descending.
- `getByDateRange(from, to)` — filters by `!m.isDeleted && m.transactedAt >= from && m.transactedAt <= to`.

### Repository Implementation

File: `lib/features/transactions/data/repositories/transaction_repository_impl.dart`

- Implements `TransactionRepository`.
- Wraps all calls in `try/catch` → `StorageFailure`.
- `softDeleteTransaction` — gets model, sets `isDeleted = true`, `updatedAt = now`, saves.
- `restoreTransaction` — gets model, sets `isDeleted = false`, `updatedAt = now`, saves.
- `permanentDeleteTransaction` — calls `deleteById`.
- `softDeleteLine(txId, lineId)`:
  1. Gets transaction model by `txId`.
  2. Finds line with `lineId` in `model.lines`.
  3. Sets `line.isDeleted = true`.
  4. Recomputes `model.grandTotal` using `computeGrandTotal` (mapped to entities first, or inline sum).
  5. Updates `model.updatedAt = now`.
  6. Saves model.
- `restoreLine(txId, lineId)` — same pattern; sets `line.isDeleted = false`.

---

## Presentation Layer

### Two BLoCs

#### `TransactionListBloc`

Files: `lib/features/transactions/presentation/bloc/transaction_list_bloc/`

**Events** — plain sealed classes:
```dart
sealed class TransactionListEvent { const TransactionListEvent(); }
final class TransactionsLoaded extends TransactionListEvent { const TransactionsLoaded(); }
final class TransactionsTrashLoaded extends TransactionListEvent { const TransactionsTrashLoaded(); }
final class TransactionDeleteRequested extends TransactionListEvent {
  const TransactionDeleteRequested(this.id); final String id;
}
final class TransactionRestoreRequested extends TransactionListEvent {
  const TransactionRestoreRequested(this.id); final String id;
}
final class TransactionPermanentDeleteRequested extends TransactionListEvent {
  const TransactionPermanentDeleteRequested(this.id); final String id;
}
```

**States** — plain sealed classes with Equatable:
```dart
sealed class TransactionListState extends Equatable {
  const TransactionListState();
  @override List<Object?> get props => [];
}
final class TransactionListInitial extends TransactionListState { const TransactionListInitial(); }
final class TransactionListLoading extends TransactionListState { const TransactionListLoading(); }
final class TransactionListLoaded extends TransactionListState {
  const TransactionListLoaded(this.transactions);
  final List<Transaction> transactions;
  @override List<Object?> get props => [transactions];
}
final class TransactionListTrashLoaded extends TransactionListState {
  const TransactionListTrashLoaded(this.transactions);
  final List<Transaction> transactions;
  @override List<Object?> get props => [transactions];
}
final class TransactionListError extends TransactionListState {
  const TransactionListError(this.failure);
  final Failure failure;
  @override List<Object?> get props => [failure];
}
```

**BLoC logic:**
- `on<TransactionsLoaded>` → `loading()`, call `GetTransactions`, emit `loaded` or `error`.
- `on<TransactionsTrashLoaded>` → `loading()`, call `GetDeletedTransactions`, emit `trashLoaded` or `error`.
- `on<TransactionDeleteRequested>` → call `SoftDeleteTransaction`, re-add `TransactionsLoaded()`.
- `on<TransactionRestoreRequested>` → call `RestoreTransaction`, re-add `TransactionsTrashLoaded()`.
- `on<TransactionPermanentDeleteRequested>` → call `PermanentDeleteTransaction`, re-add `TransactionsTrashLoaded()`.

#### `TransactionFormBloc`

Files: `lib/features/transactions/presentation/bloc/transaction_form_bloc/`

**Events** — plain sealed classes:
```dart
sealed class TransactionFormEvent { const TransactionFormEvent(); }
final class TransactionFormInitialized extends TransactionFormEvent {
  const TransactionFormInitialized(this.existingTransactionId);
  final String? existingTransactionId;
}
final class TransactionLineAdded extends TransactionFormEvent {
  const TransactionLineAdded(this.line); final TransactionLine line;
}
final class TransactionLineRemoved extends TransactionFormEvent {
  const TransactionLineRemoved(this.lineId); final String lineId;
}
final class TransactionLineRestored extends TransactionFormEvent {
  const TransactionLineRestored(this.lineId); final String lineId;
}
final class TransactionSaveRequested extends TransactionFormEvent {
  const TransactionSaveRequested();
}
```

**States** — plain sealed classes with Equatable:
```dart
sealed class TransactionFormState extends Equatable {
  const TransactionFormState();
  @override List<Object?> get props => [];
}
final class TransactionFormInitial extends TransactionFormState { const TransactionFormInitial(); }
final class TransactionFormLoading extends TransactionFormState { const TransactionFormLoading(); }
final class TransactionFormReady extends TransactionFormState {
  const TransactionFormReady({
    this.existingTransaction, required this.lines,
    required this.availableProducts, required this.availableSuppliers,
    required this.grandTotal,
  });
  final Transaction? existingTransaction;
  final List<TransactionLine> lines;
  final List<Product> availableProducts;
  final List<Supplier> availableSuppliers;
  final double grandTotal;
  @override List<Object?> get props => [existingTransaction, lines, availableProducts, availableSuppliers, grandTotal];
}
final class TransactionFormSaving extends TransactionFormState { const TransactionFormSaving(); }
final class TransactionFormSaveSuccess extends TransactionFormState {
  const TransactionFormSaveSuccess(this.transactionId); final String transactionId;
  @override List<Object?> get props => [transactionId];
}
final class TransactionFormError extends TransactionFormState {
  const TransactionFormError(this.failure); final Failure failure;
  @override List<Object?> get props => [failure];
}
```

**BLoC logic:**
- `on<TransactionFormInitialized>`:
  - Emits `loading()`.
  - In parallel: loads active products via `GetProducts`, active suppliers via `GetSuppliers`.
  - If `existingTransactionId` is non-null, loads transaction via `GetById`.
  - Emits `ready(...)` with loaded data. `grandTotal` computed via `computeGrandTotal`.
- `on<TransactionLineAdded>`:
  - Adds line to draft `lines` list with next `sortOrder`.
  - Recomputes `grandTotal`.
  - Emits updated `ready(...)`.
- `on<TransactionLineRemoved>`:
  - Marks line `isDeleted = true` in draft.
  - Recomputes `grandTotal`.
  - Emits updated `ready(...)`.
- `on<TransactionLineRestored>`:
  - Marks line `isDeleted = false`.
  - Recomputes `grandTotal`.
  - Emits updated `ready(...)`.
- `on<TransactionSaveRequested>`:
  - Builds `Transaction` object:
    - New: `id = uuid`, `transactedAt = DateTime.now()`, `createdAt = now`, `updatedAt = now`.
    - Edit: existing transaction `copyWith(lines: ..., grandTotal: ..., updatedAt: now)`.
  - Calls `SaveTransaction(transaction)`.
  - Emits `saving()` then `saveSuccess(id)` or `error(failure)`.

**Key constraint:** For new transactions, `transactedAt` is set to `DateTime.now()` at the moment `TransactionSaveRequested` is handled — not when the form opens. For edits, `transactedAt` is never changed.

### Pages

**`lib/features/transactions/presentation/pages/transaction_list_page.dart`**

- Two tabs: **Active** and **Trash**.
- Provides `TransactionListBloc` via `BlocProvider`.
- On init, adds `TransactionsLoaded()`.
- Active tab: `ListView` of `TransactionListTile`.
  - On delete: shows `ConfirmDeleteDialog`; on confirm adds `TransactionDeleteRequested(id)`.
- Trash tab: `ListView` of `TransactionTrashTile`.
- FAB: navigates to `/transactions/new`.
- Shows `AppLoadingWidget`, `AppErrorWidget`, `AppEmptyStateWidget` as appropriate.

**`lib/features/transactions/presentation/pages/transaction_form_page.dart`**

- Receives optional `transactionId` from route params.
- Provides `TransactionFormBloc` via `BlocProvider`; on init adds `TransactionFormInitialized(transactionId)`.
- `AppBar` title: "New Transaction" or "Edit Transaction". Shows auto `transactedAt` as subtitle (read-only).
- Body:
  - `ListView` of `TransactionLineFormRow` for each line (including deleted ones via `TransactionLineDeletedRow`).
  - "Add Line" button at bottom of list — opens a modal/bottom sheet or inline form to pick supplier, product, enter quantity.
  - `TransactionTotalBar` pinned at bottom.
- Save button in `AppBar` or at bottom: adds `TransactionSaveRequested()`.
- On `saveSuccess`: `context.pop()`.
- On `error`: shows `SnackBar` with failure message.

**Add Line UI:**
- Supplier dropdown: active suppliers from `ready.availableSuppliers`.
- Product dropdown: active products from `ready.availableProducts`.
- Quantity field: `TextInputType.numberWithOptions(decimal: true)`.
- On confirm: builds `TransactionLine` with denormalized snapshot values, dispatches `TransactionLineAdded`.

### Widgets

**`transaction_list_tile.dart`**
```
TransactionListTile({ required Transaction transaction, required VoidCallback onDelete, required VoidCallback onTap })
```
- Shows: date (`transactedAt` formatted), active line count, grand total.
- Trailing: delete icon.
- Tapping navigates to edit form.

**`transaction_trash_tile.dart`**
```
TransactionTrashTile({ required Transaction transaction, required VoidCallback onRestore, required VoidCallback onPermanentDelete })
```
- Shows same info with muted styling.
- Trailing: restore + permanent delete icons.

**`transaction_line_form_row.dart`**
```
TransactionLineFormRow({ required TransactionLine line, required VoidCallback onDelete })
```
- Shows: supplier name, product name, quantity, unit, unit price, line total.
- Delete icon to soft-delete line (dispatches `TransactionLineRemoved`).

**`transaction_line_deleted_row.dart`**
```
TransactionLineDeletedRow({ required TransactionLine line, required VoidCallback onRestore })
```
- Same info but strikethrough/muted.
- Restore icon.

**`transaction_total_bar.dart`**
```
TransactionTotalBar({ required double grandTotal })
```
- Fixed-height container at bottom showing "Total: [grandTotal formatted as currency]".

---

## Dependency Injection

In `lib/core/di/injection.dart`, register manually:

```dart
// Transactions
getIt.registerLazySingleton<Box<TransactionModel>>(
  () => Hive.box<TransactionModel>(HiveBoxNames.transactions),
);
getIt.registerLazySingleton<TransactionLocalDataSource>(
  () => TransactionLocalDataSourceImpl(getIt()),
);
getIt.registerLazySingleton<TransactionRepository>(
  () => TransactionRepositoryImpl(getIt()),
);
getIt.registerFactory(() => GetTransactions(getIt()));
getIt.registerFactory(() => GetDeletedTransactions(getIt()));
getIt.registerFactory(() => SaveTransaction(getIt()));
getIt.registerFactory(() => SoftDeleteTransaction(getIt()));
getIt.registerFactory(() => RestoreTransaction(getIt()));
getIt.registerFactory(() => PermanentDeleteTransaction(getIt()));
getIt.registerFactory(() => SoftDeleteLine(getIt()));
getIt.registerFactory(() => RestoreLine(getIt()));
getIt.registerFactory(() => GetTransactionsByDateRange(getIt()));
getIt.registerFactory(() => TransactionListBloc(
  getTransactions: getIt(), getDeletedTransactions: getIt(),
  softDeleteTransaction: getIt(), restoreTransaction: getIt(),
  permanentDeleteTransaction: getIt(),
));
getIt.registerFactory(() => TransactionFormBloc(
  getProducts: getIt(), getSuppliers: getIt(),
  saveTransaction: getIt(), softDeleteLine: getIt(), restoreLine: getIt(),
));
```

---

## Files to Create

```
lib/core/utils/transaction_utils.dart
lib/features/transactions/domain/entities/transaction_line.dart
lib/features/transactions/domain/entities/transaction.dart
lib/features/transactions/domain/repositories/transaction_repository.dart
lib/features/transactions/domain/usecases/get_transactions.dart
lib/features/transactions/domain/usecases/get_deleted_transactions.dart
lib/features/transactions/domain/usecases/save_transaction.dart
lib/features/transactions/domain/usecases/soft_delete_transaction.dart
lib/features/transactions/domain/usecases/restore_transaction.dart
lib/features/transactions/domain/usecases/permanent_delete_transaction.dart
lib/features/transactions/domain/usecases/soft_delete_line.dart
lib/features/transactions/domain/usecases/restore_line.dart
lib/features/transactions/domain/usecases/get_transactions_by_date_range.dart
lib/features/transactions/data/models/transaction_line_model.dart
lib/features/transactions/data/models/transaction_model.dart
lib/features/transactions/data/datasources/transaction_local_data_source.dart
lib/features/transactions/data/repositories/transaction_repository_impl.dart
lib/features/transactions/presentation/bloc/transaction_list_bloc/transaction_list_event.dart
lib/features/transactions/presentation/bloc/transaction_list_bloc/transaction_list_state.dart
lib/features/transactions/presentation/bloc/transaction_list_bloc/transaction_list_bloc.dart
lib/features/transactions/presentation/bloc/transaction_form_bloc/transaction_form_event.dart
lib/features/transactions/presentation/bloc/transaction_form_bloc/transaction_form_state.dart
lib/features/transactions/presentation/bloc/transaction_form_bloc/transaction_form_bloc.dart
lib/features/transactions/presentation/pages/transaction_list_page.dart
lib/features/transactions/presentation/pages/transaction_form_page.dart
lib/features/transactions/presentation/widgets/transaction_list_tile.dart
lib/features/transactions/presentation/widgets/transaction_trash_tile.dart
lib/features/transactions/presentation/widgets/transaction_line_form_row.dart
lib/features/transactions/presentation/widgets/transaction_line_deleted_row.dart
lib/features/transactions/presentation/widgets/transaction_total_bar.dart
test/core/utils/transaction_utils_test.dart
test/features/transactions/domain/usecases/save_transaction_test.dart
test/features/transactions/domain/usecases/soft_delete_line_test.dart
test/features/transactions/data/repositories/transaction_repository_impl_test.dart
test/features/transactions/presentation/bloc/transaction_list_bloc_test.dart
test/features/transactions/presentation/bloc/transaction_form_bloc_test.dart
```

---

## Test Coverage

### `transaction_utils_test.dart`
- Empty list → `0.0`.
- All active lines → sum of `lineTotal`.
- Mix of active + deleted → sum of active only.
- Single line → returns its `lineTotal`.

### `SaveTransactionTest`
- Valid transaction → delegates to repository.
- Zero lines → `ValidationFailure`.
- All lines deleted → `ValidationFailure`.
- Line with zero quantity → `ValidationFailure`.

### `SoftDeleteLineTest`
- Delegates `(txId, lineId)` to repository.

### Repository Tests
- `softDeleteTransaction` — sets `isDeleted = true`, saves.
- `softDeleteLine` — finds line, sets `isDeleted = true`, recomputes `grandTotal`, saves.
- `restoreLine` — finds line, sets `isDeleted = false`, recomputes `grandTotal`, saves.
- `getByDateRange` — returns only transactions within range.

### BLoC Tests
- `TransactionsLoaded` → `[loading(), loaded(list)]`.
- `TransactionDeleteRequested` → calls `SoftDeleteTransaction`, re-loads.
- `TransactionFormInitialized` (new) → `[loading(), ready(empty lines, products, suppliers, total: 0)]`.
- `TransactionLineAdded` → updates `ready.lines` and `ready.grandTotal`.
- `TransactionLineRemoved` → marks line deleted, recomputes total.

---

## Verification Checklist

- [ ] Creating a transaction with at least one line saves and appears in list.
- [ ] Attempting to save with zero lines shows validation error.
- [ ] Grand total updates as lines are added/removed during form editing.
- [ ] Soft-deleting a line (within a saved transaction) recomputes stored `grandTotal`.
- [ ] Soft-deleting a transaction moves it to Trash tab.
- [ ] Restoring a transaction returns it to Active tab.
- [ ] Transaction list row shows correct line count and total.
- [ ] `transactedAt` is set on save and never changes on edits.
- [ ] Supplier/product dropdowns show only active records.
- [ ] Lines display snapshots correctly even if product/supplier is later soft-deleted.
- [ ] All unit and BLoC tests pass.
