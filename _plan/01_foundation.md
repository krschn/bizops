# Plan 01 — Foundation

**Objective:** Bootstrap the entire app infrastructure. Every other plan depends on this.

---

## Dependencies

None — this is the base layer.

---

## New Packages

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_bloc: ^9.1.1
  bloc: ^9.2.0
  get_it: ^9.2.0
  dartz: ^0.10.1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  go_router: ^14.0.0
  equatable: ^2.0.5

dev_dependencies:
  mocktail: ^1.0.4
  flutter_test:
    sdk: flutter
  bloc_test: ^10.0.0
```

No code generation packages. All code is handwritten.

---

## Error Model

File: `lib/core/error/failures.dart`

Plain Dart 3 sealed class hierarchy — no `@freezed`, no `part` directive, no generated files:

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
```

- Dart 3 sealed class gives exhaustive `switch` pattern matching.
- No `==` / `hashCode` needed on failures (compared by type in tests).

---

## Hive Initializer

File: `lib/core/storage/hive_initializer.dart`

```
Future<void> initHive() async
```

- Calls `await Hive.initFlutter()`.
- Registers all 7 handwritten TypeAdapters:
  - `ProductModelAdapter()` — typeId 1
  - `SupplierModelAdapter()` — typeId 2
  - `TransactionLineModelAdapter()` — typeId 3
  - `TransactionModelAdapter()` — typeId 4
  - `EmployeeModelAdapter()` — typeId 5
  - `PayrollPeriodModelAdapter()` — typeId 6
  - `PayrollEntryModelAdapter()` — typeId 7
- Opens all boxes by name (see box names below).
- Returns `Future<void>` — called before DI setup in `main.dart`.

**Note:** Each adapter is only registered if not already registered (use `Hive.isAdapterRegistered(typeId)` guard).

### Handwritten TypeAdapter pattern

Each model file contains its own adapter class. Example for `ProductModel`:

```dart
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

**Critical:** Field write order in `write()` must exactly match field read order in `read()`. No `@HiveType`/`@HiveField` annotations needed.

---

## Hive Box Names

File: `lib/core/storage/hive_box_names.dart`

```dart
abstract class HiveBoxNames {
  static const String products = 'products';
  static const String suppliers = 'suppliers';
  static const String transactions = 'transactions';
  static const String employees = 'employees';
  static const String payrollPeriods = 'payroll_periods';
  static const String payrollEntries = 'payroll_entries';
}
```

---

## Dependency Injection

File: `lib/core/di/injection.dart`

Manual `GetIt` registration — no `injectable` package, no annotations, no generated config:

```dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Registrations added here as features are built (Plans 02–07).
  // Example pattern:
  //   getIt.registerLazySingleton<ProductRepository>(
  //     () => ProductRepositoryImpl(getIt()),
  //   );
}
```

Each feature's dependencies are registered directly in this function (or in feature-specific registration functions called from here).

---

## Theme

### `lib/core/theme/app_colors.dart`

All values are `Color` constants. No platform branching. No color value may be used in UI code directly — always reference these tokens.

```
abstract class AppColors {
  // Backgrounds
  static const background     = Color(0xFFFFFFFF); // scaffold, page backgrounds
  static const surface        = Color(0xFFF8F8FA); // cards, inputs, bottom nav
  static const surfaceVariant = Color(0xFFF0F0F5); // dividers, inactive areas

  // Navy Blue — primary accent
  static const primary        = Color(0xFF1B2A4A); // buttons, active nav, links
  static const primaryLight   = Color(0xFF2E4270); // pressed states on navy
  static const primaryMuted   = Color(0xFFE8EBF2); // chip selected bg, highlights

  // Text
  static const textPrimary    = Color(0xFF0D0D0D); // headings, body
  static const textSecondary  = Color(0xFF6B7280); // subtitles, hints
  static const textDisabled   = Color(0xFFB0B7C3); // disabled, placeholders
  static const textOnPrimary  = Color(0xFFFFFFFF); // text on navy backgrounds

  // Borders & Dividers
  static const divider        = Color(0xFFE5E7EB); // list dividers, card outlines
  static const border         = Color(0xFFD1D5DB); // input borders

  // Semantic
  static const error          = Color(0xFFC0392B);
  static const errorSurface   = Color(0xFFFDEDED);
  static const success        = Color(0xFF1A7A4A);
  static const warning        = Color(0xFFB45309);

  // Trash / soft-delete
  static const trashAccent    = Color(0xFF9CA3AF);
}
```

### `lib/core/theme/app_theme.dart`

```
abstract class AppTheme
  static ThemeData light()  — returns configured ThemeData
