# Plan 05 — Payroll

**Objective:** Employee records + payroll entries organized by weekly/custom periods. Half-day support via `double` days worked. Soft-delete + trash/restore for entries. Employees are deactivated (not deleted).

---

## Dependencies

- Plan 01 complete (core infrastructure, DI, Hive init, shared widgets).

> Plan 05 is independent of Plans 02, 03, and 04. It can be implemented in parallel with Products and Suppliers after Plan 01 is complete.

---

## New Packages

None beyond Plan 01.

---

## Core Utilities

### `lib/core/utils/date_utils.dart`

```dart
/// Returns the Monday of the ISO week containing [date].
DateTime currentWeekStart([DateTime? date]);

/// Returns the Sunday of the ISO week containing [date].
DateTime currentWeekEnd([DateTime? date]);
```

- Pure functions, no side effects.
- Monday is weekday 1, Sunday is weekday 7 (Dart `DateTime.weekday` convention).
- `currentWeekStart` — subtract `(weekday - 1)` days from the date, zero out time.
- `currentWeekEnd` — add `(7 - weekday)` days to the date, set time to 23:59:59.999.
- Both strip time component from the returned value for start; end is end-of-day.
- Unit tested with: mid-week date, Monday, Sunday, and year-boundary dates.

### `lib/core/utils/payroll_utils.dart`

```dart
/// Pure function.
double computeTotalPay(double daysWorked, double dailyRate) =>
    daysWorked * dailyRate;
```

- Unit tested with: whole days, 0.5 half-day, zero days, zero rate.

---

## Domain Layer

### Entities

**File: `lib/features/payroll/domain/entities/employee.dart`**

```
Employee (immutable, equatable)
  id: String
  name: String
  dailyRate: double
  isActive: bool       ← false = deactivated (not deleted); still visible in history
  createdAt: DateTime
  updatedAt: DateTime
```

**File: `lib/features/payroll/domain/entities/payroll_period.dart`**

```
PayrollPeriod (immutable, equatable)
  id: String
  startDate: DateTime   ← date only; time component ignored
  endDate: DateTime     ← date only; time component ignored
  label: String         ← e.g. "Feb 10–16, 2026" or custom label
  isCustom: bool        ← false = auto-generated weekly period
```

**File: `lib/features/payroll/domain/entities/payroll_entry.dart`**

```
PayrollEntry (immutable, equatable)
  id: String
  periodId: String
  employeeId: String
  employeeName: String   ← denormalized snapshot
  dailyRate: double      ← denormalized snapshot (rate at time of entry)
  daysWorked: double     ← supports 0.5 increments; minimum 0.5
  totalPay: double       ← daysWorked * dailyRate; computed and stored
  notes: String          ← optional
  isDeleted: bool
  createdAt: DateTime
  updatedAt: DateTime
```

**Denormalization rule:** `employeeName` and `dailyRate` are copied from the `Employee` record when the entry is created. Rate changes to the employee do not retroactively affect past entries.

### Repository Interfaces

**File: `lib/features/payroll/domain/repositories/employee_repository.dart`**

```
abstract class EmployeeRepository {
  Future<Either<Failure, List<Employee>>> getAll();          // all employees (active + inactive)
  Future<Either<Failure, List<Employee>>> getActive();       // isActive == true only
  Future<Either<Failure, Employee>> getById(String id);
  Future<Either<Failure, Unit>> save(Employee employee);     // create + update
  Future<Either<Failure, Unit>> deactivate(String id);      // sets isActive = false
  Future<Either<Failure, Unit>> reactivate(String id);      // sets isActive = true
}
```

**File: `lib/features/payroll/domain/repositories/payroll_period_repository.dart`**

```
abstract class PayrollPeriodRepository {
  Future<Either<Failure, List<PayrollPeriod>>> getAll();
  Future<Either<Failure, PayrollPeriod?>> findByDateRange(DateTime start, DateTime end);
  Future<Either<Failure, Unit>> save(PayrollPeriod period);
  Future<Either<Failure, Unit>> delete(String id);          // hard delete (no trash for periods)
}
```

