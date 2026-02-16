import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/transaction_repository.dart';

class SoftDeleteLine {
  const SoftDeleteLine(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, Unit>> call(String txId, String lineId) =>
      _repository.softDeleteLine(txId, lineId);
}
