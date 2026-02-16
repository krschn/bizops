import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/suppliers/domain/entities/supplier.dart';
import 'package:bizops/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:bizops/features/suppliers/domain/usecases/save_supplier.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSupplierRepository extends Mock implements SupplierRepository {}

void main() {
  late SaveSupplier useCase;
  late MockSupplierRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      Supplier(
        id: '',
        name: '',
        isDeleted: false,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    );
  });

  setUp(() {
    mockRepository = MockSupplierRepository();
    useCase = SaveSupplier(mockRepository);
  });

  final validSupplier = Supplier(
    id: '1',
    name: 'Valid Supplier',
    isDeleted: false,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  test('saves supplier when valid', () async {
    when(() => mockRepository.save(any()))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(validSupplier);

    expect(result, const Right(unit));
    verify(() => mockRepository.save(validSupplier)).called(1);
  });

  test('returns ValidationFailure when name is empty', () async {
    final supplier = validSupplier.copyWith(name: '');

    final result = await useCase(supplier);

    expect(result, const Left(ValidationFailure('Name is required')));
    verifyNever(() => mockRepository.save(any()));
  });

  test('returns ValidationFailure when name is whitespace only', () async {
    final supplier = validSupplier.copyWith(name: '   ');

    final result = await useCase(supplier);

    expect(result, const Left(ValidationFailure('Name is required')));
    verifyNever(() => mockRepository.save(any()));
  });
}
