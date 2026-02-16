import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/transaction_repository.dart';

class RestoreLine {
  const RestoreLine(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, Unit>> call(String txId, String lineId) =>
      _repository.restoreLine(txId, lineId);
}
