import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/suppliers/domain/entities/supplier.dart';
import 'package:bizops/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:bizops/features/suppliers/domain/usecases/get_suppliers.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSupplierRepository extends Mock implements SupplierRepository {}

void main() {
  late GetSuppliers useCase;
  late MockSupplierRepository mockRepository;

  setUp(() {
    mockRepository = MockSupplierRepository();
    useCase = GetSuppliers(mockRepository);
  });

  final suppliers = [
    Supplier(
      id: '1',
      name: 'Test Supplier',
      isDeleted: false,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
  ];

  test('returns list of suppliers on success', () async {
    when(() => mockRepository.getAll())
        .thenAnswer((_) async => Right(suppliers));

    final result = await useCase();

    expect(result, Right(suppliers));
    verify(() => mockRepository.getAll()).called(1);
  });

  test('returns StorageFailure on error', () async {
    when(() => mockRepository.getAll())
        .thenAnswer((_) async => const Left(StorageFailure('error')));

    final result = await useCase();

    expect(result, const Left(StorageFailure('error')));
  });
}
