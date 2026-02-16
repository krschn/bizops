import 'package:hive/hive.dart';

import '../models/supplier_model.dart';

abstract class SupplierLocalDataSource {
  Future<List<SupplierModel>> getAll();
  Future<void> save(SupplierModel model);
  Future<SupplierModel?> getById(String id);
  Future<void> delete(String id);
}

class SupplierLocalDataSourceImpl implements SupplierLocalDataSource {
  const SupplierLocalDataSourceImpl(this._box);

  final Box<SupplierModel> _box;

  @override
  Future<List<SupplierModel>> getAll() async => _box.values.toList();

  @override
  Future<void> save(SupplierModel model) async => _box.put(model.id, model);

  @override
  Future<SupplierModel?> getById(String id) async => _box.get(id);

  @override
  Future<void> delete(String id) async => _box.delete(id);
}
