import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/supplier.dart';

abstract class SupplierRepository {
  Future<Either<Failure, List<Supplier>>> getAll();
  Future<Either<Failure, List<Supplier>>> getDeleted();
  Future<Either<Failure, Unit>> save(Supplier supplier);
  Future<Either<Failure, Unit>> softDelete(String id);
  Future<Either<Failure, Unit>> restore(String id);
  Future<Either<Failure, Unit>> permanentDelete(String id);
}
