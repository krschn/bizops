import '../../domain/entities/product.dart';

sealed class ProductEvent {
  const ProductEvent();
}

final class ProductsLoaded extends ProductEvent {
  const ProductsLoaded();
}

final class ProductsTrashLoaded extends ProductEvent {
  const ProductsTrashLoaded();
}

final class ProductSaveRequested extends ProductEvent {
  const ProductSaveRequested(this.product);
  final Product product;
}

final class ProductDeleteRequested extends ProductEvent {
  const ProductDeleteRequested(this.id);
  final String id;
}

final class ProductRestoreRequested extends ProductEvent {
  const ProductRestoreRequested(this.id);
  final String id;
}

final class ProductPermanentDeleteRequested extends ProductEvent {
  const ProductPermanentDeleteRequested(this.id);
  final String id;
}
