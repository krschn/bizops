import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/suppliers/data/datasources/supplier_local_data_source.dart';
import 'package:bizops/features/suppliers/data/models/supplier_model.dart';
import 'package:bizops/features/suppliers/data/repositories/supplier_repository_impl.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSupplierLocalDataSource extends Mock
    implements SupplierLocalDataSource {}

void main() {
  late SupplierRepositoryImpl repository;
  late MockSupplierLocalDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(
      SupplierModel(
        id: '',
        name: '',
        isDeleted: false,
        createdAtMillis: 0,
        updatedAtMillis: 0,
      ),
    );
  });

  setUp(() {
    mockDataSource = MockSupplierLocalDataSource();
    repository = SupplierRepositoryImpl(mockDataSource);
  });

  SupplierModel makeModel({String id = '1', bool isDeleted = false}) =>
      SupplierModel(
        id: id,
        name: 'Test Supplier',
        isDeleted: isDeleted,
        createdAtMillis: DateTime(2024).millisecondsSinceEpoch,
        updatedAtMillis: DateTime(2024).millisecondsSinceEpoch,
      );

  group('getAll', () {
    test('returns only non-deleted suppliers', () async {
      final models = [makeModel(id: '1'), makeModel(id: '2', isDeleted: true)];
      when(() => mockDataSource.getAll()).thenAnswer((_) async => models);

      final result = await repository.getAll();

      result.fold(
        (f) => fail('Expected Right'),
        (suppliers) {
          expect(suppliers.length, 1);
          expect(suppliers.first.id, '1');
        },
      );
    });

    test('returns StorageFailure on exception', () async {
      when(() => mockDataSource.getAll()).thenThrow(Exception('db error'));

      final result = await repository.getAll();

      result.fold(
        (f) => expect(f, isA<StorageFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getDeleted', () {
    test('returns only deleted suppliers', () async {
      final models = [makeModel(id: '1'), makeModel(id: '2', isDeleted: true)];
      when(() => mockDataSource.getAll()).thenAnswer((_) async => models);

      final result = await repository.getDeleted();

      result.fold(
        (f) => fail('Expected Right'),
        (suppliers) {
          expect(suppliers.length, 1);
          expect(suppliers.first.id, '2');
        },
      );
    });
  });

  group('softDelete', () {
    test('marks supplier as deleted', () async {
      final model = makeModel();
      when(() => mockDataSource.getById('1')).thenAnswer((_) async => model);
      when(() => mockDataSource.save(any())).thenAnswer((_) async {});

      final result = await repository.softDelete('1');

      expect(result, const Right(unit));
      final captured =
          verify(() => mockDataSource.save(captureAny())).captured.first
              as SupplierModel;
      expect(captured.isDeleted, true);
    });

    test('returns NotFoundFailure when supplier not found', () async {
      when(() => mockDataSource.getById('1')).thenAnswer((_) async => null);

      final result = await repository.softDelete('1');

      expect(result, const Left(NotFoundFailure('Supplier not found: 1')));
    });
  });

  group('restore', () {
    test('marks supplier as not deleted', () async {
      final model = makeModel(isDeleted: true);
      when(() => mockDataSource.getById('1')).thenAnswer((_) async => model);
      when(() => mockDataSource.save(any())).thenAnswer((_) async {});

      final result = await repository.restore('1');

      expect(result, const Right(unit));
      final captured =
          verify(() => mockDataSource.save(captureAny())).captured.first
              as SupplierModel;
      expect(captured.isDeleted, false);
    });
  });

  group('permanentDelete', () {
    test('calls delete on data source', () async {
      when(() => mockDataSource.delete('1')).thenAnswer((_) async {});

      final result = await repository.permanentDelete('1');

      expect(result, const Right(unit));
      verify(() => mockDataSource.delete('1')).called(1);
    });
  });
}