**File: `lib/features/payroll/domain/repositories/payroll_entry_repository.dart`**

```
abstract class PayrollEntryRepository {
  Future<Either<Failure, List<PayrollEntry>>> getByPeriod(String periodId);
  Future<Either<Failure, List<PayrollEntry>>> getDeletedByPeriod(String periodId);
  Future<Either<Failure, Unit>> save(PayrollEntry entry);
  Future<Either<Failure, Unit>> softDelete(String id);
  Future<Either<Failure, Unit>> restore(String id);
  Future<Either<Failure, Unit>> permanentDelete(String id);
  Future<Either<Failure, List<PayrollEntry>>> getByPeriodIds(List<String> periodIds); // for export
}
```

### Use Cases

All in `lib/features/payroll/domain/usecases/`.

**Employee use cases:**

| File | Class | Signature |
|---|---|---|
| `get_all_employees.dart` | `GetAllEmployees` | `call() → Future<Either<Failure, List<Employee>>>` |
| `get_active_employees.dart` | `GetActiveEmployees` | `call() → Future<Either<Failure, List<Employee>>>` |
| `save_employee.dart` | `SaveEmployee` | `call(Employee) → Future<Either<Failure, Unit>>` |
| `deactivate_employee.dart` | `DeactivateEmployee` | `call(String id) → Future<Either<Failure, Unit>>` |
| `reactivate_employee.dart` | `ReactivateEmployee` | `call(String id) → Future<Either<Failure, Unit>>` |

**Period use cases:**

| File | Class | Signature |
|---|---|---|
| `get_all_periods.dart` | `GetAllPeriods` | `call() → Future<Either<Failure, List<PayrollPeriod>>>` |
| `save_period.dart` | `SavePeriod` | `call(PayrollPeriod) → Future<Either<Failure, Unit>>` |
| `get_current_week_period.dart` | `GetCurrentWeekPeriod` | `call() → Future<Either<Failure, PayrollPeriod?>>` |

`GetCurrentWeekPeriod` logic:
1. Compute `start = currentWeekStart()`, `end = currentWeekEnd()` using `date_utils.dart`.
2. Call `PayrollPeriodRepository.findByDateRange(start, end)`.
3. Return the found period or `null` if not found. Does **not** create a new period.

**Entry use cases:**

| File | Class | Signature |
|---|---|---|
| `get_entries_by_period.dart` | `GetEntriesByPeriod` | `call(String periodId) → Future<Either<Failure, List<PayrollEntry>>>` |
| `get_deleted_entries_by_period.dart` | `GetDeletedEntriesByPeriod` | `call(String periodId) → Future<Either<Failure, List<PayrollEntry>>>` |
| `save_payroll_entry.dart` | `SavePayrollEntry` | `call(PayrollEntry) → Future<Either<Failure, Unit>>` |
| `soft_delete_entry.dart` | `SoftDeleteEntry` | `call(String id) → Future<Either<Failure, Unit>>` |
| `restore_entry.dart` | `RestoreEntry` | `call(String id) → Future<Either<Failure, Unit>>` |
| `permanent_delete_entry.dart` | `PermanentDeleteEntry` | `call(String id) → Future<Either<Failure, Unit>>` |

**Validation in `SaveEmployee`:**
- `name` must not be empty → `ValidationFailure('Name is required')`.
- `dailyRate` must be > 0 → `ValidationFailure('Daily rate must be positive')`.

**Validation in `SavePayrollEntry`:**
- `daysWorked` must be > 0 → `ValidationFailure('Days worked must be positive')`.
- `daysWorked` must be a multiple of 0.5 → `ValidationFailure('Days worked must be in 0.5 increments')`.
- `employeeId` must not be empty → `ValidationFailure('Employee is required')`.

---

## Data Layer

### Hive Models

**File: `lib/features/payroll/data/models/employee_model.dart`**

```
@HiveType(typeId: 5)
EmployeeModel extends HiveObject
  @HiveField(0) id: String
  @HiveField(1) name: String
  @HiveField(2) dailyRate: double
  @HiveField(3) isActive: bool
  @HiveField(4) createdAt: DateTime
  @HiveField(5) updatedAt: DateTime
```

