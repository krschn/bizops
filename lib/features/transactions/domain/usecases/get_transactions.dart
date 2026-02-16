import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class GetTransactions {
  const GetTransactions(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, List<Transaction>>> call() => _repository.getAll();
}
