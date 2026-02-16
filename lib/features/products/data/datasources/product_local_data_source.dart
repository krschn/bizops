import 'package:hive/hive.dart';

import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getAll();
  Future<void> save(ProductModel model);
  Future<ProductModel?> getById(String id);
  Future<void> delete(String id);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  const ProductLocalDataSourceImpl(this._box);

  final Box<ProductModel> _box;

  @override
  Future<List<ProductModel>> getAll() async => _box.values.toList();

  @override
  Future<void> save(ProductModel model) async => _box.put(model.id, model);

  @override
  Future<ProductModel?> getById(String id) async => _box.get(id);

  @override
  Future<void> delete(String id) async => _box.delete(id);
}