**File: `lib/features/payroll/data/models/payroll_period_model.dart`**

```
@HiveType(typeId: 6)
PayrollPeriodModel extends HiveObject
  @HiveField(0) id: String
  @HiveField(1) startDate: DateTime
  @HiveField(2) endDate: DateTime
  @HiveField(3) label: String
  @HiveField(4) isCustom: bool
```

**File: `lib/features/payroll/data/models/payroll_entry_model.dart`**

```
@HiveType(typeId: 7)
PayrollEntryModel extends HiveObject
  @HiveField(0)  id: String
  @HiveField(1)  periodId: String
  @HiveField(2)  employeeId: String
  @HiveField(3)  employeeName: String
  @HiveField(4)  dailyRate: double
  @HiveField(5)  daysWorked: double
  @HiveField(6)  totalPay: double
  @HiveField(7)  notes: String
  @HiveField(8)  isDeleted: bool
  @HiveField(9)  createdAt: DateTime
  @HiveField(10) updatedAt: DateTime
```

### Data Sources

Three data sources with corresponding implementations:

- `EmployeeLocalDataSource` / `EmployeeLocalDataSourceImpl` — box: `'employees'`
- `PayrollPeriodLocalDataSource` / `PayrollPeriodLocalDataSourceImpl` — box: `'payroll_periods'`
- `PayrollEntryLocalDataSource` / `PayrollEntryLocalDataSourceImpl` — box: `'payroll_entries'`

Each follows the same pattern: inject `Box<T>`, implement get/save/delete methods, use model id as box key.

`PayrollPeriodLocalDataSource.findByDateRange(start, end)` — filter by `model.startDate == start && model.endDate == end` (date-only comparison; ignore time).

`PayrollEntryLocalDataSource.getByPeriod(periodId)` — filter by `model.periodId == periodId && !model.isDeleted`.

`PayrollEntryLocalDataSource.getDeletedByPeriod(periodId)` — filter by `model.periodId == periodId && model.isDeleted`.

### Repository Implementations

Three implementations following the same error-wrapping pattern as Products/Suppliers.

---

## Presentation Layer

### Three BLoCs

#### `EmployeeBloc`

Files: `lib/features/payroll/presentation/bloc/employee_bloc/`

**Events:**
```
EmployeeEvent (sealed/freezed)
  EmployeesLoaded()
  EmployeeSaveRequested(Employee employee)
  EmployeeDeactivateRequested(String id)
  EmployeeReactivateRequested(String id)
```

**States:**
```
EmployeeState (sealed/freezed)
  initial()
  loading()
  loaded(List<Employee> active, List<Employee> inactive)
  saving()
  saveSuccess()
  error(Failure failure)
```

**Logic:**
- `on<EmployeesLoaded>` → call `GetAllEmployees`, split by `isActive`, emit `loaded(active, inactive)`.
- `on<EmployeeSaveRequested>` → `saving()`, call `SaveEmployee`, `saveSuccess()` or `error`.
- `on<EmployeeDeactivateRequested>` → call `DeactivateEmployee`, re-add `EmployeesLoaded()`.
- `on<EmployeeReactivateRequested>` → call `ReactivateEmployee`, re-add `EmployeesLoaded()`.

#### `PayrollPeriodBloc`

Files: `lib/features/payroll/presentation/bloc/payroll_period_bloc/`

**Events:**
```
PayrollPeriodEvent (sealed/freezed)
  PayrollPeriodsLoaded()
  CurrentWeekPeriodRequested()
  NewWeekPeriodCreated()       ← user taps "New Week" button
  CustomPeriodCreated(DateTime start, DateTime end, String label)
  PayrollPeriodSelected(String periodId)
  PayrollPeriodDeleted(String id)
```

**States:**
```
PayrollPeriodState (sealed/freezed)
  initial()
  loading()
  loaded(List<PayrollPeriod> periods, String? selectedPeriodId)
  error(Failure failure)
```

