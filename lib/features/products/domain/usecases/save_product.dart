import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class SaveProduct {
  const SaveProduct(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, Unit>> call(Product product) {
    if (product.name.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Name is required')));
    }
    if (product.price < 0) {
      return Future.value(
        const Left(ValidationFailure('Price must be non-negative')),
      );
    }
    if (product.unit.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Unit is required')));
    }
    return _repository.saveProduct(product);
  }
}
