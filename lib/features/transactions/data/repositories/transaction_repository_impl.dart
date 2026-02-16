import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/transaction_utils.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_local_data_source.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._dataSource);

  final TransactionLocalDataSource _dataSource;

  @override
  Future<Either<Failure, List<Transaction>>> getAll() async {
    try {
      final models = await _dataSource.getAll();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getDeleted() async {
    try {
      final models = await _dataSource.getDeleted();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> getById(String id) async {
    try {
      final model = await _dataSource.getById(id);
      if (model == null) {
        return Left(NotFoundFailure('Transaction not found: $id'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> save(Transaction transaction) async {
    try {
      await _dataSource.save(TransactionModel.fromEntity(transaction));
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> softDeleteTransaction(String id) async {
    try {
      final model = await _dataSource.getById(id);
      if (model == null) {
        return Left(NotFoundFailure('Transaction not found: $id'));
      }
      final updated = TransactionModel.fromEntity(
        model.toEntity().copyWith(
              isDeleted: true,
              updatedAt: DateTime.now(),
            ),
      );
      await _dataSource.save(updated);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> restoreTransaction(String id) async {
    try {
      final model = await _dataSource.getById(id);
      if (model == null) {
        return Left(NotFoundFailure('Transaction not found: $id'));
      }
      final updated = TransactionModel.fromEntity(
        model.toEntity().copyWith(
              isDeleted: false,
              updatedAt: DateTime.now(),
            ),
      );
      await _dataSource.save(updated);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> permanentDeleteTransaction(String id) async {
    try {
      await _dataSource.deleteById(id);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> softDeleteLine(
    String txId,
    String lineId,
  ) async {
    try {
      final model = await _dataSource.getById(txId);
      if (model == null) {
        return Left(NotFoundFailure('Transaction not found: $txId'));
      }
      final tx = model.toEntity();
      final updatedLines = tx.lines.map((l) {
        if (l.id == lineId) return l.copyWith(isDeleted: true);
        return l;
      }).toList();
      final newTotal = computeGrandTotal(updatedLines);
      final updated = TransactionModel.fromEntity(
        tx.copyWith(
          lines: updatedLines,
          grandTotal: newTotal,
          updatedAt: DateTime.now(),
        ),
      );
      await _dataSource.save(updated);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> restoreLine(
    String txId,
    String lineId,
  ) async {
    try {
      final model = await _dataSource.getById(txId);
      if (model == null) {
        return Left(NotFoundFailure('Transaction not found: $txId'));
      }
      final tx = model.toEntity();
      final updatedLines = tx.lines.map((l) {
        if (l.id == lineId) return l.copyWith(isDeleted: false);
        return l;
      }).toList();
      final newTotal = computeGrandTotal(updatedLines);
      final updated = TransactionModel.fromEntity(
        tx.copyWith(
          lines: updatedLines,
          grandTotal: newTotal,
          updatedAt: DateTime.now(),
        ),
      );
      await _dataSource.save(updated);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final models = await _dataSource.getByDateRange(from, to);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(StorageFailure(e.toString()));
    }
  }
}
