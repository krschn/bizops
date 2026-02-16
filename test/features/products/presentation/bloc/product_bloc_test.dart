import 'package:bizops/core/error/failures.dart';
import 'package:bizops/features/products/domain/entities/product.dart';
import 'package:bizops/features/products/domain/usecases/get_deleted_products.dart';
import 'package:bizops/features/products/domain/usecases/get_products.dart';
import 'package:bizops/features/products/domain/usecases/permanent_delete_product.dart';
import 'package:bizops/features/products/domain/usecases/restore_product.dart';
import 'package:bizops/features/products/domain/usecases/save_product.dart';
import 'package:bizops/features/products/domain/usecases/soft_delete_product.dart';
import 'package:bizops/features/products/presentation/bloc/product_bloc.dart';
import 'package:bizops/features/products/presentation/bloc/product_event.dart';
import 'package:bizops/features/products/presentation/bloc/product_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetProducts extends Mock implements GetProducts {}

class MockGetDeletedProducts extends Mock implements GetDeletedProducts {}

class MockSaveProduct extends Mock implements SaveProduct {}

class MockSoftDeleteProduct extends Mock implements SoftDeleteProduct {}

class MockRestoreProduct extends Mock implements RestoreProduct {}

class MockPermanentDeleteProduct extends Mock implements PermanentDeleteProduct {}

void main() {
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

  late MockGetProducts mockGetProducts;
  late MockGetDeletedProducts mockGetDeletedProducts;
  late MockSaveProduct mockSaveProduct;
  late MockSoftDeleteProduct mockSoftDeleteProduct;
  late MockRestoreProduct mockRestoreProduct;
  late MockPermanentDeleteProduct mockPermanentDeleteProduct;

  final product = Product(
    id: '1',
    name: 'Test',
    price: 10.0,
    unit: 'kg',
    isDeleted: false,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  setUp(() {
    mockGetProducts = MockGetProducts();
    mockGetDeletedProducts = MockGetDeletedProducts();
    mockSaveProduct = MockSaveProduct();
    mockSoftDeleteProduct = MockSoftDeleteProduct();
    mockRestoreProduct = MockRestoreProduct();
    mockPermanentDeleteProduct = MockPermanentDeleteProduct();
  });

  ProductBloc buildBloc() => ProductBloc(
        getProducts: mockGetProducts,
        getDeletedProducts: mockGetDeletedProducts,
        saveProduct: mockSaveProduct,
        softDeleteProduct: mockSoftDeleteProduct,
        restoreProduct: mockRestoreProduct,
        permanentDeleteProduct: mockPermanentDeleteProduct,
      );

  blocTest<ProductBloc, ProductState>(
    'emits [loading, loaded] on ProductsLoaded success',
    build: buildBloc,
    setUp: () {
      when(() => mockGetProducts()).thenAnswer((_) async => Right([product]));
    },
    act: (bloc) => bloc.add(const ProductsLoaded()),
    expect: () => [
      const ProductLoading(),
      ProductLoaded([product]),
    ],
  );

  blocTest<ProductBloc, ProductState>(
    'emits [loading, error] on ProductsLoaded failure',
    build: buildBloc,
    setUp: () {
      when(() => mockGetProducts())
          .thenAnswer((_) async => const Left(StorageFailure('error')));
    },
    act: (bloc) => bloc.add(const ProductsLoaded()),
    expect: () => [
      const ProductLoading(),
      const ProductError('error'),
    ],
  );

  blocTest<ProductBloc, ProductState>(
    'emits [saving, saveSuccess] on ProductSaveRequested success',
    build: buildBloc,
    setUp: () {
      when(() => mockSaveProduct(any()))
          .thenAnswer((_) async => const Right(unit));
    },
    act: (bloc) => bloc.add(ProductSaveRequested(product)),
    expect: () => [
      const ProductSaving(),
      const ProductSaveSuccess(),
    ],
  );

  blocTest<ProductBloc, ProductState>(
    'emits [saving, error] on ProductSaveRequested validation failure',
    build: buildBloc,
    setUp: () {
      when(() => mockSaveProduct(any())).thenAnswer(
        (_) async => const Left(ValidationFailure('Name is required')),
      );
    },
    act: (bloc) => bloc.add(ProductSaveRequested(product)),
    expect: () => [
      const ProductSaving(),
      const ProductError('Name is required'),
    ],
  );

  blocTest<ProductBloc, ProductState>(
    'refreshes active list after ProductDeleteRequested success',
    build: buildBloc,
    setUp: () {
      when(() => mockSoftDeleteProduct(any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => mockGetProducts()).thenAnswer((_) async => Right([product]));
    },
    act: (bloc) => bloc.add(const ProductDeleteRequested('1')),
    expect: () => [
      const ProductLoading(),
      ProductLoaded([product]),
    ],
  );

  blocTest<ProductBloc, ProductState>(
    'emits error on ProductDeleteRequested failure',
    build: buildBloc,
    setUp: () {
      when(() => mockSoftDeleteProduct(any()))
          .thenAnswer((_) async => const Left(NotFoundFailure('not found')));
    },
    act: (bloc) => bloc.add(const ProductDeleteRequested('1')),
    expect: () => [
      const ProductError('not found'),
    ],
  );
}
