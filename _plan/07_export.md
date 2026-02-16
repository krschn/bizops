# Plan 07 — Export

**Objective:** Excel export of transactions and payroll via the `excel` package. Files are saved to the device documents folder and shared via the system share sheet. Export is triggered from existing pages (not a standalone page).

---

## Dependencies

- Plan 01 complete (core infrastructure, DI, shared widgets).
- Plan 04 complete (Transactions — entities and use cases).
- Plan 05 complete (Payroll — entities and use cases).
- Plan 06 complete (Reporting — date range use cases used to fetch transaction data for export).

---

## New Packages

Add to `pubspec.yaml`:

```yaml
dependencies:
  excel: ^4.0.6
  path_provider: ^2.1.5
  share_plus: ^10.1.4
```

**Critical:** `excel`, `path_provider`, and `share_plus` must **only** be imported in `lib/features/export/data/`. They must never appear in domain entities, use cases, BLoC, or any presentation widget.

---

## Value Object (not persisted)

File: `lib/features/export/domain/entities/export_result.dart`

```
ExportResult (immutable, equatable)
  filePath: String
  fileName: String
  exportedAt: DateTime
```

---

## Domain Layer

### Repository Interface

File: `lib/features/export/domain/repositories/export_repository.dart`

```
abstract class ExportRepository {
  /// Writes transaction lines to an Excel file and returns the file path.
  Future<Either<Failure, ExportResult>> exportTransactions({
    required List<Transaction> transactions,
    required DateTime from,
    required DateTime to,
  });

  /// Writes payroll entries to an Excel file and returns the file path.
  Future<Either<Failure, ExportResult>> exportPayroll({
    required PayrollPeriod period,
    required List<PayrollEntry> entries,
  });

  /// Opens the system share sheet for the given file path.
  Future<Either<Failure, Unit>> shareFile(String filePath);
}
```

### Use Cases

All in `lib/features/export/domain/usecases/`.

---

**`lib/features/export/domain/usecases/export_transactions_to_excel.dart`**

```
ExportTransactionsToExcel
  Injects: TransactionRepository, ExportRepository
  call(DateTime from, DateTime to) → Future<Either<Failure, ExportResult>>
```

Logic:
1. Call `TransactionRepository.getByDateRange(from, to)`.
2. Filter: exclude transactions where `isDeleted == true`.
3. Collect all non-deleted lines from remaining transactions.
4. Call `ExportRepository.exportTransactions(transactions: ..., from: from, to: to)`.
5. Return `ExportResult`.

---

**`lib/features/export/domain/usecases/export_payroll_to_excel.dart`**

```
ExportPayrollToExcel
  Injects: PayrollEntryRepository, ExportRepository
  call(PayrollPeriod period) → Future<Either<Failure, ExportResult>>
```

Logic:
1. Call `PayrollEntryRepository.getByPeriod(period.id)` — returns non-deleted entries.
2. Call `ExportRepository.exportPayroll(period: period, entries: entries)`.
3. Return `ExportResult`.

---

**`lib/features/export/domain/usecases/share_export_file.dart`**

```
ShareExportFile
  Injects: ExportRepository
  call(String filePath) → Future<Either<Failure, Unit>>
```

- Delegates to `ExportRepository.shareFile(filePath)`.

---

## Data Layer

### Repository Implementation

File: `lib/features/export/data/repositories/export_repository_impl.dart`

Implements `ExportRepository`.

Only this file (and helpers in `lib/features/export/data/`) may import `excel`, `path_provider`, or `share_plus`.

#### `exportTransactions` implementation:

1. Create new `Excel` workbook: `var excel = Excel.createExcel()`.
2. Get/create sheet named "Transactions": `Sheet sheet = excel['Transactions']`.
3. Delete the default "Sheet1" if it exists.
4. Write header row (row 0):
   ```
   Date | Transaction ID | Supplier | Product | Unit | Qty | Unit Price | Line Total
   ```
5. For each transaction (sorted by `transactedAt`), for each non-deleted line:
   - Row: `transactedAt` formatted "yyyy-MM-dd HH:mm", first 8 chars of `transaction.id`, `supplierName`, `productName`, `unit`, `quantity`, `unitPrice`, `lineTotal`.
6. If no lines exist (edge case): write header only, no data rows.
7. Write Grand Total row at the bottom:
   ```
   [empty] | [empty] | [empty] | [empty] | [empty] | [empty] | Grand Total | [sum]
   ```
8. Generate file name: `transactions_YYYYMMDD_YYYYMMDD.xlsx` (from/to dates).
9. Get documents directory via `path_provider`: `getApplicationDocumentsDirectory()`.
10. Write bytes: `File(filePath).writeAsBytesSync(excel.encode()!)`.
11. Return `ExportResult(filePath: filePath, fileName: fileName, exportedAt: DateTime.now())`.
12. Wrap entire operation in `try/catch` → `StorageFailure` on error.

