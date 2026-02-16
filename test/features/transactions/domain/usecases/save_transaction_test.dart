import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/transactions/domain/entities/transaction.dart';
import 'package:bizops/features/transactions/domain/entities/transaction_line.dart';
import 'package:bizops/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:bizops/features/transactions/domain/usecases/save_transaction.dart';

class MockTransactionRepository extends Mock
    implements TransactionRepository {}

TransactionLine _line({
  String id = 'line1',
  double quantity = 1,
  double unitPrice = 10,
  bool isDeleted = false,
}) =>
    TransactionLine(
      id: id,
      transactionId: 'tx1',
      supplierId: 's1',
      supplierName: 'Supplier',
      productId: 'p1',
      productName: 'Product',
      unit: 'kg',
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal: quantity * unitPrice,
      isDeleted: isDeleted,
      sortOrder: 0,
    );

Transaction _tx({required List<TransactionLine> lines}) {
  final now = DateTime(2025);
  return Transaction(
    id: 'tx1',
    transactedAt: now,
    lines: lines,
    grandTotal: 10,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockTransactionRepository repository;
  late SaveTransaction useCase;

  setUpAll(() {
    registerFallbackValue(
      _tx(lines: [_line()]),
    );
  });

  setUp(() {
    repository = MockTransactionRepository();
    useCase = SaveTransaction(repository);
    when(() => repository.save(any())).thenAnswer((_) async => const Right(unit));
  });

  group('SaveTransaction', () {
    test('delegates to repository when transaction has valid active lines', () async {
      final tx = _tx(lines: [_line(quantity: 2, unitPrice: 5)]);
      final result = await useCase(tx);

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => repository.save(tx)).called(1);
    });

    test('returns ValidationFailure when lines list is empty', () async {
      final tx = _tx(lines: []);
      final result = await useCase(tx);

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected failure'),
      );
      verifyNever(() => repository.save(any()));
    });

    test('returns ValidationFailure when all lines are deleted', () async {
      final tx = _tx(lines: [_line(isDeleted: true)]);
      final result = await useCase(tx);

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected failure'),
      );
      verifyNever(() => repository.save(any()));
    });

    test('returns ValidationFailure when a line has quantity = 0', () async {
      final tx = _tx(lines: [_line(quantity: 0)]);
      final result = await useCase(tx);

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected failure'),
      );
      verifyNever(() => repository.save(any()));
    });

    test('returns ValidationFailure when a line has negative unit price', () async {
      final tx = _tx(lines: [_line(unitPrice: -1)]);
      final result = await useCase(tx);

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('expected failure'),
      );
      verifyNever(() => repository.save(any()));
    });
  });
}