```

- Uses `AppColors` for all color slots.
- Configures `ColorScheme`, `AppBarTheme`, `BottomNavigationBarTheme`, `InputDecorationTheme`, `TextTheme`, `ElevatedButtonThemeData`, `CardTheme`.
- No dark theme required in this plan.

---

## Routing

File: `lib/core/routing/app_router.dart`

Uses `GoRouter`. Define a `AppRouter` class (or top-level constant) exposing `RouterConfig<Object?>`.

Routes:

| Path | Page |
|---|---|
| `/` | `AppShellPage` (shell route with bottom nav) |
| `/transactions` | `TransactionListPage` |
| `/transactions/new` | `TransactionFormPage` |
| `/transactions/:id` | `TransactionFormPage` (edit) |
| `/products` | `ProductListPage` |
| `/products/new` | `ProductFormPage` |
| `/products/:id` | `ProductFormPage` (edit) |
| `/suppliers` | `SupplierListPage` |
| `/suppliers/new` | `SupplierFormPage` |
| `/suppliers/:id` | `SupplierFormPage` (edit) |
| `/payroll` | `PayrollMainPage` |
| `/payroll/employees` | `EmployeeListPage` |
| `/payroll/employees/new` | `EmployeeFormPage` |
| `/payroll/employees/:id` | `EmployeeFormPage` (edit) |
| `/payroll/entry/new` | `PayrollEntryFormPage` |
| `/payroll/entry/:id` | `PayrollEntryFormPage` (edit) |
| `/reports` | `ReportPage` |

- Shell route wraps all top-level routes with `AppShellPage`.
- Use `StatefulShellRoute` for bottom-nav state preservation.

---

## Shell / Navigation

File: `lib/features/shell/presentation/pages/app_shell_page.dart`

`AppShellPage` — `StatefulWidget` wrapping a `Scaffold` with a `BottomNavigationBar`.

Tabs (in order):
1. Transactions (icon: `receipt_long`)
2. Products (icon: `inventory_2`)
3. Suppliers (icon: `store`)
4. Payroll (icon: `payments`)
5. Reports (icon: `bar_chart`)

- Tapping a tab calls `context.go(...)` with the corresponding route.
- Active tab is derived from current `GoRouter` location — no local index state.
- `body` renders the routed child page.

---

## Shared Widgets

All in `lib/shared/widgets/`. No feature-specific logic in any widget.

### `app_error_widget.dart`
```
AppErrorWidget({ required String message, VoidCallback? onRetry })
```
- Shows error icon, message text, and an optional "Retry" button.

### `app_loading_widget.dart`
```
AppLoadingWidget()
```
- Centered `CircularProgressIndicator`.

### `app_empty_state_widget.dart`
```
AppEmptyStateWidget({ required String message, Widget? action })
```
- Centered icon + message + optional action widget.

### `confirm_delete_dialog.dart`
```
ConfirmDeleteDialog({ required String title, required String message })
  → static Future<bool?> show(BuildContext context, {required String title, required String message})
```
- `AlertDialog` with Cancel and Delete (destructive color) buttons.
- Returns `true` on confirm, `false`/`null` on dismiss.

### `primary_button.dart`
```
PrimaryButton({ required String label, required VoidCallback? onPressed, bool isLoading = false })
```
- `ElevatedButton` styled via theme.
- Shows `CircularProgressIndicator` when `isLoading` is true; disables `onPressed`.

### `labeled_field.dart`
```
LabeledField({ required String label, required Widget child })
```
- Wraps any widget with a `Text` label above it.
- Used to wrap `TextFormField`, dropdowns, etc. for consistent spacing.

---

## Bootstrap Sequence

`lib/main.dart`:

```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();           // registers adapters, opens boxes
  await configureDependencies();  // wires GetIt
  runApp(BizOpsApp());
}
```

`BizOpsApp` — `StatelessWidget` returning `MaterialApp.router` with:
- `routerConfig: AppRouter.config`
- `theme: AppTheme.light()`
- `title: 'BizOps'`

---

## Files to Create

```
lib/main.dart
lib/core/di/injection.dart
lib/core/error/failures.dart
lib/core/storage/hive_initializer.dart
lib/core/storage/hive_box_names.dart
lib/core/theme/app_theme.dart
lib/core/theme/app_colors.dart
lib/core/routing/app_router.dart
lib/features/shell/presentation/pages/app_shell_page.dart
lib/shared/widgets/app_error_widget.dart
lib/shared/widgets/app_loading_widget.dart
lib/shared/widgets/app_empty_state_widget.dart
lib/shared/widgets/confirm_delete_dialog.dart
lib/shared/widgets/primary_button.dart
lib/shared/widgets/labeled_field.dart
test/core/error/failures_test.dart
```

---

## Test Coverage

`test/core/error/failures_test.dart`:
- Verify each `Failure` variant constructs correctly.
- Verify `message` field is accessible on each variant.
- Verify Dart 3 sealed class exhaustive switch compiles (type-checking test).

---

## Verification Checklist

- [ ] `flutter pub get` succeeds after package additions.
- [ ] `flutter analyze` — zero errors.
- [ ] App launches with bottom nav showing 5 tabs.
- [ ] Navigating each tab routes without errors.
- [ ] All shared widgets render without overflow in isolation.
