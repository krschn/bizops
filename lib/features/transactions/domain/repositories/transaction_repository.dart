import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getAll();
  Future<Either<Failure, List<Transaction>>> getDeleted();
  Future<Either<Failure, Transaction>> getById(String id);
  Future<Either<Failure, Unit>> save(Transaction transaction);
  Future<Either<Failure, Unit>> softDeleteTransaction(String id);
  Future<Either<Failure, Unit>> restoreTransaction(String id);
  Future<Either<Failure, Unit>> permanentDeleteTransaction(String id);
  Future<Either<Failure, Unit>> softDeleteLine(String txId, String lineId);
  Future<Either<Failure, Unit>> restoreLine(String txId, String lineId);
  Future<Either<Failure, List<Transaction>>> getByDateRange(
    DateTime from,
    DateTime to,
  );
}
