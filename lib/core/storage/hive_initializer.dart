import 'package:hive_flutter/hive_flutter.dart';

import 'hive_box_names.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  _registerAdapters();
  await _openBoxes();
}

void _registerAdapters() {
  // Plan 02: Hive.registerAdapter(TransactionModelAdapter())
  // Plan 03: Hive.registerAdapter(ProductModelAdapter())
  // Plan 04: Hive.registerAdapter(SupplierModelAdapter())
  // Plan 05: Hive.registerAdapter(EmployeeModelAdapter())
  // Plan 05: Hive.registerAdapter(PayrollEntryModelAdapter())
}

Future<void> _openBoxes() async {
  await Hive.openBox(HiveBoxNames.transactions);
  await Hive.openBox(HiveBoxNames.products);
  await Hive.openBox(HiveBoxNames.suppliers);
  await Hive.openBox(HiveBoxNames.employees);
  await Hive.openBox(HiveBoxNames.payrollEntries);
  await Hive.openBox(HiveBoxNames.settings);
}
