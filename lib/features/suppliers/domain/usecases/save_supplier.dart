import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class SaveSupplier {
  const SaveSupplier(this._repository);

  final SupplierRepository _repository;

  Future<Either<Failure, Unit>> call(Supplier supplier) {
    if (supplier.name.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Name is required')),
      );
    }
    return _repository.save(supplier);
  }
}
