import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/products/data/datasources/product_local_data_source.dart';
import 'package:bizops/features/products/data/models/product_model.dart';
import 'package:bizops/features/products/data/repositories/product_repository_impl.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductLocalDataSource extends Mock
    implements ProductLocalDataSource {}

void main() {
  late ProductRepositoryImpl repository;
  late MockProductLocalDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(
      ProductModel(
        id: '',
        name: '',
        price: 0,
        unit: '',
        isDeleted: false,
        createdAtMillis: 0,
        updatedAtMillis: 0,
      ),
    );
  });

  setUp(() {
    mockDataSource = MockProductLocalDataSource();
    repository = ProductRepositoryImpl(mockDataSource);
  });

  ProductModel makeModel({String id = '1', bool isDeleted = false}) =>
      ProductModel(
        id: id,
        name: 'Test',
        price: 10.0,
        unit: 'kg',
        isDeleted: isDeleted,
        createdAtMillis: DateTime(2024).millisecondsSinceEpoch,
        updatedAtMillis: DateTime(2024).millisecondsSinceEpoch,
      );

  group('getProducts', () {
    test('returns only non-deleted products', () async {
      final models = [makeModel(id: '1'), makeModel(id: '2', isDeleted: true)];
      when(() => mockDataSource.getAll()).thenAnswer((_) async => models);

      final result = await repository.getProducts();

      result.fold(
        (f) => fail('Expected Right'),
        (products) {
          expect(products.length, 1);
          expect(products.first.id, '1');
        },
      );
    });

    test('returns StorageFailure on exception', () async {
      when(() => mockDataSource.getAll()).thenThrow(Exception('db error'));

      final result = await repository.getProducts();

      result.fold(
        (f) => expect(f, isA<StorageFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('softDeleteProduct', () {
    test('marks product as deleted', () async {
      final model = makeModel();
      when(() => mockDataSource.getById('1')).thenAnswer((_) async => model);
      when(() => mockDataSource.save(any())).thenAnswer((_) async {});

      final result = await repository.softDeleteProduct('1');

      expect(result, const Right(unit));
      final captured =
          verify(() => mockDataSource.save(captureAny())).captured.first
              as ProductModel;
      expect(captured.isDeleted, true);
    });

    test('returns NotFoundFailure when product not found', () async {
      when(() => mockDataSource.getById('1')).thenAnswer((_) async => null);

      final result = await repository.softDeleteProduct('1');

      expect(result, const Left(NotFoundFailure('Product not found: 1')));
    });
  });

  group('restoreProduct', () {
    test('marks product as not deleted', () async {
      final model = makeModel(isDeleted: true);
      when(() => mockDataSource.getById('1')).thenAnswer((_) async => model);
      when(() => mockDataSource.save(any())).thenAnswer((_) async {});

      final result = await repository.restoreProduct('1');

      expect(result, const Right(unit));
      final captured =
          verify(() => mockDataSource.save(captureAny())).captured.first
              as ProductModel;
      expect(captured.isDeleted, false);
    });
  });

  group('permanentDeleteProduct', () {
    test('calls delete on data source', () async {
      when(() => mockDataSource.delete('1')).thenAnswer((_) async {});

      final result = await repository.permanentDeleteProduct('1');

      expect(result, const Right(unit));
      verify(() => mockDataSource.delete('1')).called(1);
    });
  });
}
