import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/products/domain/entities/product.dart';
import 'package:bizops/features/products/domain/usecases/get_products.dart';
import 'package:bizops/features/suppliers/domain/entities/supplier.dart';
import 'package:bizops/features/suppliers/domain/usecases/get_suppliers.dart';
import 'package:bizops/features/transactions/domain/entities/transaction.dart';
import 'package:bizops/features/transactions/domain/entities/transaction_line.dart';
import 'package:bizops/features/transactions/domain/usecases/get_transaction_by_id.dart';
import 'package:bizops/features/transactions/domain/usecases/save_transaction.dart';
import 'package:bizops/features/transactions/presentation/bloc/transaction_form_bloc/transaction_form_bloc.dart';
import 'package:bizops/features/transactions/presentation/bloc/transaction_form_bloc/transaction_form_event.dart';
import 'package:bizops/features/transactions/presentation/bloc/transaction_form_bloc/transaction_form_state.dart';

class MockGetTransactionById extends Mock implements GetTransactionById {}

class MockGetProducts extends Mock implements GetProducts {}

class MockGetSuppliers extends Mock implements GetSuppliers {}

class MockSaveTransaction extends Mock implements SaveTransaction {}

class FakeTransaction extends Fake implements Transaction {}

DateTime _dt = DateTime(2025);

Product _product() => Product(
      id: 'p1',
      name: 'Product',
      price: 10,
      unit: 'kg',
      isDeleted: false,
      createdAt: _dt,
      updatedAt: _dt,
    );

Supplier _supplier() => Supplier(
      id: 's1',
      name: 'Supplier',
      isDeleted: false,
      createdAt: _dt,
      updatedAt: _dt,
    );

TransactionLine _line({bool isDeleted = false}) => TransactionLine(
      id: 'line1',
      transactionId: 'tx1',
      supplierId: 's1',
      supplierName: 'Supplier',
      productId: 'p1',
      productName: 'Product',
      unit: 'kg',
      quantity: 2,
      unitPrice: 5,
      lineTotal: 10,
      isDeleted: isDeleted,
      sortOrder: 0,
    );

Transaction _tx({List<TransactionLine>? lines}) => Transaction(
      id: 'tx1',
      transactedAt: _dt,
      lines: lines ?? [_line()],
      grandTotal: 10,
      isDeleted: false,
      createdAt: _dt,
      updatedAt: _dt,
    );

TransactionFormBloc _makeBloc({
  required MockGetTransactionById getTransactionById,
  required MockGetProducts getProducts,
  required MockGetSuppliers getSuppliers,
  required MockSaveTransaction saveTransaction,
}) =>
    TransactionFormBloc(
      getTransactionById: getTransactionById,
      getProducts: getProducts,
      getSuppliers: getSuppliers,
      saveTransaction: saveTransaction,
    );

