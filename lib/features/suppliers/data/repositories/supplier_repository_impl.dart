import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../datasources/supplier_local_data_source.dart';
import '../models/supplier_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  const SupplierRepositoryImpl(this._dataSource);

  final SupplierLocalDataSource _dataSource;

  @override
  Future<Either<Failure, List<Supplier>>> getAll() async {
    try {
      final models = await _dataSource.getAll();
      final suppliers =
          models.where((m) => !m.isDeleted).map((m) => m.toEntity()).toList();
      return Right(suppliers);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Supplier>>> getDeleted() async {
    try {
      final models = await _dataSource.getAll();
      final suppliers =
          models.where((m) => m.isDeleted).map((m) => m.toEntity()).toList();
      return Right(suppliers);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> save(Supplier supplier) async {
    try {
      await _dataSource.save(SupplierModel.fromEntity(supplier));
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> softDelete(String id) async {
    try {
      final model = await _dataSource.getById(id);
      if (model == null) {
        return Left(NotFoundFailure('Supplier not found: $id'));
      }
      final updated = SupplierModel.fromEntity(
        model.toEntity().copyWith(isDeleted: true, updatedAt: DateTime.now()),
      );
      await _dataSource.save(updated);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> restore(String id) async {
    try {
      final model = await _dataSource.getById(id);
      if (model == null) {
        return Left(NotFoundFailure('Supplier not found: $id'));
      }
      final updated = SupplierModel.fromEntity(
        model.toEntity().copyWith(isDeleted: false, updatedAt: DateTime.now()),
      );
      await _dataSource.save(updated);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> permanentDelete(String id) async {
    try {
      await _dataSource.delete(id);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
