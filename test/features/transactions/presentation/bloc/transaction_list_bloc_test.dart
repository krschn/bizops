import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/transactions/domain/entities/transaction.dart';
import 'package:bizops/features/transactions/domain/usecases/get_deleted_transactions.dart';
import 'package:bizops/features/transactions/domain/usecases/get_transactions.dart';
import 'package:bizops/features/transactions/domain/usecases/permanent_delete_transaction.dart';
import 'package:bizops/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:bizops/features/transactions/domain/usecases/soft_delete_transaction.dart';
import 'package:bizops/features/transactions/presentation/bloc/transaction_list_bloc/transaction_list_bloc.dart';
import 'package:bizops/features/transactions/presentation/bloc/transaction_list_bloc/transaction_list_event.dart';
import 'package:bizops/features/transactions/presentation/bloc/transaction_list_bloc/transaction_list_state.dart';

class MockGetTransactions extends Mock implements GetTransactions {}

class MockGetDeletedTransactions extends Mock
    implements GetDeletedTransactions {}

class MockSoftDeleteTransaction extends Mock implements SoftDeleteTransaction {}

class MockRestoreTransaction extends Mock implements RestoreTransaction {}

class MockPermanentDeleteTransaction extends Mock
    implements PermanentDeleteTransaction {}

Transaction _tx({String id = 'tx1'}) {
  final now = DateTime(2025);
  return Transaction(
    id: id,
    transactedAt: now,
    lines: const [],
    grandTotal: 0,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );
}

TransactionListBloc _makeBloc({
  required MockGetTransactions getTransactions,
  required MockGetDeletedTransactions getDeletedTransactions,
  required MockSoftDeleteTransaction softDeleteTransaction,
  required MockRestoreTransaction restoreTransaction,
  required MockPermanentDeleteTransaction permanentDeleteTransaction,
}) =>
    TransactionListBloc(
      getTransactions: getTransactions,
      getDeletedTransactions: getDeletedTransactions,
      softDeleteTransaction: softDeleteTransaction,
      restoreTransaction: restoreTransaction,
      permanentDeleteTransaction: permanentDeleteTransaction,
    );

void main() {
  late MockGetTransactions getTransactions;
  late MockGetDeletedTransactions getDeletedTransactions;
  late MockSoftDeleteTransaction softDeleteTransaction;
  late MockRestoreTransaction restoreTransaction;
  late MockPermanentDeleteTransaction permanentDeleteTransaction;

  setUp(() {
    getTransactions = MockGetTransactions();
    getDeletedTransactions = MockGetDeletedTransactions();
    softDeleteTransaction = MockSoftDeleteTransaction();
    restoreTransaction = MockRestoreTransaction();
    permanentDeleteTransaction = MockPermanentDeleteTransaction();
  });

  group('TransactionsLoaded', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => getTransactions())
            .thenAnswer((_) async => Right([_tx()]));
        return _makeBloc(
          getTransactions: getTransactions,
          getDeletedTransactions: getDeletedTransactions,
          softDeleteTransaction: softDeleteTransaction,
          restoreTransaction: restoreTransaction,
          permanentDeleteTransaction: permanentDeleteTransaction,
        );
      },
      act: (bloc) => bloc.add(const TransactionsLoaded()),
      expect: () => [
        const TransactionListLoading(),
        isA<TransactionListLoaded>(),
      ],
    );

    blocTest<TransactionListBloc, TransactionListState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => getTransactions()).thenAnswer(
          (_) async =>
              const Left(StorageFailure('error')),
        );
        return _makeBloc(
          getTransactions: getTransactions,
          getDeletedTransactions: getDeletedTransactions,
          softDeleteTransaction: softDeleteTransaction,
          restoreTransaction: restoreTransaction,
          permanentDeleteTransaction: permanentDeleteTransaction,
        );
      },
      act: (bloc) => bloc.add(const TransactionsLoaded()),
      expect: () => [
        const TransactionListLoading(),
        isA<TransactionListError>(),
      ],
    );
  });

  group('TransactionsTrashLoaded', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'emits [Loading, TrashLoaded] on success',
      build: () {
        when(() => getDeletedTransactions())
            .thenAnswer((_) async => Right([_tx()]));
        return _makeBloc(
          getTransactions: getTransactions,
          getDeletedTransactions: getDeletedTransactions,
          softDeleteTransaction: softDeleteTransaction,
          restoreTransaction: restoreTransaction,
          permanentDeleteTransaction: permanentDeleteTransaction,
        );
      },
      act: (bloc) => bloc.add(const TransactionsTrashLoaded()),
      expect: () => [
        const TransactionListLoading(),
        isA<TransactionListTrashLoaded>(),
      ],
    );
  });

  group('TransactionDeleteRequested', () {
    blocTest<TransactionListBloc, TransactionListState>(
      'calls softDelete then re-loads active list',
      build: () {
        when(() => softDeleteTransaction(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => getTransactions())
            .thenAnswer((_) async => const Right([]));
        return _makeBloc(
          getTransactions: getTransactions,
          getDeletedTransactions: getDeletedTransactions,
          softDeleteTransaction: softDeleteTransaction,
          restoreTransaction: restoreTransaction,
          permanentDeleteTransaction: permanentDeleteTransaction,
        );
      },
      act: (bloc) =>
          bloc.add(const TransactionDeleteRequested('tx1')),
      expect: () => [
        const TransactionListLoading(),
        const TransactionListLoaded([]),
      ],
      verify: (_) {
        verify(() => softDeleteTransaction('tx1')).called(1);
      },
    );
  });
}
