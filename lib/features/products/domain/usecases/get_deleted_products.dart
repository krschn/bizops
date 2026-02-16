import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetDeletedProducts {
  const GetDeletedProducts(this._repository);

  final ProductRepository _repository;

  Future<Either<Failure, List<Product>>> call() => _repository.getDeletedProducts();
}