#### `exportPayroll` implementation:

1. Create `Excel` workbook.
2. Sheet named "Payroll".
3. Header row (row 0):
   ```
   Employee | Days Worked | Daily Rate | Total Pay | Notes
   ```
4. Row 1 (period info): merge or use a label row showing `period.label`.
5. For each non-deleted entry (already filtered before being passed in):
   - Row: `employeeName`, `daysWorked`, `dailyRate`, `totalPay`, `notes`.
6. Period Total row at bottom:
   ```
   [empty] | [empty] | Period Total | [sum of totalPay]
   ```
7. File name: `payroll_[period.label sanitized].xlsx` (replace spaces and special chars with underscores).
8. Write to documents directory.
9. Return `ExportResult`.

#### `shareFile` implementation:

```dart
await Share.shareXFiles([XFile(filePath)], text: fileName);
return Right(unit);
```

Wrap in `try/catch` → `UnexpectedFailure` on error.

---

## Presentation Layer

### BLoC

Files: `lib/features/export/presentation/bloc/`

**Events** (`export_event.dart`) — plain sealed classes:
```dart
sealed class ExportEvent { const ExportEvent(); }
final class TransactionExportRequested extends ExportEvent {
  const TransactionExportRequested(this.from, this.to);
  final DateTime from; final DateTime to;
}
final class PayrollExportRequested extends ExportEvent {
  const PayrollExportRequested(this.period); final PayrollPeriod period;
}
final class ExportFileShared extends ExportEvent {
  const ExportFileShared(this.filePath); final String filePath;
}
```

**States** (`export_state.dart`) — plain sealed classes with Equatable:
```dart
sealed class ExportState extends Equatable {
  const ExportState();
  @override List<Object?> get props => [];
}
final class ExportInitial extends ExportState { const ExportInitial(); }
final class ExportExporting extends ExportState { const ExportExporting(); }
final class ExportSuccess extends ExportState {
  const ExportSuccess(this.result); final ExportResult result;
  @override List<Object?> get props => [result];
}
final class ExportSharing extends ExportState { const ExportSharing(); }
final class ExportShareSuccess extends ExportState { const ExportShareSuccess(); }
final class ExportError extends ExportState {
  const ExportError(this.failure); final Failure failure;
  @override List<Object?> get props => [failure];
}
```

**BLoC** (`export_bloc.dart`):
- Injects: `ExportTransactionsToExcel`, `ExportPayrollToExcel`, `ShareExportFile`.
- `on<TransactionExportRequested>` → emits `exporting()`, calls use case, emits `exportSuccess(result)` or `error(failure)`.
- `on<PayrollExportRequested>` → emits `exporting()`, calls use case, emits `exportSuccess(result)` or `error(failure)`.
- `on<ExportFileShared>` → emits `sharing()`, calls `ShareExportFile`, emits `shareSuccess()` or `error(failure)`.

---

### Widgets

Export is invoked from existing pages — no standalone export page.

**`lib/features/export/presentation/widgets/export_action_button.dart`**
```
ExportActionButton({ required VoidCallback onPressed, bool isLoading = false })
```
- `IconButton` with `Icons.file_download` (or `Icons.ios_share` on all platforms — same icon, no platform branch).
- Shows `CircularProgressIndicator` in place of icon when `isLoading == true`.
- Used in `AppBar` actions of `ReportPage` and `PayrollMainPage`.

**`lib/features/export/presentation/widgets/export_success_dialog.dart`**
```
ExportSuccessDialog({ required ExportResult result, required VoidCallback onShare, required VoidCallback onDismiss })
  static Future<void> show(BuildContext context, ExportResult result, VoidCallback onShare)
```
- `AlertDialog` showing:
  - Title: "Export Complete"
  - Content: file name + "File saved to documents folder."
  - Actions: "Share" button + "Dismiss" button.
- Tapping "Share" calls `onShare` (which dispatches `ExportFileShared(result.filePath)`).

---

### Integration with Existing Pages

#### `ReportPage` (`lib/features/reporting/presentation/pages/report_page.dart`)

- Add `ExportBloc` to the `BlocProvider` tree for `ReportPage`.
- AppBar action: `ExportActionButton`:
  - On press: dispatches `TransactionExportRequested(summary.startDate, summary.endDate)` where `summary` comes from current `ReportBloc` `loaded` state.
  - `isLoading: true` when `ExportBloc` state is `exporting()`.
- `BlocListener<ExportBloc, ExportState>`:
  - On `exportSuccess(result)`: show `ExportSuccessDialog`.
  - On `error(failure)`: show `SnackBar` with error message.
  - On `shareSuccess`: dismiss dialog (if open).

#### `PayrollMainPage` (`lib/features/payroll/presentation/pages/payroll_main_page.dart`)