**Logic:**
- `on<PayrollPeriodsLoaded>` → load all periods; also call `GetCurrentWeekPeriod` to find if current week exists; emit `loaded(periods, currentWeekPeriodId)`.
- `on<NewWeekPeriodCreated>`:
  1. Compute Mon–Sun for today.
  2. Call `GetCurrentWeekPeriod` — if found, select that period (no duplicate).
  3. If not found, create a new `PayrollPeriod` with `isCustom: false`, auto-generated label (e.g. "Feb 10–16, 2026"), call `SavePeriod`, reload.
- `on<CustomPeriodCreated>` → create period with `isCustom: true`, save, reload.
- `on<PayrollPeriodSelected>` → re-emit `loaded` with updated `selectedPeriodId`.
- `on<PayrollPeriodDeleted>` → hard-delete period, reload.

#### `PayrollEntryBloc`

Files: `lib/features/payroll/presentation/bloc/payroll_entry_bloc/`

**Events:**
```
PayrollEntryEvent (sealed/freezed)
  PayrollEntriesLoaded(String periodId)
  PayrollEntriesTrashLoaded(String periodId)
  PayrollEntrySaveRequested(PayrollEntry entry)
  PayrollEntryDeleteRequested(String id, String periodId)
  PayrollEntryRestoreRequested(String id, String periodId)
  PayrollEntryPermanentDeleteRequested(String id, String periodId)
```

**States:**
```
PayrollEntryState (sealed/freezed)
  initial()
  loading()
  loaded(List<PayrollEntry> entries, double periodTotal)
  trashLoaded(List<PayrollEntry> entries)
  saving()
  saveSuccess()
  error(Failure failure)
```

`periodTotal` = sum of `totalPay` for all non-deleted entries in the period.

**Logic:** Mirrors Products pattern. `on<PayrollEntriesLoaded>` → load entries for `periodId`, compute `periodTotal`, emit `loaded`.

### Pages

**`lib/features/payroll/presentation/pages/payroll_main_page.dart`**

- Main payroll screen.
- Two tabs: **Entries** and **Trash**.
- Shows `PeriodSelectorWidget` at the top (period chips from `PayrollPeriodBloc`).
- "New Week" button → dispatches `NewWeekPeriodCreated`.
- "Custom Period" button → opens date-range picker dialog, dispatches `CustomPeriodCreated`.
- Entry list: `BlocBuilder<PayrollEntryBloc, PayrollEntryState>` on `loaded` → `ListView` of `PayrollEntryTile`.
- `PayrollPeriodTotalBar` at bottom showing period total.
- FAB: navigates to `/payroll/entry/new` (passing `selectedPeriodId`).
- AppBar actions: export button (Plan 07).

**`lib/features/payroll/presentation/pages/employee_list_page.dart`**

- Shows two sections: **Active** and **Inactive**.
- Uses `BlocBuilder<EmployeeBloc, EmployeeState>` on `loaded(active, inactive)`.
- Active section: `ListView` of `EmployeeListTile` with deactivate action.
- Inactive section: same tiles with reactivate action.
- FAB: navigates to `/payroll/employees/new`.

**`lib/features/payroll/presentation/pages/employee_form_page.dart`**

- Receives optional `employeeId`.
- Fields: Name (`TextFormField`), Daily Rate (`TextFormField`, numeric).
- Uses `LabeledField` for each.
- `PrimaryButton` for save.
- On `saveSuccess`: `context.pop()`.

**`lib/features/payroll/presentation/pages/payroll_entry_form_page.dart`**

- Receives `periodId` (required) and optional `entryId`.
- Employee picker: dropdown of active employees (from `GetActiveEmployees`).
- Days Worked: numeric field, hint "e.g. 1.0 or 0.5".
- Computed Total Pay: read-only display, updated reactively as employee/days change.
- Notes: optional `TextFormField`.
- On employee select: snapshot `employeeName` and `dailyRate`.
- On `saveSuccess`: `context.pop()`.

### Widgets

