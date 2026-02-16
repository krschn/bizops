import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/transaction_repository.dart';

class RestoreTransaction {
  const RestoreTransaction(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, Unit>> call(String id) =>
      _repository.restoreTransaction(id);
}
