import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../features/products/data/datasources/product_local_data_source.dart';
import '../../features/products/data/models/product_model.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/get_deleted_products.dart';
import '../../features/products/domain/usecases/get_products.dart';
import '../../features/products/domain/usecases/permanent_delete_product.dart';
import '../../features/products/domain/usecases/restore_product.dart';
import '../../features/products/domain/usecases/save_product.dart';
import '../../features/products/domain/usecases/soft_delete_product.dart';
import '../../features/products/presentation/bloc/product_bloc.dart';
import '../storage/hive_box_names.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Products
  getIt.registerLazySingleton<Box<ProductModel>>(
    () => Hive.box<ProductModel>(HiveBoxNames.products),
  );
  getIt.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<GetProducts>(() => GetProducts(getIt()));
  getIt.registerLazySingleton<GetDeletedProducts>(
    () => GetDeletedProducts(getIt()),
  );
  getIt.registerLazySingleton<SaveProduct>(() => SaveProduct(getIt()));
  getIt.registerLazySingleton<SoftDeleteProduct>(
    () => SoftDeleteProduct(getIt()),
  );
  getIt.registerLazySingleton<RestoreProduct>(() => RestoreProduct(getIt()));
  getIt.registerLazySingleton<PermanentDeleteProduct>(
    () => PermanentDeleteProduct(getIt()),
  );
  getIt.registerFactory<ProductBloc>(
    () => ProductBloc(
      getProducts: getIt(),
      getDeletedProducts: getIt(),
      saveProduct: getIt(),
      softDeleteProduct: getIt(),
      restoreProduct: getIt(),
      permanentDeleteProduct: getIt(),
    ),
  );
}