**`PeriodSelectorWidget`**
- Horizontal scrollable row of `ChoiceChip` widgets, one per period.
- Selected period highlighted. Tapping dispatches `PayrollPeriodSelected`.

**`PayrollEntryTile`**
```
PayrollEntryTile({ required PayrollEntry entry, required VoidCallback onDelete, required VoidCallback onEdit })
```
- Shows: employee name, days worked, total pay.

**`PayrollTrashTile`**
```
PayrollTrashTile({ required PayrollEntry entry, required VoidCallback onRestore, required VoidCallback onPermanentDelete })
```
- Muted styling, restore + permanent delete actions.

**`PayrollPeriodTotalBar`**
```
PayrollPeriodTotalBar({ required double total, required String periodLabel })
```
- Fixed bar at bottom showing period label and total.

**`EmployeeListTile`**
```
EmployeeListTile({ required Employee employee, required VoidCallback onAction })
```
- Shows name + daily rate. Action is "Deactivate" or "Reactivate" based on `isActive`.

---

## Dependency Injection

Three Hive box modules:
```dart
@module
abstract class PayrollModule {
  @lazySingleton
  Box<EmployeeModel> get employeeBox => Hive.box<EmployeeModel>(HiveBoxNames.employees);

  @lazySingleton
  Box<PayrollPeriodModel> get periodBox => Hive.box<PayrollPeriodModel>(HiveBoxNames.payrollPeriods);

  @lazySingleton
  Box<PayrollEntryModel> get entryBox => Hive.box<PayrollEntryModel>(HiveBoxNames.payrollEntries);
}
```

All data sources, repositories, use cases: `@injectable` or `@LazySingleton(as: ...)`.

All three BLoCs: `@injectable` (transient).

---

## Files to Create

```
lib/core/utils/date_utils.dart
lib/core/utils/payroll_utils.dart
lib/features/payroll/domain/entities/employee.dart
lib/features/payroll/domain/entities/payroll_period.dart
lib/features/payroll/domain/entities/payroll_entry.dart
lib/features/payroll/domain/repositories/employee_repository.dart
lib/features/payroll/domain/repositories/payroll_period_repository.dart
lib/features/payroll/domain/repositories/payroll_entry_repository.dart
lib/features/payroll/domain/usecases/get_all_employees.dart
lib/features/payroll/domain/usecases/get_active_employees.dart
lib/features/payroll/domain/usecases/save_employee.dart
lib/features/payroll/domain/usecases/deactivate_employee.dart
lib/features/payroll/domain/usecases/reactivate_employee.dart
lib/features/payroll/domain/usecases/get_all_periods.dart
lib/features/payroll/domain/usecases/save_period.dart
lib/features/payroll/domain/usecases/get_current_week_period.dart
lib/features/payroll/domain/usecases/get_entries_by_period.dart
lib/features/payroll/domain/usecases/get_deleted_entries_by_period.dart
lib/features/payroll/domain/usecases/save_payroll_entry.dart
lib/features/payroll/domain/usecases/soft_delete_entry.dart
lib/features/payroll/domain/usecases/restore_entry.dart
lib/features/payroll/domain/usecases/permanent_delete_entry.dart
lib/features/payroll/data/models/employee_model.dart
lib/features/payroll/data/models/employee_model.g.dart              ← generated
lib/features/payroll/data/models/payroll_period_model.dart
lib/features/payroll/data/models/payroll_period_model.g.dart        ← generated
lib/features/payroll/data/models/payroll_entry_model.dart
lib/features/payroll/data/models/payroll_entry_model.g.dart         ← generated
lib/features/payroll/data/datasources/employee_local_data_source.dart
lib/features/payroll/data/datasources/payroll_period_local_data_source.dart
lib/features/payroll/data/datasources/payroll_entry_local_data_source.dart
lib/features/payroll/data/repositories/employee_repository_impl.dart
lib/features/payroll/data/repositories/payroll_period_repository_impl.dart
lib/features/payroll/data/repositories/payroll_entry_repository_impl.dart
lib/features/payroll/presentation/bloc/employee_bloc/employee_event.dart
lib/features/payroll/presentation/bloc/employee_bloc/employee_state.dart
lib/features/payroll/presentation/bloc/employee_bloc/employee_bloc.dart
lib/features/payroll/presentation/bloc/payroll_period_bloc/payroll_period_event.dart
lib/features/payroll/presentation/bloc/payroll_period_bloc/payroll_period_state.dart
lib/features/payroll/presentation/bloc/payroll_period_bloc/payroll_period_bloc.dart
lib/features/payroll/presentation/bloc/payroll_entry_bloc/payroll_entry_event.dart
lib/features/payroll/presentation/bloc/payroll_entry_bloc/payroll_entry_state.dart
lib/features/payroll/presentation/bloc/payroll_entry_bloc/payroll_entry_bloc.dart
lib/features/payroll/presentation/pages/payroll_main_page.dart
lib/features/payroll/presentation/pages/employee_list_page.dart
lib/features/payroll/presentation/pages/employee_form_page.dart
lib/features/payroll/presentation/pages/payroll_entry_form_page.dart
lib/features/payroll/presentation/widgets/period_selector_widget.dart
lib/features/payroll/presentation/widgets/payroll_entry_tile.dart
lib/features/payroll/presentation/widgets/payroll_trash_tile.dart
lib/features/payroll/presentation/widgets/payroll_period_total_bar.dart
lib/features/payroll/presentation/widgets/employee_list_tile.dart
test/core/utils/date_utils_test.dart
test/core/utils/payroll_utils_test.dart
test/features/payroll/domain/usecases/save_employee_test.dart
test/features/payroll/domain/usecases/save_payroll_entry_test.dart
test/features/payroll/domain/usecases/get_current_week_period_test.dart
test/features/payroll/presentation/bloc/employee_bloc_test.dart
test/features/payroll/presentation/bloc/payroll_entry_bloc_test.dart
```

