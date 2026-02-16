import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionsByDateRange {
  const GetTransactionsByDateRange(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, List<Transaction>>> call(
    DateTime from,
    DateTime to,
  ) =>
      _repository.getByDateRange(from, to);
}
