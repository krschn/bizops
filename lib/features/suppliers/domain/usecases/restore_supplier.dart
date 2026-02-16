import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/supplier_repository.dart';

class RestoreSupplier {
  const RestoreSupplier(this._repository);

  final SupplierRepository _repository;

  Future<Either<Failure, Unit>> call(String id) => _repository.restore(id);
}
