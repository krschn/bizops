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
import '../../features/suppliers/data/datasources/supplier_local_data_source.dart';
import '../../features/suppliers/data/models/supplier_model.dart';
import '../../features/suppliers/data/repositories/supplier_repository_impl.dart';
import '../../features/suppliers/domain/repositories/supplier_repository.dart';
import '../../features/suppliers/domain/usecases/get_deleted_suppliers.dart';
import '../../features/suppliers/domain/usecases/get_suppliers.dart';
import '../../features/suppliers/domain/usecases/permanent_delete_supplier.dart';
import '../../features/suppliers/domain/usecases/restore_supplier.dart';
import '../../features/suppliers/domain/usecases/save_supplier.dart';
import '../../features/suppliers/domain/usecases/soft_delete_supplier.dart';
import '../../features/suppliers/presentation/bloc/supplier_bloc.dart';
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

  // Suppliers
  getIt.registerLazySingleton<Box<SupplierModel>>(
    () => Hive.box<SupplierModel>(HiveBoxNames.suppliers),
  );
  getIt.registerLazySingleton<SupplierLocalDataSource>(
    () => SupplierLocalDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<SupplierRepository>(
    () => SupplierRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => GetSuppliers(getIt()));
  getIt.registerFactory(() => GetDeletedSuppliers(getIt()));
  getIt.registerFactory(() => SaveSupplier(getIt()));
  getIt.registerFactory(() => SoftDeleteSupplier(getIt()));
  getIt.registerFactory(() => RestoreSupplier(getIt()));
  getIt.registerFactory(() => PermanentDeleteSupplier(getIt()));
  getIt.registerFactory(
    () => SupplierBloc(
      getSuppliers: getIt(),
      getDeletedSuppliers: getIt(),
      saveSupplier: getIt(),
      softDeleteSupplier: getIt(),
      restoreSupplier: getIt(),
      permanentDeleteSupplier: getIt(),
    ),
  );
}
