import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/products/domain/entities/product.dart';
import 'package:bizops/features/products/domain/repositories/product_repository.dart';
import 'package:bizops/features/products/domain/usecases/get_products.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late GetProducts useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = GetProducts(mockRepository);
  });

  final products = [
    Product(
      id: '1',
      name: 'Test Product',
      price: 10.0,
      unit: 'kg',
      isDeleted: false,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
  ];

  test('returns list of products on success', () async {
    when(() => mockRepository.getProducts())
        .thenAnswer((_) async => Right(products));

    final result = await useCase();

    expect(result, Right(products));
    verify(() => mockRepository.getProducts()).called(1);
  });

  test('returns StorageFailure on error', () async {
    when(() => mockRepository.getProducts())
        .thenAnswer((_) async => const Left(StorageFailure('error')));

    final result = await useCase();

    expect(result, const Left(StorageFailure('error')));
  });
}
