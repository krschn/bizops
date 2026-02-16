import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_deleted_products.dart';
import '../../domain/usecases/get_products.dart';
import '../../domain/usecases/permanent_delete_product.dart';
import '../../domain/usecases/restore_product.dart';
import '../../domain/usecases/save_product.dart';
import '../../domain/usecases/soft_delete_product.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc({
    required GetProducts getProducts,
    required GetDeletedProducts getDeletedProducts,
    required SaveProduct saveProduct,
    required SoftDeleteProduct softDeleteProduct,
    required RestoreProduct restoreProduct,
    required PermanentDeleteProduct permanentDeleteProduct,
  })  : _getProducts = getProducts,
        _getDeletedProducts = getDeletedProducts,
        _saveProduct = saveProduct,
        _softDeleteProduct = softDeleteProduct,
        _restoreProduct = restoreProduct,
        _permanentDeleteProduct = permanentDeleteProduct,
        super(const ProductInitial()) {
    on<ProductsLoaded>(_onProductsLoaded);
    on<ProductsTrashLoaded>(_onProductsTrashLoaded);
    on<ProductSaveRequested>(_onProductSaveRequested);
    on<ProductDeleteRequested>(_onProductDeleteRequested);
    on<ProductRestoreRequested>(_onProductRestoreRequested);
    on<ProductPermanentDeleteRequested>(_onProductPermanentDeleteRequested);
  }

  final GetProducts _getProducts;
  final GetDeletedProducts _getDeletedProducts;
  final SaveProduct _saveProduct;
  final SoftDeleteProduct _softDeleteProduct;
  final RestoreProduct _restoreProduct;
  final PermanentDeleteProduct _permanentDeleteProduct;

  Future<void> _onProductsLoaded(
    ProductsLoaded event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    final result = await _getProducts();
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductLoaded(products)),
    );
  }

  Future<void> _onProductsTrashLoaded(
    ProductsTrashLoaded event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    final result = await _getDeletedProducts();
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductTrashLoaded(products)),
    );
  }

  Future<void> _onProductSaveRequested(
    ProductSaveRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductSaving());
    final result = await _saveProduct(event.product);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => emit(const ProductSaveSuccess()),
    );
  }

  Future<void> _onProductDeleteRequested(
    ProductDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    final result = await _softDeleteProduct(event.id);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => add(const ProductsLoaded()),
    );
  }

  Future<void> _onProductRestoreRequested(
    ProductRestoreRequested event,
    Emitter<ProductState> emit,
  ) async {
    final result = await _restoreProduct(event.id);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => add(const ProductsTrashLoaded()),
    );
  }

  Future<void> _onProductPermanentDeleteRequested(
    ProductPermanentDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    final result = await _permanentDeleteProduct(event.id);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => add(const ProductsTrashLoaded()),
    );
  }
}
