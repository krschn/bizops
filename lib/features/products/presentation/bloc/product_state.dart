import 'package:equatable/equatable.dart';

import '../../domain/entities/product.dart';

sealed class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

final class ProductInitial extends ProductState {
  const ProductInitial();
}

final class ProductLoading extends ProductState {
  const ProductLoading();
}

final class ProductLoaded extends ProductState {
  const ProductLoaded(this.products);
  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

final class ProductTrashLoaded extends ProductState {
  const ProductTrashLoaded(this.products);
  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

final class ProductSaving extends ProductState {
  const ProductSaving();
}

final class ProductSaveSuccess extends ProductState {
  const ProductSaveSuccess();
}

final class ProductError extends ProductState {
  const ProductError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
