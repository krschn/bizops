import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:bizops/features/transactions/domain/usecases/soft_delete_line.dart';

class MockTransactionRepository extends Mock
    implements TransactionRepository {}

void main() {
  late MockTransactionRepository repository;
  late SoftDeleteLine useCase;

  setUp(() {
    repository = MockTransactionRepository();
    useCase = SoftDeleteLine(repository);
    when(() => repository.softDeleteLine(any(), any()))
        .thenAnswer((_) async => const Right(unit));
  });

  test('delegates (txId, lineId) to repository', () async {
    const txId = 'tx1';
    const lineId = 'line1';

    final result = await useCase(txId, lineId);

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => repository.softDeleteLine(txId, lineId)).called(1);
  });
}
