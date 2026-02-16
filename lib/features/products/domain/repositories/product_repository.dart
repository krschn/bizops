import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, List<Product>>> getDeletedProducts();
  Future<Either<Failure, Unit>> saveProduct(Product product);
  Future<Either<Failure, Unit>> softDeleteProduct(String id);
  Future<Either<Failure, Unit>> restoreProduct(String id);
  Future<Either<Failure, Unit>> permanentDeleteProduct(String id);
}