---

## Test Coverage

### `date_utils_test.dart`
- Mid-week Wednesday → correct Mon start, Sun end.
- Monday input → start is same day.
- Sunday input → end is same day.
- Year-boundary date (e.g. Dec 31) → correctly wraps to Jan.

### `payroll_utils_test.dart`
- `computeTotalPay(5, 600)` → `3000.0`.
- `computeTotalPay(0.5, 600)` → `300.0`.
- `computeTotalPay(0, 600)` → `0.0`.

### `SaveEmployeeTest`
- Valid → delegates to repository.
- Empty name → `ValidationFailure`.
- Zero rate → `ValidationFailure`.
- Negative rate → `ValidationFailure`.

### `SavePayrollEntryTest`
- Valid (1.0 day) → delegates.
- Valid (0.5 day) → delegates.
- `daysWorked = 0` → `ValidationFailure`.
- `daysWorked = 0.3` (not multiple of 0.5) → `ValidationFailure`.
- Empty `employeeId` → `ValidationFailure`.

### `GetCurrentWeekPeriodTest`
- Period exists → returns it.
- No period → returns `Right(null)`.

### BLoC Tests
- `EmployeesLoaded` → splits employees into active/inactive lists.
- `NewWeekPeriodCreated` (period already exists) → selects existing, no duplicate saved.
- `NewWeekPeriodCreated` (no existing period) → creates and saves new period.
- `PayrollEntriesLoaded` → emits `loaded` with correct `periodTotal`.

---

## Verification Checklist

- [ ] `build_runner` generates all 3 `_model.g.dart` files without errors.
- [ ] Employee list shows Active and Inactive sections correctly.
- [ ] Deactivating an employee moves them to Inactive section; they no longer appear in entry form picker.
- [ ] "New Week" creates a Mon–Sun period with correct label; pressing again selects the same period (no duplicate).
- [ ] Custom period creation works with arbitrary start/end dates.
- [ ] Payroll entry with 0.5 days saves correctly; `totalPay` = `dailyRate * 0.5`.
- [ ] Entering 0.3 days shows validation error.
- [ ] Soft-deleting an entry moves it to Trash tab.
- [ ] Period total bar shows sum of active entries for selected period.
- [ ] All unit and BLoC tests pass.
