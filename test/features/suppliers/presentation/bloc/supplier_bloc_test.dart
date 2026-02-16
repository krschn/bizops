import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/suppliers/domain/entities/supplier.dart';
import 'package:bizops/features/suppliers/domain/usecases/get_deleted_suppliers.dart';
import 'package:bizops/features/suppliers/domain/usecases/get_suppliers.dart';
import 'package:bizops/features/suppliers/domain/usecases/permanent_delete_supplier.dart';
import 'package:bizops/features/suppliers/domain/usecases/restore_supplier.dart';
import 'package:bizops/features/suppliers/domain/usecases/save_supplier.dart';
import 'package:bizops/features/suppliers/domain/usecases/soft_delete_supplier.dart';
import 'package:bizops/features/suppliers/presentation/bloc/supplier_bloc.dart';
import 'package:bizops/features/suppliers/presentation/bloc/supplier_event.dart';
import 'package:bizops/features/suppliers/presentation/bloc/supplier_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSuppliers extends Mock implements GetSuppliers {}

class MockGetDeletedSuppliers extends Mock implements GetDeletedSuppliers {}

class MockSaveSupplier extends Mock implements SaveSupplier {}

class MockSoftDeleteSupplier extends Mock implements SoftDeleteSupplier {}

class MockRestoreSupplier extends Mock implements RestoreSupplier {}

class MockPermanentDeleteSupplier extends Mock
    implements PermanentDeleteSupplier {}

void main() {
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

  late MockGetSuppliers mockGetSuppliers;
  late MockGetDeletedSuppliers mockGetDeletedSuppliers;
  late MockSaveSupplier mockSaveSupplier;
  late MockSoftDeleteSupplier mockSoftDeleteSupplier;
  late MockRestoreSupplier mockRestoreSupplier;
  late MockPermanentDeleteSupplier mockPermanentDeleteSupplier;

  final supplier = Supplier(
    id: '1',
    name: 'Test Supplier',
    isDeleted: false,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  setUp(() {
    mockGetSuppliers = MockGetSuppliers();
    mockGetDeletedSuppliers = MockGetDeletedSuppliers();
    mockSaveSupplier = MockSaveSupplier();
    mockSoftDeleteSupplier = MockSoftDeleteSupplier();
    mockRestoreSupplier = MockRestoreSupplier();
    mockPermanentDeleteSupplier = MockPermanentDeleteSupplier();
  });

  SupplierBloc buildBloc() => SupplierBloc(
        getSuppliers: mockGetSuppliers,
        getDeletedSuppliers: mockGetDeletedSuppliers,
        saveSupplier: mockSaveSupplier,
        softDeleteSupplier: mockSoftDeleteSupplier,
        restoreSupplier: mockRestoreSupplier,
        permanentDeleteSupplier: mockPermanentDeleteSupplier,
      );

  blocTest<SupplierBloc, SupplierState>(
    'emits [loading, loaded] on SuppliersLoaded success',
    build: buildBloc,
    setUp: () {
      when(() => mockGetSuppliers())
          .thenAnswer((_) async => Right([supplier]));
    },
    act: (bloc) => bloc.add(const SuppliersLoaded()),
    expect: () => [
      const SupplierLoading(),
      SupplierLoaded([supplier]),
    ],
  );

  blocTest<SupplierBloc, SupplierState>(
    'emits [loading, error] on SuppliersLoaded failure',
    build: buildBloc,
    setUp: () {
      when(() => mockGetSuppliers()).thenAnswer(
        (_) async => const Left(StorageFailure('error')),
      );
    },
    act: (bloc) => bloc.add(const SuppliersLoaded()),
    expect: () => [
      const SupplierLoading(),
      const SupplierError(StorageFailure('error')),
    ],
  );

  blocTest<SupplierBloc, SupplierState>(
    'emits [saving, saveSuccess] on SupplierSaveRequested success',
    build: buildBloc,
    setUp: () {
      when(() => mockSaveSupplier(any()))
          .thenAnswer((_) async => const Right(unit));
    },
    act: (bloc) => bloc.add(SupplierSaveRequested(supplier)),
    expect: () => [
      const SupplierSaving(),
      const SupplierSaveSuccess(),
    ],
  );

  blocTest<SupplierBloc, SupplierState>(
    'emits [saving, error] on SupplierSaveRequested validation failure',
    build: buildBloc,
    setUp: () {
      when(() => mockSaveSupplier(any())).thenAnswer(
        (_) async => const Left(ValidationFailure('Name is required')),
      );
    },
    act: (bloc) => bloc.add(SupplierSaveRequested(supplier)),
    expect: () => [
      const SupplierSaving(),
      const SupplierError(ValidationFailure('Name is required')),
    ],
  );

  blocTest<SupplierBloc, SupplierState>(
    'refreshes active list after SupplierDeleteRequested success',
    build: buildBloc,
    setUp: () {
      when(() => mockSoftDeleteSupplier(any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockGetSuppliers())
          .thenAnswer((_) async => Right([supplier]));
    },
    act: (bloc) => bloc.add(const SupplierDeleteRequested('1')),
    expect: () => [
      const SupplierLoading(),
      SupplierLoaded([supplier]),
    ],
  );

  blocTest<SupplierBloc, SupplierState>(
    'emits error on SupplierDeleteRequested failure',
    build: buildBloc,
    setUp: () {
      when(() => mockSoftDeleteSupplier(any())).thenAnswer(
        (_) async => const Left(NotFoundFailure('not found')),
      );
    },
    act: (bloc) => bloc.add(const SupplierDeleteRequested('1')),
    expect: () => [
      const SupplierError(NotFoundFailure('not found')),
    ],
  );
}
