import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/product_repository.dart';

class SoftDeleteProduct {
  const SoftDeleteProduct(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, Unit>> call(String id) =>
      _repository.softDeleteProduct(id);
}