- Add `ExportBloc` to `BlocProvider` tree.
- AppBar action: `ExportActionButton`:
  - On press: dispatches `PayrollExportRequested(selectedPeriod)` where `selectedPeriod` is the currently selected `PayrollPeriod`.
  - Disabled/loading when no period selected or during export.
- Same `BlocListener` pattern as `ReportPage`.

---

## Dependency Injection

In `lib/core/di/injection.dart`, register manually:

```dart
// Export
getIt.registerLazySingleton<ExportRepository>(
  () => ExportRepositoryImpl(),
);
getIt.registerFactory(() => ExportTransactionsToExcel(getIt(), getIt()));
getIt.registerFactory(() => ExportPayrollToExcel(getIt(), getIt()));
getIt.registerFactory(() => ShareExportFile(getIt()));
getIt.registerFactory(() => ExportBloc(
  exportTransactionsToExcel: getIt(),
  exportPayrollToExcel: getIt(),
  shareExportFile: getIt(),
));
```

No Hive boxes needed for export. No empty module class.

---

## File Naming Convention

Generated programmatically — no user input involved (no injection risk).

| Export Type | File Name Pattern | Example |
|---|---|---|
| Transactions | `transactions_YYYYMMDD_YYYYMMDD.xlsx` | `transactions_20260210_20260216.xlsx` |
| Payroll | `payroll_[sanitized_label].xlsx` | `payroll_Feb_10_16_2026.xlsx` |

Sanitization: replace all non-alphanumeric characters (except underscores) with `_` using a simple `RegExp('[^a-zA-Z0-9]').replaceAll(label, '_')`.

---

## Files to Create

```
lib/features/export/domain/entities/export_result.dart
lib/features/export/domain/repositories/export_repository.dart
lib/features/export/domain/usecases/export_transactions_to_excel.dart
lib/features/export/domain/usecases/export_payroll_to_excel.dart
lib/features/export/domain/usecases/share_export_file.dart
lib/features/export/data/repositories/export_repository_impl.dart
lib/features/export/presentation/bloc/export_event.dart
lib/features/export/presentation/bloc/export_state.dart
lib/features/export/presentation/bloc/export_bloc.dart
lib/features/export/presentation/widgets/export_action_button.dart
lib/features/export/presentation/widgets/export_success_dialog.dart
test/features/export/domain/usecases/export_transactions_to_excel_test.dart
test/features/export/domain/usecases/export_payroll_to_excel_test.dart
test/features/export/presentation/bloc/export_bloc_test.dart
```

---

## Test Coverage

### `ExportTransactionsToExcelTest` (mock `TransactionRepository` and `ExportRepository`)

- Fetches transactions in range, filters deleted, passes to `ExportRepository`.
- `ExportRepository` returns success → use case returns `Right(ExportResult)`.
- `TransactionRepository` returns failure → use case returns `Left(failure)`.
- All transactions deleted → passes empty list to repository (zero-row edge case handled in repo).

### `ExportPayrollToExcelTest` (mock `PayrollEntryRepository` and `ExportRepository`)

- Fetches non-deleted entries for period, passes to `ExportRepository`.
- Returns `Right(ExportResult)` on success.
- Returns `Left(failure)` if repository fails.

### `ExportBlocTest` (mock all use cases)

- `TransactionExportRequested` → emits `[exporting(), exportSuccess(result)]`.
- `TransactionExportRequested` when use case fails → emits `[exporting(), error(failure)]`.
- `PayrollExportRequested` → emits `[exporting(), exportSuccess(result)]`.
- `ExportFileShared` → emits `[sharing(), shareSuccess()]`.
- `ExportFileShared` when share fails → emits `[sharing(), error(failure)]`.

---

## Key Constraints

- `excel`, `path_provider`, `share_plus` are never imported outside `lib/features/export/data/`.
- File names are always generated by code — no user-supplied strings in file paths.
- Zero-row edge case: if no data rows exist, write header row only. Do not throw an error.
- `ExportBloc` is provided at the page level (`ReportPage`, `PayrollMainPage`) — not at the app level.
- `Share.shareXFiles` is a fire-and-forget call from the user's perspective; the app does not need to know if the user completed or cancelled the share action.

---

## Verification Checklist

- [ ] Tapping export icon on `ReportPage` generates a `.xlsx` file in the documents directory.
- [ ] `ExportSuccessDialog` appears with correct file name after export.
- [ ] Tapping "Share" in the dialog opens the system share sheet.
- [ ] Exported transactions sheet has one row per non-deleted line + Grand Total row.
- [ ] Exported payroll sheet has one row per non-deleted entry + Period Total row.
- [ ] Export with zero data rows produces a valid `.xlsx` file with header only (no crash).
- [ ] Tapping export icon on `PayrollMainPage` generates payroll `.xlsx` for selected period.
- [ ] `excel`, `path_provider`, `share_plus` imports are confined to `lib/features/export/data/`.
- [ ] All unit and BLoC tests pass.
