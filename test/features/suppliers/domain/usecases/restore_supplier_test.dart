import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:bizops/features/suppliers/domain/usecases/restore_supplier.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSupplierRepository extends Mock implements SupplierRepository {}

void main() {
  late RestoreSupplier useCase;
  late MockSupplierRepository mockRepository;

  setUp(() {
    mockRepository = MockSupplierRepository();
    useCase = RestoreSupplier(mockRepository);
  });

  test('delegates to repository restore', () async {
    when(() => mockRepository.restore('1'))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase('1');

    expect(result, const Right(unit));
    verify(() => mockRepository.restore('1')).called(1);
  });

  test('returns failure when repository fails', () async {
    when(() => mockRepository.restore('1'))
        .thenAnswer((_) async => const Left(NotFoundFailure('Supplier not found: 1')));

    final result = await useCase('1');

    expect(result, const Left(NotFoundFailure('Supplier not found: 1')));
  });
}