void main() {
  late MockGetTransactionById getTransactionById;
  late MockGetProducts getProducts;
  late MockGetSuppliers getSuppliers;
  late MockSaveTransaction saveTransaction;

  setUpAll(() {
    registerFallbackValue(FakeTransaction());
  });

  setUp(() {
    getTransactionById = MockGetTransactionById();
    getProducts = MockGetProducts();
    getSuppliers = MockGetSuppliers();
    saveTransaction = MockSaveTransaction();

    when(() => getProducts())
        .thenAnswer((_) async => Right([_product()]));
    when(() => getSuppliers())
        .thenAnswer((_) async => Right([_supplier()]));
  });

  group('TransactionFormInitialized (new transaction)', () {
    blocTest<TransactionFormBloc, TransactionFormState>(
      'emits [Loading, Ready] with empty lines for new transaction',
      build: () => _makeBloc(
        getTransactionById: getTransactionById,
        getProducts: getProducts,
        getSuppliers: getSuppliers,
        saveTransaction: saveTransaction,
      ),
      act: (bloc) =>
          bloc.add(const TransactionFormInitialized()),
      expect: () => [
        const TransactionFormLoading(),
        isA<TransactionFormReady>().having(
          (s) => s.lines,
          'lines',
          isEmpty,
        ),
      ],
    );
  });

  group('TransactionFormInitialized (edit transaction)', () {
    blocTest<TransactionFormBloc, TransactionFormState>(
      'emits [Loading, Ready] with existing lines for edit',
      build: () {
        when(() => getTransactionById('tx1'))
            .thenAnswer((_) async => Right(_tx()));
        return _makeBloc(
          getTransactionById: getTransactionById,
          getProducts: getProducts,
          getSuppliers: getSuppliers,
          saveTransaction: saveTransaction,
        );
      },
      act: (bloc) => bloc.add(
        const TransactionFormInitialized(existingTransactionId: 'tx1'),
      ),
      expect: () => [
        const TransactionFormLoading(),
        isA<TransactionFormReady>().having(
          (s) => s.lines.length,
          'lines count',
          1,
        ),
      ],
    );
  });

  group('TransactionLineAdded', () {
    blocTest<TransactionFormBloc, TransactionFormState>(
      'adds line and recomputes grandTotal',
      build: () => _makeBloc(
        getTransactionById: getTransactionById,
        getProducts: getProducts,
        getSuppliers: getSuppliers,
        saveTransaction: saveTransaction,
      ),
      seed: () => TransactionFormReady(
        lines: const [],
        availableProducts: [_product()],
        availableSuppliers: [_supplier()],
        grandTotal: 0,
      ),
      act: (bloc) => bloc.add(TransactionLineAdded(_line())),
      expect: () => [
        isA<TransactionFormReady>()
            .having((s) => s.lines.length, 'lines count', 1)
            .having((s) => s.grandTotal, 'grandTotal', 10.0),
      ],
    );
  });

  group('TransactionLineRemoved', () {
    blocTest<TransactionFormBloc, TransactionFormState>(
      'marks line deleted and recomputes grandTotal',
      build: () => _makeBloc(
        getTransactionById: getTransactionById,
        getProducts: getProducts,
        getSuppliers: getSuppliers,
        saveTransaction: saveTransaction,
      ),
      seed: () => TransactionFormReady(
        lines: [_line()],
        availableProducts: [_product()],
        availableSuppliers: [_supplier()],
        grandTotal: 10,
      ),
      act: (bloc) =>
          bloc.add(const TransactionLineRemoved('line1')),
      expect: () => [
        isA<TransactionFormReady>()
            .having(
              (s) => s.lines.first.isDeleted,
              'line isDeleted',
              true,
            )
            .having((s) => s.grandTotal, 'grandTotal', 0.0),
      ],
    );
  });

  group('TransactionSaveRequested', () {
    blocTest<TransactionFormBloc, TransactionFormState>(
      'emits [Saving, SaveSuccess] on valid transaction',
      build: () {
        when(() => saveTransaction(any()))
            .thenAnswer((_) async => const Right(unit));
        return _makeBloc(
          getTransactionById: getTransactionById,
          getProducts: getProducts,
          getSuppliers: getSuppliers,
          saveTransaction: saveTransaction,
        );
      },
      seed: () => TransactionFormReady(
        lines: [_line()],
        availableProducts: [_product()],
        availableSuppliers: [_supplier()],
        grandTotal: 10,
      ),
      act: (bloc) => bloc.add(const TransactionSaveRequested()),
      expect: () => [
        const TransactionFormSaving(),
        isA<TransactionFormSaveSuccess>(),
      ],
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'emits [Saving, Error] on validation failure',
      build: () {
        when(() => saveTransaction(any())).thenAnswer(
          (_) async => const Left(
            ValidationFailure('Transaction must have at least one line'),
          ),
        );
        return _makeBloc(
          getTransactionById: getTransactionById,
          getProducts: getProducts,
          getSuppliers: getSuppliers,
          saveTransaction: saveTransaction,
        );
      },
      seed: () => TransactionFormReady(
        lines: [_line(isDeleted: true)],
        availableProducts: [_product()],
        availableSuppliers: [_supplier()],
        grandTotal: 0,
      ),
      act: (bloc) => bloc.add(const TransactionSaveRequested()),
      expect: () => [
        const TransactionFormSaving(),
        isA<TransactionFormError>(),
      ],
    );
  });
}
