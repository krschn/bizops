import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:bizops/features/transactions/data/models/transaction_line_model.dart';
import 'package:bizops/features/transactions/data/models/transaction_model.dart';
import 'package:bizops/features/transactions/data/repositories/transaction_repository_impl.dart';

class MockTransactionLocalDataSource extends Mock
    implements TransactionLocalDataSource {}

TransactionLineModel _lineModel({
  String id = 'line1',
  bool isDeleted = false,
  double lineTotal = 10.0,
}) =>
    TransactionLineModel(
      id: id,
      transactionId: 'tx1',
      supplierId: 's1',
      supplierName: 'Supplier',
      productId: 'p1',
      productName: 'Product',
      unit: 'kg',
      quantity: 1,
      unitPrice: lineTotal,
      lineTotal: lineTotal,
      isDeleted: isDeleted,
      sortOrder: 0,
    );

TransactionModel _txModel({
  String id = 'tx1',
  bool isDeleted = false,
  List<TransactionLineModel>? lines,
  double grandTotal = 10.0,
}) =>
    TransactionModel(
      id: id,
      transactedAtMillis: DateTime(2025).millisecondsSinceEpoch,
      lines: lines ?? [_lineModel()],
      grandTotal: grandTotal,
      isDeleted: isDeleted,
      createdAtMillis: DateTime(2025).millisecondsSinceEpoch,
      updatedAtMillis: DateTime(2025).millisecondsSinceEpoch,
    );

void main() {
  late MockTransactionLocalDataSource dataSource;
  late TransactionRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_txModel());
  });

  setUp(() {
    dataSource = MockTransactionLocalDataSource();
    repository = TransactionRepositoryImpl(dataSource);
  });

  group('softDeleteTransaction', () {
    test('sets isDeleted=true and saves', () async {
      final model = _txModel(isDeleted: false);
      when(() => dataSource.getById('tx1')).thenAnswer((_) async => model);
      when(() => dataSource.save(any())).thenAnswer((_) async {});

      final result = await repository.softDeleteTransaction('tx1');

      expect(result, const Right<Failure, Unit>(unit));
      final captured =
          verify(() => dataSource.save(captureAny())).captured.single
              as TransactionModel;
      expect(captured.isDeleted, true);
    });
  });

  group('softDeleteLine', () {
    test('finds line, sets isDeleted=true, recomputes grandTotal, saves',
        () async {
      final model = _txModel(
        lines: [
          _lineModel(id: 'line1', lineTotal: 10.0),
          _lineModel(id: 'line2', lineTotal: 20.0),
        ],
        grandTotal: 30.0,
      );
      when(() => dataSource.getById('tx1')).thenAnswer((_) async => model);
      when(() => dataSource.save(any())).thenAnswer((_) async {});

      final result = await repository.softDeleteLine('tx1', 'line1');

      expect(result, const Right<Failure, Unit>(unit));
      final captured =
          verify(() => dataSource.save(captureAny())).captured.single
              as TransactionModel;
      final deletedLine =
          captured.lines.firstWhere((l) => l.id == 'line1');
      expect(deletedLine.isDeleted, true);
      expect(captured.grandTotal, 20.0);
    });
  });

  group('restoreLine', () {
    test('finds line, sets isDeleted=false, recomputes grandTotal, saves',
        () async {
      final model = _txModel(
        lines: [
          _lineModel(id: 'line1', lineTotal: 10.0, isDeleted: true),
          _lineModel(id: 'line2', lineTotal: 20.0),
        ],
        grandTotal: 20.0,
      );
      when(() => dataSource.getById('tx1')).thenAnswer((_) async => model);
      when(() => dataSource.save(any())).thenAnswer((_) async {});

      final result = await repository.restoreLine('tx1', 'line1');

      expect(result, const Right<Failure, Unit>(unit));
      final captured =
          verify(() => dataSource.save(captureAny())).captured.single
              as TransactionModel;
      final restoredLine =
          captured.lines.firstWhere((l) => l.id == 'line1');
      expect(restoredLine.isDeleted, false);
      expect(captured.grandTotal, 30.0);
    });
  });

  group('getByDateRange', () {
    test('returns only transactions within the date range', () async {
      final inRange = _txModel(id: 'tx_in');
      when(() => dataSource.getByDateRange(any(), any()))
          .thenAnswer((_) async => [inRange]);

      final from = DateTime(2025, 1, 1);
      final to = DateTime(2025, 12, 31);
      final result = await repository.getByDateRange(from, to);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected right'),
        (txs) {
          expect(txs.length, 1);
          expect(txs.first.id, 'tx_in');
        },
      );
    });
  });
}
