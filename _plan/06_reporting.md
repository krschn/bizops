# Plan 06 — Reporting

**Objective:** Read-only transaction summaries by daily/weekly/monthly period. Grouped by supplier with subtotals. No data mutations — this is a derived view over existing transaction data.

---

## Dependencies

- Plan 01 complete (core infrastructure, shared widgets).
- Plan 04 complete (Transactions — specifically `TransactionRepository.getByDateRange`).

---

## New Packages

None.

---

## Value Objects (not persisted)

File: `lib/features/reporting/domain/entities/report_entities.dart`

These are pure in-memory objects — never stored to Hive.

```
enum ReportPeriod { daily, weekly, monthly }

SupplierSubtotal (immutable, equatable)
  supplierId: String
  supplierName: String      ← from transaction line snapshot
  lineCount: int            ← number of non-deleted lines for this supplier
  subtotal: double          ← sum of lineTotals for this supplier

TransactionSummary (immutable, equatable)
  period: ReportPeriod
  periodLabel: String       ← human-readable, e.g. "Feb 16, 2026" / "Feb 10–16, 2026" / "February 2026"
  startDate: DateTime
  endDate: DateTime
  supplierSubtotals: List<SupplierSubtotal>   ← sorted by supplierName ascending
  grandTotal: double        ← sum of all subtotals
```

---

## Domain Layer

### No New Repository

Reporting does **not** define a new repository. It uses:

```dart
TransactionRepository.getByDateRange(DateTime from, DateTime to)
```

which is defined and implemented in Plan 04.

### Use Cases

All in `lib/features/reporting/domain/usecases/`.

Each use case:
1. Computes `from`/`to` date range for the requested period.
2. Calls `TransactionRepository.getByDateRange(from, to)`.
3. Filters out deleted transactions (`isDeleted == true`) and deleted lines (`line.isDeleted == true`).
4. Groups remaining lines by `supplierName`.
5. For each supplier group, computes `lineCount` and `subtotal`.
6. Sorts `supplierSubtotals` alphabetically by `supplierName`.
7. Computes `grandTotal`.
8. Returns `Right(TransactionSummary(...))`.

**Zero-transaction behavior:** If no transactions exist for the period, return `Right(TransactionSummary(..., supplierSubtotals: [], grandTotal: 0.0))` — never return an error for empty data.

---

**`lib/features/reporting/domain/usecases/get_daily_report.dart`**

```
GetDailyReport
  call(DateTime date) → Future<Either<Failure, TransactionSummary>>
```

- `from` = start of `date` (00:00:00.000).
- `to` = end of `date` (23:59:59.999).
- `periodLabel` = formatted as "MMM d, yyyy" (e.g. "Feb 16, 2026").

---

**`lib/features/reporting/domain/usecases/get_weekly_report.dart`**

```
GetWeeklyReport
  call(DateTime weekStart) → Future<Either<Failure, TransactionSummary>>
```

