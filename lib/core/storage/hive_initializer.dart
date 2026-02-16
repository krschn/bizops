import 'package:hive_flutter/hive_flutter.dart';

import '../../features/products/data/models/product_model.dart';
import '../../features/suppliers/data/models/supplier_model.dart';
import 'hive_box_names.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  _registerAdapters();
  await _openBoxes();
}

void _registerAdapters() {
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(SupplierModelAdapter());
  // Plan 04: Hive.registerAdapter(EmployeeModelAdapter())
  // Plan 04: Hive.registerAdapter(PayrollEntryModelAdapter())
}

Future<void> _openBoxes() async {
  await Hive.openBox(HiveBoxNames.transactions);
  await Hive.openBox<ProductModel>(HiveBoxNames.products);
  await Hive.openBox<SupplierModel>(HiveBoxNames.suppliers);
  await Hive.openBox(HiveBoxNames.employees);
  await Hive.openBox(HiveBoxNames.payrollEntries);
  await Hive.openBox(HiveBoxNames.settings);
}
