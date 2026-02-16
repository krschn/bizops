import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/products/domain/repositories/product_repository.dart';
import 'package:bizops/features/products/domain/usecases/restore_product.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late RestoreProduct useCase;
  late MockProductRepository mockRepository;

  setUp(() {
    mockRepository = MockProductRepository();
    useCase = RestoreProduct(mockRepository);
  });

  test('calls repository restoreProduct', () async {
    when(() => mockRepository.restoreProduct(any()))
        .thenAnswer((_) async => const Right(unit));

    final result = await useCase('1');

    expect(result, const Right(unit));
    verify(() => mockRepository.restoreProduct('1')).called(1);
  });

  test('returns failure on error', () async {
    when(() => mockRepository.restoreProduct(any()))
        .thenAnswer((_) async => const Left(NotFoundFailure('not found')));

    final result = await useCase('1');

    expect(result, const Left(NotFoundFailure('not found')));
  });
}