- `weekStart` must be a Monday (caller's responsibility).
- `from` = start of `weekStart`.
- `to` = end of `weekStart + 6 days` (Sunday, 23:59:59.999).
- `periodLabel` = "MMM d–d, yyyy" if same month (e.g. "Feb 10–16, 2026") or "MMM d – MMM d, yyyy" if crosses month boundary.

---

**`lib/features/reporting/domain/usecases/get_monthly_report.dart`**

```
GetMonthlyReport
  call(int year, int month) → Future<Either<Failure, TransactionSummary>>
```

- `from` = `DateTime(year, month, 1, 0, 0, 0, 0)`.
- `to` = last millisecond of the last day of `month` in `year`.
- `periodLabel` = "MMMM yyyy" (e.g. "February 2026").
- Last day: `DateTime(year, month + 1, 0)` (Dart wraps month correctly).

---

## Presentation Layer

### BLoC

Files: `lib/features/reporting/presentation/bloc/`

**Events** (`report_event.dart`):
```
ReportEvent (sealed/freezed)
  ReportPeriodChanged(ReportPeriod period)   ← tab switch; resets to current date
  ReportDateNavigated(bool forward)           ← prev/next arrow; forward=true means next
  ReportRefreshed()                           ← re-load current state
```

**States** (`report_state.dart`):
```
ReportState (sealed/freezed)
  initial()
  loading()
  loaded {
    TransactionSummary summary
    ReportPeriod period
    DateTime currentDate        ← the anchor date (day/week-start/month-start) for navigation
    bool canGoForward           ← false if currentDate is today or later (no future reports)
  }
  error(Failure failure)
```

**BLoC** (`report_bloc.dart`):

State carries `currentDate` (the navigation anchor):
- For `daily`: the displayed day.
- For `weekly`: the Monday of the displayed week.
- For `monthly`: the 1st of the displayed month.

Initialization: `currentDate = DateTime.now()` (normalized to start-of-day).

`on<ReportPeriodChanged>`:
- Reset `currentDate` to today (normalized).
- Load report for new period + today.
- Emit `loaded(summary, period, today, canGoForward: false)`.

`on<ReportDateNavigated>`:
- If `forward` and `canGoForward == false` → ignore (no future navigation).
- Compute new `currentDate`:
  - `daily`: ±1 day.
  - `weekly`: ±7 days.
  - `monthly`: ±1 month (use `DateTime(year, month ± 1, 1)`).
- Load report for new date.
- `canGoForward` = new `currentDate` is before today's period start.
- Emit `loaded(...)`.

`on<ReportRefreshed>`:
- Re-load current period + date without changing state.

Default behavior on BLoC creation: emit `loading()`, load daily report for today.

### Pages

**`lib/features/reporting/presentation/pages/report_page.dart`**

- `ReportPage` — provides `ReportBloc` via `BlocProvider`.
- On init: BLoC auto-loads daily report for today (handled in BLoC constructor or initial event).
- `AppBar`: title "Reports", actions include export button (Plan 07).
- Body:
  - `ReportPeriodNavBar` at top.
  - `BlocBuilder` on `loaded` → `ReportSummaryView`.
  - `BlocBuilder` on `loading` → `AppLoadingWidget`.
  - `BlocBuilder` on `error` → `AppErrorWidget(onRetry: () => bloc.add(ReportRefreshed()))`.

### Widgets

**`lib/features/reporting/presentation/widgets/report_period_nav_bar.dart`**
```
ReportPeriodNavBar({
  required ReportPeriod selectedPeriod,
  required DateTime currentDate,
  required bool canGoForward,
  required ValueChanged<ReportPeriod> onPeriodChanged,
  required VoidCallback onPrev,
  required VoidCallback onNext,
})
```
- Top section: `SegmentedButton<ReportPeriod>` with three segments: Daily, Weekly, Monthly.
- Bottom section: left arrow (prev) + period label text + right arrow (next).
- Right arrow is disabled (greyed out) when `canGoForward == false`.
- Period label comes from `summary.periodLabel` (passed via parent, not computed here).

**`lib/features/reporting/presentation/widgets/report_summary_view.dart`**
```
ReportSummaryView({ required TransactionSummary summary })
```
- If `summary.supplierSubtotals.isEmpty`: shows `AppEmptyStateWidget(message: 'No transactions for this period')`.
- Otherwise: `ListView` of `SupplierSubtotalCard` + `ReportGrandTotalBar` pinned at bottom.

**`lib/features/reporting/presentation/widgets/supplier_subtotal_card.dart`**
```
SupplierSubtotalCard({ required SupplierSubtotal subtotal })
```
- `Card` showing:
  - Supplier name (title).
  - Line count (e.g. "12 lines").
  - Subtotal formatted as currency (e.g. "₱ 4,500.00").

**`lib/features/reporting/presentation/widgets/report_grand_total_bar.dart`**
```
ReportGrandTotalBar({ required double grandTotal })
```
- Fixed bar at bottom showing "Grand Total: [formatted amount]".

---

## Dependency Injection

`ReportBloc`: `@injectable` (transient).

Use cases: `@injectable`.

No new repositories or data sources to register.

---

## Files to Create

```
lib/features/reporting/domain/entities/report_entities.dart
lib/features/reporting/domain/usecases/get_daily_report.dart
lib/features/reporting/domain/usecases/get_weekly_report.dart
lib/features/reporting/domain/usecases/get_monthly_report.dart
lib/features/reporting/presentation/bloc/report_event.dart
lib/features/reporting/presentation/bloc/report_state.dart
lib/features/reporting/presentation/bloc/report_bloc.dart
lib/features/reporting/presentation/pages/report_page.dart
lib/features/reporting/presentation/widgets/report_period_nav_bar.dart
lib/features/reporting/presentation/widgets/report_summary_view.dart
lib/features/reporting/presentation/widgets/supplier_subtotal_card.dart
lib/features/reporting/presentation/widgets/report_grand_total_bar.dart
test/features/reporting/domain/usecases/get_daily_report_test.dart
test/features/reporting/domain/usecases/get_weekly_report_test.dart
test/features/reporting/domain/usecases/get_monthly_report_test.dart
test/features/reporting/presentation/bloc/report_bloc_test.dart
```

---

## Test Coverage

### `GetDailyReportTest` (mock `TransactionRepository`)

- Transactions within day → grouped by supplier, correct subtotals.
- Transactions outside day → excluded.
- Deleted transactions → excluded.
- Deleted lines → excluded from supplier totals but transaction not excluded.
- No transactions → `Right(summary with grandTotal: 0.0, supplierSubtotals: [])`.
- Repository failure → `Left(StorageFailure)`.

### `GetWeeklyReportTest`

- Lines across multiple days in week → all included, grouped by supplier.
- Transaction on Sunday of week → included.
- Transaction on Monday of following week → excluded.
- Cross-month week → `periodLabel` uses "MMM d – MMM d, yyyy" format.

### `GetMonthlyReportTest`

- All days in month included.
- Day 1 and last day both included.
- Deleted transactions filtered out.
- `periodLabel` = "February 2026" format.

### `ReportBlocTest`

- BLoC creation → emits `[loading(), loaded(daily for today)]`.
- `ReportPeriodChanged(weekly)` → resets to current week, emits `loaded`.
- `ReportDateNavigated(forward: false)` → navigates back one period.
- `ReportDateNavigated(forward: true)` when `canGoForward == false` → no state change.
- `ReportDateNavigated(forward: true)` when on past date → navigates forward, emits loaded.

---

## Key Constraints

- Uses `supplierName` from transaction line snapshots, not current supplier records. If a supplier was renamed or deleted after a transaction was recorded, the report shows the original snapshotted name.
- Zero-transaction periods always emit `loaded` with zero totals — never `error`.
- No future navigation: `canGoForward` is `false` when the current period contains today or is in the future.
- No new Hive boxes. No writes. This feature is strictly read-only.

---

## Verification Checklist

- [ ] Daily tab defaults to today's date; shows correct supplier breakdown.
- [ ] Weekly tab defaults to current Mon–Sun week.
- [ ] Monthly tab defaults to current month.
- [ ] Left arrow navigates backward; right arrow is disabled on today's period.
- [ ] Empty period shows `AppEmptyStateWidget`, not an error.
- [ ] Supplier subtotals are sorted alphabetically.
- [ ] Grand total matches sum of supplier subtotals.
- [ ] Deleted transactions do not appear in reports.
- [ ] Deleted lines within a non-deleted transaction are excluded from subtotals.
- [ ] All unit and BLoC tests pass.
