import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetSuppliers {
  const GetSuppliers(this._repository);

  final SupplierRepository _repository;

  Future<Either<Failure, List<Supplier>>> call() => _repository.getAll();
}
