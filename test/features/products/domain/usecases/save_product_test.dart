import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/products/domain/entities/product.dart';
import 'package:bizops/features/products/domain/repositories/product_repository.dart';
import 'package:bizops/features/products/domain/usecases/save_product.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late SaveProduct useCase;
  late MockProductRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      Product(
        id: '',
        name: '',
        price: 0,
        unit: '',
        isDeleted: false,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    );
  });

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = SaveProduct(mockRepository);
  });

  final validProduct = Product(
    id: '1',
    name: 'Valid Product',
    price: 10.0,
    unit: 'kg',
    isDeleted: false,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  test('saves product when valid', () async {
    when(() => mockRepository.saveProduct(any()))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase(validProduct);

    expect(result, const Right(unit));
    verify(() => mockRepository.saveProduct(validProduct)).called(1);
  });

  test('returns ValidationFailure when name is empty', () async {
    final product = validProduct.copyWith(name: '');

    final result = await useCase(product);

    expect(result, const Left(ValidationFailure('Name is required')));
    verifyNever(() => mockRepository.saveProduct(any()));
  });

  test('returns ValidationFailure when price is negative', () async {
    final product = validProduct.copyWith(price: -1.0);

    final result = await useCase(product);

    expect(result, const Left(ValidationFailure('Price must be non-negative')));
    verifyNever(() => mockRepository.saveProduct(any()));
  });

  test('returns ValidationFailure when unit is empty', () async {
    final product = validProduct.copyWith(unit: '');

    final result = await useCase(product);

    expect(result, const Left(ValidationFailure('Unit is required')));
    verifyNever(() => mockRepository.saveProduct(any()));
  });
}
