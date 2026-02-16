import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._dataSource);

  final ProductLocalDataSource _dataSource;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final models = await _dataSource.getAll();
      final products =
          models.where((m) => !m.isDeleted).map((m) => m.toEntity()).toList();
      return Right(products);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getDeletedProducts() async {
    try {
      final models = await _dataSource.getAll();
      final products =
          models.where((m) => m.isDeleted).map((m) => m.toEntity()).toList();
      return Right(products);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveProduct(Product product) async {
    try {
      await _dataSource.save(ProductModel.fromEntity(product));
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> softDeleteProduct(String id) async {
    try {
      final model = await _dataSource.getById(id);
      if (model == null) {
        return Left(NotFoundFailure('Product not found: $id'));
      }
      final updated = ProductModel.fromEntity(
        model.toEntity().copyWith(isDeleted: true, updatedAt: DateTime.now()),
      );
      await _dataSource.save(updated);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> restoreProduct(String id) async {
    try {
      final model = await _dataSource.getById(id);
      if (model == null) {
        return Left(NotFoundFailure('Product not found: $id'));
      }
      final updated = ProductModel.fromEntity(
        model.toEntity().copyWith(isDeleted: false, updatedAt: DateTime.now()),
      );
      await _dataSource.save(updated);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> permanentDeleteProduct(String id) async {
    try {
      await _dataSource.delete(id);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
