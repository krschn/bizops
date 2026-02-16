import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionById {
  const GetTransactionById(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, Transaction>> call(String id) =>
      _repository.getById(id);
}
