import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetDeletedSuppliers {
  const GetDeletedSuppliers(this._repository);

  final SupplierRepository _repository;

  Future<Either<Failure, List<Supplier>>> call() => _repository.getDeleted();
}
