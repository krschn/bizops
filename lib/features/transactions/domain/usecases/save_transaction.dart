import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class SaveTransaction {
  const SaveTransaction(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, Unit>> call(Transaction transaction) {
    final activeLines =
        transaction.lines.where((l) => !l.isDeleted).toList();

    if (activeLines.isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('Transaction must have at least one line'),
        ),
      );
    }

    for (final line in activeLines) {
      if (line.quantity <= 0) {
        return Future.value(
          const Left(ValidationFailure('Quantity must be positive')),
        );
      }
      if (line.unitPrice < 0) {
        return Future.value(
          const Left(
            ValidationFailure('Unit price must be non-negative'),
          ),
        );
      }
    }

    return _repository.save(transaction);
  }
}
